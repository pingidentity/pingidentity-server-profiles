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
    CONFIG_QUERY_LISTENER_KEYPAIR_ID=$( jq -n "$OUT" | jq '.items[] | select(.name=="CONFIG QUERY") | .keyPairId' )
    echo "CONFIG_QUERY_LISTENER_KEYPAIR_ID:${CONFIG_QUERY_LISTENER_KEYPAIR_ID}"

    echo "Retrieving the Key Pair alias..."
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/keyPairs  )
    KEYPAIR_ALIAS_NAME=$( jq -n "$OUT" | jq -r '.items[] | select(.id=='${CONFIG_QUERY_LISTENER_KEYPAIR_ID}') | .alias' )
    echo "KEYPAIR_ALIAS_NAME:"${KEYPAIR_ALIAS_NAME}

    # Retrieve Engine Cert ID
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/engines/certificates )
    ENGINE_CERT_ID=$( jq -n "$OUT" | \
                      jq --arg KEYPAIR_ALIAS_NAME "${KEYPAIR_ALIAS_NAME}" \
                      '.items[] | select(.alias==$KEYPAIR_ALIAS_NAME and .keyPair==true) | .id' )
    echo "ENGINE_CERT_ID:${ENGINE_CERT_ID}"

    # Retrieve Engine ID
    SHORT_HOST_NAME=$(hostname)
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/engines )
    ENGINE_ID=$( jq -n "$OUT" | \
                 jq --arg SHORT_HOST_NAME "${SHORT_HOST_NAME}" \
                 '.items[] | select(.name==$SHORT_HOST_NAME) | .id' )

    # If engine doesnt exist, then create new engine
    if test -z "${ENGINE_ID}" || test "${ENGINE_ID}" = null ; then
        OUT=$( make_api_request -X POST -d "{
            \"name\":\"${SHORT_HOST_NAME}\",
            \"selectedCertificateId\": ${ENGINE_CERT_ID},
            \"configReplicationEnabled\": true
        }" https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/engines )
        ENGINE_ID=$( jq -n "$OUT" | jq '.id' )
    fi

    # Download Engine Configuration
    echo "ENGINE_ID:"${ENGINE_ID}
    echo "Retrieving the engine config"
    make_api_request -X POST https://${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9000/pa-admin-api/v3/engines/${ENGINE_ID}/config \
    -o engine-config.zip

    echo "Extracting config files to conf folder..."
    unzip -o engine-config.zip -d ${OUT_DIR}/instance
    chmod 400 ${OUT_DIR}/instance/conf/pa.jwk

    echo "Cleanup zip.."
    rm engine-config.zip
fi