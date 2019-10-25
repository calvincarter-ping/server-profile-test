#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"

#APIATTEMPTS=10
# --max-time 10     (how long each retry will wait)
# --retry 5         (it will retry 5 times)
# --retry-delay 0   (an exponential backoff algorithm)
# --retry-max-time  (total time before it's considered failed)

#function make_api_request
#{
#    local retryAttempts=10
#    while true; do
        curl -k --max-time 3 --retry 10 -u Administrator:2FederateM0re -H "X-Xsrf-Header: PingAccess " "$@"
#        if [[ ! $? -eq 0 && $retryAttempts -gt 0 ]]; then
#            retryAttempts=$((retryAttempts-1))
#            sleep 3
#        elif [ $retryAttempts -eq 0 ]; then
#            return 1
#        else
#            break
#        fi
#    done
#}