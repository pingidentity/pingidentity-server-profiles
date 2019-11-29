#!/usr/bin/env sh

${VERBOSE} && set -x

# Set PATH - since this is executed from within the server process, it may not have all we need on the path
export PATH="${PATH}:${SERVER_ROOT_DIR}/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"

# Since the server invokes this, send the output to a log file so it's captured on Kibana
LOG_FILE="${SERVER_ROOT_DIR}/logs/tools/upload.log"

# Allow overriding the log archive URL with an arg
test ! -z "${1}" && LOG_ARCHIVE_URL="${1}"
echo "Uploading to location ${LOG_ARCHIVE_URL}" > "${LOG_FILE}"

# Install AWS CLI if the upload location is S3
if test "${LOG_ARCHIVE_URL#s3}" == "${LOG_ARCHIVE_URL}"; then
  echo "Upload location is not S3" >> "${LOG_FILE}"
  exit 0
elif ! which aws > /dev/null; then
  echo "Installing AWS CLI" >> "${LOG_FILE}"
  apk --update add python3
  pip3 install --no-cache-dir --upgrade pip
  pip3 install --no-cache-dir --upgrade awscli
fi

FORMAT="+%d/%b/%Y:%H:%M:%S %z"
NOW=$(date "${FORMAT}")
AN_HOUR_AGO=$(date --date="@$(($(date +%s) - 3600))" "${FORMAT}")

cd "${OUT_DIR}"
collect-support-data --timeRange "\"[${AN_HOUR_AGO}],[${NOW}]\""
CSD_OUT=$(find . -name support\*zip -type f | sort | tail -1)

echo "Uploading "${CSD_OUT}" to ${LOG_ARCHIVE_URL} at ${NOW}" >> "${LOG_FILE}"
DST_FILE=$(basename "${CSD_OUT}")
aws s3 cp "${CSD_OUT}" "${LOG_ARCHIVE_URL}/${DST_FILE}"

echo "Upload return code: ${?}" >> "${LOG_FILE}"

rm -f "${CSD_OUT}"