#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- This script is started in the background immediately before 
#- the server within the container is started
#-
#- This is useful to implement any logic that needs to occur after the
#- server is up and running
#-
#- For example, enabling replication in PingDirectory, initializing Sync 
#- Pipes in PingDataSync or issuing admin API calls to PingFederate or PingAccess

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

pahost=${PA_CONSOLE_HOST}
INITIAL_ADMIN_PASSWORD=${INITIAL_ADMIN_PASSWORD:=2FederateM0re}
if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_ENGINE" ]]; then
    echo "This node is an engine..."
    while true; do
    curl -ss --silent -o /dev/null -k https://${pahost}:9000/pa/heartbeat.ping 
    if ! test $? -eq 0 ; then
        echo "Adding Engine: Server not started, waiting.."
        sleep 3
    else
        echo "PA started, begin adding engine"
        break
    fi
    done

    # Get Engine Certificate ID
    echo "Retrieving Key Pair ID from administration API..."
    keypairid=$( curl -v -k -u Administrator:"${INITIAL_ADMIN_PASSWORD}" -H "X-Xsrf-Header: PingAccess" https://${pahost}:9000/pa-admin-api/v3/httpsListeners | jq '.items[] | select(.name=="CONFIG QUERY") | .keyPairId' )
    echo "KeyPairId:"${keypairid}

    echo "Retrieving the Key Pair alias..."
    kpalias=$( curl -v -k -u Administrator:"${INITIAL_ADMIN_PASSWORD}" -H "X-Xsrf-Header: PingAccess" https://${pahost}:9000/pa-admin-api/v3/keyPairs | jq '.items[] | select(.id=='${keypairid}') | .alias' )
    echo "Key Pair Alias:"${kpalias}

    echo "Retrieving Engine Certificate ID..."
    certid=$( curl -v -k -u Administrator:"${INITIAL_ADMIN_PASSWORD}" -H "X-Xsrf-Header: PingAccess" https://${pahost}:9000/pa-admin-api/v3/engines/certificates| jq '.items[] | select(.alias=='${kpalias}' and .keyPair==true) | .id' )
    echo "Engine Cert ID:"${certid}

    echo "Adding new engine"
    host=`hostname`
    engineid=$( curl -v -k -X POST -u Administrator:"${INITIAL_ADMIN_PASSWORD}" -H "X-Xsrf-Header: PingAccess" -d "{
            \"name\":\"${host}\",
            \"selectedCertificateId\": ${certid}
        }" https://${pahost}:9000/pa-admin-api/v3/engines | jq '.id' )

    echo "EngineId:"${engineid}
    set PA_ENGINE_ID=${engineid}
    echo "Retrieving the engine config..."
    curl -v -k -X POST -u Administrator:"${INITIAL_ADMIN_PASSWORD}" -H "X-Xsrf-Header: PingAccess" https://${pahost}:9000/pa-admin-api/v3/engines/${engineid}/config -o engine-config.zip

    echo "Extracting config files to conf folder..."
    unzip -o engine-config.zip -d ${OUT_DIR}/instance
    ls -la ${OUT_DIR}instance/conf
    cat ${OUT_DIR}/instance/conf/bootstrap.properties
    chmod 400 ${OUT_DIR}/instance/conf/pa.jwk

    echo "Cleanup zip.."
    rm engine-config.zip
fi




