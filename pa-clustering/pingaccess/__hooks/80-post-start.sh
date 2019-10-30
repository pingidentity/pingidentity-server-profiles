#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- This script is used to import any configurations that are
#- needed after PingAccess starts

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"
INITIAL_ADMIN_PASSWORD=${INITIAL_ADMIN_PASSWORD:=2FederateM0re}
if test ${RUN_PLAN} = "START" ; then
  echo "Check for configuration to import.."
  if ! test -f ${STAGING_DIR}/instance/conf/pa.jwk ; then
    echo "INFO: No 'pa.jwk' found in /instance/conf"
    if ! test -f ${STAGING_DIR}/instance/data/data.json ; then
      echo "INFO: No file named 'data.json' found in /instance/data"
      echo "INFO: skipping config import"
    fi
  else 
    if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" ]]; then
      run_hook "81-import-initial-configuration.sh"
    fi   
  fi
fi

if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" ]]; then
  echo "Bringing eth0 back up..."
  ip link set eth0 up
fi 