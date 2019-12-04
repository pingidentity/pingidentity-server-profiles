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
. "${HOOKS_DIR}/utils.lib.sh"

host=`hostname`
if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_ENGINE" ]]; then
    echo "This node is an engine..."
    while true; do
    curl -ss --silent -o /dev/null -k https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9090/pa/heartbeat.ping
    if ! test $? -eq 0 ; then
        echo "Adding Engine: Server not started, waiting.."
        sleep 3
    else
        echo "PA started, begin adding engine"
        break
    fi
    done

    # Retrieving CONFIG QUERY id
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/httpsListeners )
    configQueryListenerKeyPairId=$( jq -n "$OUT" | jq '.items[] | select(.name=="CONFIG QUERY") | .keyPairId' )
    echo "ConfigQueryListenerKeyPairId:${configQueryListenerKeyPairId}"

    echo "Retrieving the Key Pair alias..."
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/keyPairs  )
    kpalias=$( jq -n "$OUT" | jq -r '.items[] | select(.id=='${configQueryListenerKeyPairId}') | .alias' )
    echo "Key Pair Alias:"${kpalias}

    # Retrieve Engine Cert ID
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/engines/certificates )
    paEngineCertId=$( jq -n "$OUT" | jq --arg kpalias "${kpalias}" '.items[] | select(.alias==$kpalias and .keyPair==true) | .id' )
    echo "Engine Cert ID:${paEngineCertId}"

    # Retrieve Engine ID
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/engines )
    engineId=$( jq -n "$OUT" | jq --arg host "${host}" '.items[] | select(.name==$host) | .id' )

    # If engine doesnt exist, then create new engine
    if test -z "${engineId}" || test "${engineId}" = null ; then
        OUT=$( make_api_request -X POST -d "{
            \"name\":\"${host}\",
            \"selectedCertificateId\": ${paEngineCertId},
            \"configReplicationEnabled\": true
        }" https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/engines )
        engineId=$( jq -n "$OUT" | jq '.id' )
    fi

    # Download Engine Configuration
    echo "EngineId:"${engineId}
    echo "Retrieving the engine config"
    make_api_request -X POST https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/engines/${engineId}/config -o engine-config.zip

    echo "Extracting config files to conf folder..."
    unzip -o engine-config.zip -d ${OUT_DIR}/instance
    ls -la ${OUT_DIR}/instance/conf
    cat ${OUT_DIR}/instance/conf/bootstrap.properties
    chmod 400 ${OUT_DIR}/instance/conf/pa.jwk

    echo "Cleanup zip.."
    rm engine-config.zip
fi