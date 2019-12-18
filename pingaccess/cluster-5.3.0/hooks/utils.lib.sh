#!/usr/bin/env sh

########################################################################################################################
# Makes curl request to PingAccess API to configure.
#
# Arguments
#   $@ -> The URL and additional needed data to make request
########################################################################################################################
function make_api_request
{
    curl -k --retry ${API_RETRY_LIMIT} --max-time ${API_TIMEOUT_WAIT} --retry-delay 1 --retry-connrefuse -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess " "$@"
    if [[ ! $? -eq 0 ]]; then
        echo "Admin API connection refused"
        exit 1
    fi
}

########################################################################################################################
# Makes curl request to PingAccess API to configure.
#
# Arguments
#   $@ -> The URL and additional needed data to make request
########################################################################################################################
function make_initial_api_request
{
    curl -k --retry ${API_RETRY_LIMIT} --max-time ${API_TIMEOUT_WAIT} --retry-delay 1 --retry-connrefuse -u Administrator:2Access -H "X-Xsrf-Header: PingAccess " "$@"
    if [[ ! $? -eq 0 ]]; then
        echo "Admin API connection refused"
        exit 1
    fi
}

########################################################################################################################
# Makes curl request to localhost PingAccess admin Console heartbeat page.
# If request fails, wait for 3 seconds and try again.
#
# Arguments
#   N/A
########################################################################################################################
function pingaccess_admin_localhost_wait
{
    while true; do
        curl -ss --silent -o /dev/null -k https://localhost:9000/pa/heartbeat.ping 
        if ! test $? -eq 0 ; then
            echo "Import Config: Server not started, waiting.."
            sleep 3
        else
            echo "PA started, begin import"
            break
        fi
    done
}

########################################################################################################################
# Makes curl request to PingAccess admin cluster heartbeat page.
# If request fails, wait for 3 seconds and try again.
#
# Arguments
#   N/A
########################################################################################################################
function pingaccess_external_engine_wait
{
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
}