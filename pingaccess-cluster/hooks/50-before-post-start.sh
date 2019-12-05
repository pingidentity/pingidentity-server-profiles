#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- This is called after the start or restart sequence has finished and before 
#- the server within the container starts
#

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

echo `set`

echo_green 'Checking if OPERATIONAL_MODE is set...'
echo "OPERATIONAL_MODE:"${OPERATIONAL_MODE}
INITIAL_ADMIN_PASSWORD=${INITIAL_ADMIN_PASSWORD:=2FederateM0re}
if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" ]]; then
  echo "Shutting down the eth01 interface..."
  ip link set eth0 down
fi

if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_ENGINE" ]]; then
  echo "Adding engine..."
  run_hook "51-add-engine.sh"
fi