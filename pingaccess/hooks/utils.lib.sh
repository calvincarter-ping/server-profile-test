#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"

APIATTEMPTS=10

function make_api_request
{
    echo password ${INITIAL_ADMIN_PASSWORD}

    local retryAttempts=${APIATTEMPTS}
    while true; do
    curl -k -u Administrator:2FederateM0re -H "X-Xsrf-Header: PingAccess " "$@"
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