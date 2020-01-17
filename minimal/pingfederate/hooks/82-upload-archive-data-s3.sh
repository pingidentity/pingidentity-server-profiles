#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

${VERBOSE} && set -x

# Allow overriding the backup URL with an arg
test ! -z "${1}" && BACKUP_URL="${1}"
echo "Uploading to location ${BACKUP_URL}"

# Install AWS CLI if the upload location is S3
if test "${BACKUP_URL#s3}" == "${BACKUP_URL}"; then
   echo_red "Upload location is not S3"
   exit 1
else
   installTools
fi

# Create and export archive data into file data.mm-dd-YYYY.HH.MM.SS.zip
DST_FILE="data-`date +%m-%d-%Y.%H.%M.%S`.zip"
DST_DIRECTORY="/tmp/k8s-s3-upload-archive"
mkdir -p ${DST_DIRECTORY}

# Make request to admin API and export latest data
make_api_request -X GET https://localhost:9999/pf-admin-api/v1/configArchive/export \
    -o ${DST_DIRECTORY}/${DST_FILE}

# Validate admin API call was successful and that zip isn't corrupted
if test ! $? -eq 0 || test "$( unzip -t ${DST_DIRECTORY}/${DST_FILE} > /dev/null 2>&1;echo $?)" != "0" ; then
  echo "Failed to export archive"
  # Cleanup k8s-s3-upload-archive temp directory
  rm -rf ${DST_DIRECTORY}
  exit 0
fi

BUCKET_URL_NO_PROTOCOL=${BACKUP_URL#s3://}
BUCKET_NAME=$(echo ${BUCKET_URL_NO_PROTOCOL} | cut -d/ -f1)
DIRECTORY_NAME=$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')

echo "Creating directory ${DIRECTORY_NAME} under bucket ${BUCKET_NAME}"
aws s3api put-object --bucket "${BUCKET_NAME}" --key "${DIRECTORY_NAME}"/

if test "${BACKUP_URL}" == */pingfederate; then
  TARGET_URL="${BACKUP_URL}"
else
  TARGET_URL="${BACKUP_URL}/${DIRECTORY_NAME}"
fi

aws s3 cp "${DST_DIRECTORY}/${DST_FILE}" "${TARGET_URL}/"
AWS_API_RESULT="${?}"

echo "Upload return code: ${AWS_API_RESULT}"

if [ "${AWS_API_RESULT}" != "0" ]; then
  echo_red "Upload was unsuccessful - crash the container"
  exit 1
fi

# Print the filename of the uploaded file to s3
echo "Uploaded file name: ${DST_FILE}"

# Print listed files from k8s-s3-upload-archive
DST_DIR_CONTENTS=$(mktemp)
ls ${DST_DIRECTORY} > ${DST_DIR_CONTENTS}
cat ${DST_DIR_CONTENTS}

# Cleanup k8s-s3-upload-archive temp directory
rm -rf ${DST_DIRECTORY}