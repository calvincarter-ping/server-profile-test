#!/usr/bin/env sh

########################################################################################################################
# Makes curl request to PingAccess API to configure.
#
# Arguments
#   $@ -> The URL and additional needed data to make request
########################################################################################################################
function make_api_request
{
    curl -k --retry 10  --retry-delay 1 --retry-connrefuse -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess " "$@"
    if [[ ! $? -eq 0 ]]; then
        exit 1
    fi
}