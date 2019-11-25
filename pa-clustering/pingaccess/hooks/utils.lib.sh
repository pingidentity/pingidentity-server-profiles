#!/usr/bin/env sh

########################################################################################################################
# Makes curl request to PingAccess API to configure.
#
# Arguments
#   $@ -> The URL and additional needed data to make request
########################################################################################################################
function make_api_request
{
    local retryAttempts=10
    while true; do
        curl -k -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess " "$@"
        if [[ ! $? -eq 0 && $retryAttempts -gt 0 ]]; then
            retryAttempts=$((retryAttempts-1))
            sleep 3
        elif [ $retryAttempts -eq 0 ]; then
            return 1
        else
            break
        fi
    done
}