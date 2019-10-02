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
        curl -s -o /dev/null -k https://${pahost}:9000/pa/heartbeat.ping 
        if ! test $? -eq 0 ; then
            echo "Adding Engine: Server not started, waiting.."
            sleep 3
        else
            echo "PA started, begin adding engine"
            break
        fi
    done

    # Update admin config host
    make_api_request -X PUT -d "{
        \"hostPort\": \"${pahost}:9090\"
    }" https://localhost:9000/pa-admin-api/v3/adminConfig > /dev/null

    # {\"name\":\"iPAddress\",\"value\":\"182.50.30.59\"},{\"name\":\"dNSName\",\"value\":\"${host}\"},{\"name\":\"dNSName\",\"value\":\"${pahost}\"},{\"name\":\"dNSName\",\"value\":\"ping-cloud-calvincarter\"}
    # Generate New Key Pair Id for PingAccess Engine: ${host}"
    OUT=$( make_api_request -X POST -d "{
        \"keySize\": 2048,
        \"subjectAlternativeNames\":[{\"name\":\"dNSName\",\"value\":\"${host}\"}],
        \"keyAlgorithm\":\"RSA\",
        \"alias\":\"PingAccess\",
        \"organization\":\"Ping Identity\",
        \"validDays\":1000,
        \"commonName\":\"${pahost}\",
        \"country\":\"US\",
        \"signatureAlgorithm\":\"SHA256withRSA\"
    }" https://${pahost}:9000/pa-admin-api/v3/keyPairs/generate )
    paEngineKeyPairId=$( jq -n "$OUT" | jq '.id' )
    echo "EngineKeyPairId:"${paEngineKeyPairId}
    paEngineKeyPairAlias=$( jq -n "$OUT" | jq -r '.alias' )
    echo "EngineKeyPairAlias:"${paEngineKeyPairAlias}

    # Retrieving Config Query Key Pair ID
    OUT=$( make_api_request https://${pahost}:9000/pa-admin-api/v3/httpsListeners )
    configQueryListenerKeyPairId=$( jq -n "$OUT" | jq '.items[] | select(.name=="CONFIG QUERY") | .keyPairId' )
    echo "ConfigQueryListenerKeyPairId:"${configQueryListenerKeyPairId}

    # Update CONFIG QUERY to use PingAccess Engine Key Pair
    make_api_request -X PUT -d "{
        \"name\": \"CONFIG QUERY\",
        \"useServerCipherSuiteOrder\": true,
        \"keyPairId\": ${paEngineKeyPairId}
    }" https://${pahost}:9000/pa-admin-api/v3/httpsListeners/${configQueryListenerKeyPairId} > /dev/null

    # Get Key Pair Alias
    #echo "Retrieving the Key Pair alias..."
    #OUT=$( make_api_request https://${pahost}:9000/pa-admin-api/v3/keyPairs )
    #newKeyPairAlias=$( jq -n "$OUT" | jq -r '.items[] | select(.id=='${newKeyPairId}') | .alias' )
    #echo "Key Pair Alias:"${kpalias}

    # Retrieve Engine Cert ID
    OUT=$( make_api_request https://${pahost}:9000/pa-admin-api/v3/engines/certificates )
    paEngineCertId=$( echo ${OUT} | jq --arg paEngineKeyPairAlias "${paEngineKeyPairAlias}" '.items[] | select(.alias==$paEngineKeyPairAlias and .keyPair==true) | .id' )
    echo "Engine Cert ID:"${paEngineCertId}

    # Create Engine
    OUT=$( make_api_request -X POST -d "{
        \"name\":\"${host}\",
        \"selectedCertificateId\": ${paEngineCertId},
        \"configReplicationEnabled\": true
    }" https://${pahost}:9000/pa-admin-api/v3/engines )
    engineId=$( jq -n "$OUT" | jq '.id' )

    # Download Engine Configuration
    echo "EngineId:"${engineId}
    echo "Retrieving the engine config"
    make_api_request -X POST https://${pahost}:9000/pa-admin-api/v3/engines/${engineId}/config -o engine-config.zip

    echo "Extracting config files to conf folder..."
    unzip -o engine-config.zip -d ${OUT_DIR}/instance

    chmod 400 ${OUT_DIR}/instance/conf/pa.jwk
    cat ${OUT_DIR}/instance/conf/bootstrap.properties
    ls -la ${OUT_DIR}/instance/conf

    echo "Cleanup zip.."
    rm engine-config.zip
fi


