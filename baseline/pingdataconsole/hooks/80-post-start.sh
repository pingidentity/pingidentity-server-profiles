#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- This hook runs through the followig phases:
#-
${VERBOSE} && set -x

# shellcheck source=../../pingcommon/hooks/pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"
_pinFile="${SECRETS_DIR}/.autogen-truststore.pin"
# _storeFile="${STAGING_DIR}/autogen-truststore"
_storeFile="${AUTOGEN_TRUSTSTORE_FILE}"

ensure_trust_store_present ()
{
    test -f "${_pinFile}" || head -c 1024 /dev/urandom | tr -dc 'a-zA-Z0-9-' | cut -c 1-64 > "${_pinFile}"
    _storePass="$( cat "${_pinFile}" )"
    if ! test -f "${_storeFile}" ;
    then
        keytool \
            -genkey\
            -keyalg RSA \
            -alias stub \
            -keystore "${_storeFile}" \
            -storepass "${_storePass}" \
            -validity 30 \
            -keysize 2048 \
            -noprompt \
            -dname "CN=ephemeral, OU=Docker, O=PingIdentity Corp., L=Denver, ST=CO, C=US"
        keytool \
            -delete \
            -alias stub \
            -keystore "${_storeFile}" \
            -storepass "${_storePass}"
    fi
}

# this function conveniently allows to trust a remote server
trust_server () 
{    
    _server="${1}"
    
    # shellcheck disable=SC2039
    _alias="$( echo -n ${_server} | tr : _ )_$(date '+%s')"
    _certFile="/tmp/${_alias}.cert"
    keytool -printcert -sslserver ${_server} -rfc > "${_certFile}"
    
    _certFingerPrint=$( keytool -printcert -file "${_certFile}" | awk '/SHA256:/{print $2}' )

    if test -f "${_storeFile}" ;
    then
        _certificateFound="false"
        if keytool -list -keystore "${_storeFile}" -storepass ${_storePass} | awk 'BEGIN{x=1}/SHA-256/ && $4~/'${_certFingerPrint}'/{x=0}END{exit x}' ;
        then
            _certificateFound="true"
        fi
    fi

    if test "${_certificateFound}" != "true" ;
    then
        echo "Processinng ${_server} certificate"
        _storePass="$( cat "${_pinFile}" )"
        keytool -import -file "${_certFile}" -noprompt -alias "${_alias}" -keystore "${_storeFile}" -storepass "${_storePass}"
    else
        echo "${_server} certificate was NOT added to keystore" >/dev/null
    fi
    rm "${_certFile}"
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

if test -n "${AUTOGEN_TRUSTSTORE_ENABLED}" ; 
then
    ensure_trust_store_present
    for server in "pingdirectory:${LDAPS_PORT}" "pingdirectoryproxy:${LDAPS_PORT}" "pingdatasync:${LDAPS_PORT}" "pingdatagovernance:${LDAPS_PORT}" ;
    do
        sleep 3
        watch_server "${server}" &
    done
fi