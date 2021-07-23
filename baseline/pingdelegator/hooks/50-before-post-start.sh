#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"

if test "${PF_ENGINE_PUBLIC_PORT}" = "443" ; then
  sed -i "s#^window.PF_PORT#//window.PF_PORT#" /opt/out/instance/html/delegator/config.js
fi