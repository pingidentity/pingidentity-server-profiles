#!/usr/bin/env sh

########################################################################################################################
# Makes curl request to PingFederate Admin API to configure.
#
# Arguments
#   $@ -> The URL and additional needed data to make request
########################################################################################################################
function make_api_request()
{
    curl -k --retry ${API_RETRY_LIMIT} --max-time ${API_TIMEOUT_WAIT} --retry-delay 1 --retry-connrefuse \
        -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingFederate " "$@"
    if test ! $? -eq 0; then
        echo "Admin API connection refused"
        exit 1
    fi
}

########################################################################################################################
# Function to install AWS command line tools
#
# Arguments
#   N/A
########################################################################################################################
function installTools()
{
   if [ -z "$(which aws)" ]; then
      #   
      #  Install AWS platform specific tools
      #
      echo "Installing AWS CLI tools for S3 support"
      #
      # TODO: apk needs to move to the Docker file as the package manager is plaform specific
      #
      apk --update add python3
      pip3 install --no-cache-dir --upgrade pip
      pip3 install --no-cache-dir --upgrade awscli
   fi
}