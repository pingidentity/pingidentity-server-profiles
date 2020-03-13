#!/usr/bin/env sh

#TODO: REVERTME - this shouldn't be necessary
        echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
            echo "this is password $PA_ADMIN_PASSWORD"
        if test "$PA_ADMIN_PASSWORD" = "2Access" -a "${INITIAL_ADMIN_PASSWORD}" = "2FederateM0re" -a -z "${SET_ADMIN_PASSWORD}" ; then
            PA_ADMIN_PASSWORD="${INITIAL_ADMIN_PASSWORD}"
        elif test -n "$SET_ADMIN_PASSWORD" ; then
            PA_ADMIN_PASSWORD="${SET_ADMIN_PASSWORD}"
        fi
        echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
            echo "REVERTME REVERTME REVERTME"
        echo "this is NEW password $PA_ADMIN_PASSWORD"

echo "THIS IS LIVENESS@!!"
wait-for "${PA_ENGINE_PUBLIC_HOSTNAME}:3000" -t 200 || exit 1
sleep 5
curl -kv -u "Administrator:${PA_ADMIN_PASSWORD}" -H "Content-Type: application/json" -H "X-Xsrf-Header: PingAccess" https://localhost:9000/pa-admin-api/v3/engines | jq '.items[0].configReplicationEnabled' | grep true
exit $?