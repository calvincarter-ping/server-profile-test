#!/usr/bin/env sh

########################################################################################################################
# Makes curl request to PingFederate Admin cluster heartbeat page.
# If request fails, wait for 3 seconds and try again.
#
# Arguments
#   N/A
########################################################################################################################
function pingfederate_external_engine_wait
{
    while true; do
        curl -ss --silent -o /dev/null -k https://${K8S_STATEFUL_SET_SERVICE_NAME_PINGFEDERATE_ADMIN}:9999/pf/heartbeat.ping
        if ! test $? -eq 0 ; then
            echo "Adding Engine: Server not started, waiting.."
            sleep 3
        else
            echo "PA started, begin adding engine"
            break
        fi
    done
}