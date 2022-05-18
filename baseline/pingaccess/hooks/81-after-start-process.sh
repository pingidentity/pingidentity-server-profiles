#!/usr/bin/env sh
# shellcheck source=../../../../pingcommon/opt/staging/hooks/pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

test -n "${INITIAL_ADMIN_PASSWORD}" && echo_yellow "WARNING: INITIAL_ADMIN_PASSWORD is deprecated, use PING_IDENTITY_PASSWORD"
test -n "${PA_ADMIN_PASSWORD}" && echo_yellow "WARNING: PA_ADMIN_PASSWORD is deprecated, use PING_IDENTITY_PASSWORD"

# Make an attempt to authenticate with the provided expected administrator password
_pwCheck=$(
    curl \
        --insecure \
        --silent \
        --write-out '%{http_code}' \
        --output /dev/null \
        --request GET \
        --user "${ROOT_USER}:${PING_IDENTITY_PASSWORD}" \
        -H "X-Xsrf-Header: PingAccess" \
        "https://localhost:${PA_ADMIN_PORT}/pa-admin-api/v3/users/1" \
        2> /dev/null
)

# if not successful, attempt to update the password using the default
if test "${_pwCheck}" -ne 200; then
    run_hook "83-change-password.sh"
fi

echo "Checking for data.json to import.."
if test -f "${STAGING_DIR}/instance/data/data.json"; then
  run_hook "85-import-configuration.sh"
else
    echo "INFO: No file named /instance/data/data.json found, skipping import."
fi