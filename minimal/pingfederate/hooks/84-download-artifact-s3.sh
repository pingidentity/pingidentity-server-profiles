#!/usr/bin/env sh

${VERBOSE} && set -x

# Set PATH - since this is executed from within the server process, it may not have all we need on the path
export PATH="${PATH}:${SERVER_ROOT_DIR}/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"

if test -f "${STAGING_DIR}/artifacts/artifact-list.json"; then

  # Check to see if the artifact file is empty
  ARTIFACT_LIST_JSON=$(cat "${STAGING_DIR}/artifacts/artifact-list.json")
  # Check to see if the source S3 bucket is specified
  if test ! -z "${ARTIFACT_LIST_JSON}"; then
    if test ! -z "${ARTIFACT_REPO_URL}"; then

      echo "Downloading from location ${ARTIFACT_REPO_URL}"

      if ! which jq > /dev/null; then
        echo "Installing jq"
        pip3 install --no-cache-dir --upgrade jq
      fi

      if ! which unzip > /dev/null; then
        echo "Installing unzip"
        pip3 install --no-cache-dir --upgrade unzip
      fi

      # Install AWS CLI if the upload location is S3
      if ! test "${ARTIFACT_REPO_URL#s3}" == "${ARTIFACT_REPO_URL}"; then
        echo "Installing AWS CLI"
        apk --update add python3
        pip3 install --no-cache-dir --upgrade pip
        pip3 install --no-cache-dir --upgrade awscli
      fi

      DIRECTORY_NAME=$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')

      if [ -z "${ARTIFACT_REPO_URL##*/pingfederate*}" ] ; then
        TARGET_BASE_URL="${ARTIFACT_REPO_URL}"
      else
        TARGET_BASE_URL="${ARTIFACT_REPO_URL}/${DIRECTORY_NAME}"
      fi

      for artifact in $(echo "${ARTIFACT_LIST_JSON}" | jq -c '.[]'); do
        _artifact() {
          echo ${artifact} | jq -r ${1}
        }

        ARTIFACT_NAME=$(_artifact '.name')
        ARTIFACT_VERSION=$(_artifact '.version')
        ARTIFACT_RUNTIME_ZIP=${ARTIFACT_NAME}-${ARTIFACT_VERSION}-runtime.zip

        #CURRENT_DIRECTORY=$(pwd)

        echo "${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION})/${ARTIFACT_RUNTIME_ZIP}" > ${OUT_DIR}/${ARTIFACT_VERSION}-url.txt

        # Use aws command if ARTIFACT_REPO_URL is in s3 format otherwise use curl
        if ! test "${ARTIFACT_REPO_URL#s3}" == "${ARTIFACT_REPO_URL}"; then
          aws s3 cp "${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/${ARTIFACT_RUNTIME_ZIP}" /tmp 2> ${OUT_DIR}/aws-error-${ARTIFACT_NAME}.txt
        else
          curl "${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/${ARTIFACT_RUNTIME_ZIP}" --output /tmp/${ARTIFACT_RUNTIME_ZIP} 2> ${OUT_DIR}/curl-error-${ARTIFACT_NAME}.txt
        fi

        if test $(echo $?) == "0"; then
          unzip -o /tmp/${ARTIFACT_RUNTIME_ZIP} -d ${OUT_DIR}/instance/server/default 2> ${OUT_DIR}/unzip-error-${ARTIFACT_NAME}.txt
        fi

        #Cleanup
        rm /tmp/${ARTIFACT_RUNTIME_ZIP}

        #if [ ! -z "$(aws s3 ls ${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION})" ]
        #then
        #  aws s3 cp "${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/" "${OUT_DIR}/instance/server/default" --recursive
        #fi

        # Download artifact zip
        #curl "${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION})/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.zip" --output /tmp/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.zip
        #cd /tmp
        #wget "${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION})/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.zip"

        #if test $(echo $?) == "0"; then
        #if [ -f "/tmp/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.zip" ]
        #then
          #if unzip -o /tmp/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.zip -d ${OUT_DIR}/instance/server/default 2> ${OUT_DIR}/${ARTIFACT_NAME}.txt
          #then
          #  rm /tmp/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.zip
          #fi
          #unzip -o /tmp/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.zip -d ${OUT_DIR}/instance/server/default 2> ${OUT_DIR}/${ARTIFACT_NAME}.txt
          #cd "${OUT_DIR}/instance/server/default"
          #unzip "/tmp/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.zip" 2> ${OUT_DIR}/error.txt
          #rm /tmp/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.zip
          #cd ${CURRENT_DIRECTORY}
        #fi

        #if [ ! -z "$(aws s3 ls ${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION})" ]
        #then
        #  aws s3 cp "${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/" "${OUT_DIR}/instance/server/default" --recursive
        #fi

      done

      # Print listed files from deploy
      ls ${OUT_DIR}/instance/server/default/deploy
      ls ${OUT_DIR}/instance/server/default/conf/template

    fi
  fi
fi
