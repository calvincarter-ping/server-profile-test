#!/usr/bin/env sh

########################################################################################################################
# Makes curl request to PingFederate Admin API to configure.
#
# Arguments
#   $@ -> The URL and additional needed data to make request
########################################################################################################################
function make_api_request
{
    curl -k --retry ${API_RETRY_LIMIT} --max-time ${API_TIMEOUT_WAIT} --retry-delay 1 --retry-connrefuse \
        -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingFederate " "$@"
    if test ! $? -eq 0; then
        echo "Admin API connection refused"
        exit 1
    fi
}

########################################################################################################################
# Makes curl request to localhost PingFederate admin Console heartbeat page.
#
# Arguments
#   N/A
########################################################################################################################
function pingfederate_admin_localhost_wait
{
    curl -k --retry ${API_RETRY_LIMIT} --max-time ${API_TIMEOUT_WAIT} --retry-delay 1 --retry-connrefuse \
        -o /dev/null -k https://localhost:9999/pf/heartbeat.ping
}