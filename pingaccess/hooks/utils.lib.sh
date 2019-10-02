#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"

function make_api_request
{
    local retryAttempts=${APIATTEMPTS}
    while true; do
    curl -s -k -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess " "$@"
    if [[ ! $? -eq 0 && $retryAttempts -gt 0 ]]; then
        retryAttempts=$((retryAttempts-1))
        sleep 3
    elif [ $retryAttempts -eq 0 ]; then
        exit 1
    else
        break
    fi
    done
}