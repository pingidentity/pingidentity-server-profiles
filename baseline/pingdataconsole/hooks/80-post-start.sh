#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- This hook runs through the followig phases:
#-
${VERBOSE} && set -x

# shellcheck source=../../pingcommon/hooks/pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

# this function conveniently allows to trust a remote server
trust_server () 
{
    _pinFile="/opt/staging/autogen-truststore.pin"
    _storeFile="/opt/staging/autogen-truststore"
    
    test -f "${_pinFile}" || head -c 1024 /dev/urandom | tr -dc 'a-zA-Z0-9-' | cut -c 1-64 > "${_pinFile}"
    _storePass="$( cat "${_pinFile}" )"
    _server="${1}"
    
    # shellcheck disable=SC2039
    _alias="$( echo -n ${_server} | tr : _ )_$(date '+%s')"
    _certFile="/tmp/${_alias}.cert"
    keytool -printcert -sslserver ${_server} -rfc > "${_certFile}"
    
    _certFingerPrint=$( keytool -printcert -file "${_certFile}" | awk '/SHA256:/{print $2}' )


    if ! test -f "${_storeFile}" || keytool -list -keystore "${_storeFile}" -storepass ${_storePass} | awk 'BEGIN{x=0}/SHA-256/ && $4~/'${_certFingerPrint}'/{x=1}END{exit x}' ;
    then
        echo "Processinng ${_server} certificate"
        keytool -import -file "${_certFile}" -noprompt -alias "${_alias}" -keystore "${_storeFile}" -storepass ${_storePass}
    else
        echo "${_server} certificate was NOT added to keystore"
    fi
    rm ${_certFile}
}

is_reachable ()
{
    if test -n "${1}" ;
    then
        # shellcheck disable=SC2046
        nc -z $( echo "${1}" | tr : " " ) 2>/dev/null 1>/dev/null
        return ${?}
    else
        return 2
    fi 
}

watch_server ()
{
    if test -n "${1}" ;
    then
        while true ;
        do
            is_reachable "${1}" && trust_server "${1}"
            sleep 113
        done
    fi
}

for server in "pingdirectory:${LDAPS_PORT}" "pingdirectoryproxy:${LDAPS_PORT}" "pingdatasync:${LDAPS_PORT}" "pingdatagovernance:${LDAPS_PORT}" ;
do
    sleep 7
    watch_server "${server}" &
done