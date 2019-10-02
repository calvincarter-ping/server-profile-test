#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- This script is started in the background immediately before 
#- the server within the container is started
#-
#- This is useful to implement any logic that needs to occur after the
#- server is up and running
#-
#- For example, enabling replication in PingDirectory, initializing Sync 
#- Pipes in PingDataSync or issuing admin API calls to PingFederate or PingAccess

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

host=`hostname`

if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_ENGINE" ]]; then
    echo "This node is an engine..."
    while true; do
        curl -s -o /dev/null -k https://${PA_CONSOLE_HOST}:9000/pa/heartbeat.ping 
        if ! test $? -eq 0 ; then
            echo "Adding Engine: Server not started, waiting.."
            sleep 3
        else
            echo "PA started, begin adding engine"
            break
        fi
    done

    # Download Engine Configuration
    #echo "EngineId:"${engineId}
    echo "Retrieving the engine config"
    make_api_request -X POST https://${PA_CONSOLE_HOST}:9000/pa-admin-api/v3/engines/1/config -o engine-config.zip

    echo "Extracting config files to conf folder..."
    unzip -o engine-config.zip -d ${OUT_DIR}/instance

    chmod 400 ${OUT_DIR}/instance/conf/pa.jwk
    cat ${OUT_DIR}/instance/conf/bootstrap.properties
    ls -la ${OUT_DIR}/instance/conf

    echo "Cleanup zip.."
    rm engine-config.zip
fi


