#!/usr/bin/env sh
if test -z "${OPERATIONAL_MODE}" || test "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" || test "${OPERATIONAL_MODE}" = "STANDALONE" ; then
    if test -f ${STAGING_DIR}/instance/data/data.json -a -f ${STAGING_DIR}/instance/conf/pa.jwk ; then 
        while true ; do
        _import_status=$(curl -ks -u "Administrator:${PA_ADMIN_PASSWORD}" -H "Content-Type: application/json" -H "X-Xsrf-Header: PingAccess" https://localhost:9000/pa-admin-api/v3/config/import/workflows | jq '.items[-1].status')
        case "${_import_status}" in
            '' | '"In Progress"')
            echo "import in progress.."
            sleep 2 ;;
            '"Complete"')
            echo "Import status: ${_import_status}"
            exit 0 ;;
            *)
            echo "Import status: ${_import_status}"
            echo "ERROR: Unsuccessful Import"
            exit 85 ;;
        esac
        done
    fi
else    
    curl -ss -o /dev/null -k https://localhost:3000/pa/heartbeat.ping
    # ^ this will succeed if PA has not been configured to a port other than the default
    if test ${?} -ne 0 ; then
        # if the default failed, we try on the custom port
        curl -ss -o /dev/null -k https://localhost:${HTTPS_PORT}/pa/heartbeat.ping
        # ^ this will succeed if PA has been customized to listen to ${HTTPS_PORT}
        if test ${?} -ne 0 ; then
            # the health check must return 0 for healthy, 1 otherwise
            # but not any other code so we catch the curl return code and
            # change any non-zero code to 1
            # https://docs.docker.com/engine/reference/builder/#healthcheck
            exit 1
        fi
    fi
fi