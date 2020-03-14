#!/usr/bin/env sh

echo "THIS IS LIVENESS@!!"
wait-for "${PA_ENGINE_PUBLIC_HOSTNAME}:3000" -t 200 || exit 1
sleep 5
curl -kv -u "Administrator:${PA_ADMIN_PASSWORD}" -H "Content-Type: application/json" -H "X-Xsrf-Header: PingAccess" https://localhost:9000/pa-admin-api/v3/engines | jq '.items[0].configReplicationEnabled' | grep true
exit $?