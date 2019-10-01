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

pahost=${PA_CONSOLE_HOST}
host=`hostname`

function make_api_request
{
    local retryAttempts=10
    while true; do
    curl -s -k -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess " "$@"
    if [[ ! $? -eq 0 && $retryAttempts -gt 0 ]]; then
        retryAttempts=$((retryAttempts-1))
        #echo "Timeout occured retry "
        sleep 3
    elif [ $retryAttempts -eq 0 ]; then
        #echo "API Attempts failed"
        exit 1
    else
        break
    fi
    done
}

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

    # Generate Cert for PingAccess Host
    make_api_request -X POST -d "{
        \"keySize\": 2048,
        \"subjectAlternativeNames\":[],
        \"keyAlgorithm\":\"RSA\",
        \"alias\":\"PingAccess: CONFIG QUERY\",
        \"organization\":\"Ping Identity\",
        \"validDays\":365,
        \"commonName\":\"${PINGACCESS_PORT_9000_TCP_ADDR}\",
        \"country\":\"US\",
        \"signatureAlgorithm\":\"SHA256withRSA\"
        }" https://${pahost}:9000/pa-admin-api/v3/keyPairs/generate

    make_api_request -X PUT -d "{
        \"name\": \"CONFIG QUERY\",
        \"useServerCipherSuiteOrder\": false,
        \"keyPairId\": 5
    }" https://${pahost}:9000/pa-admin-api/v3/httpsListeners/2

    # Get Engine Certificate ID
    echo "Retrieving Key Pair ID from administration API..."
    OUT=$( make_api_request https://${pahost}:9000/pa-admin-api/v3/httpsListeners )
    echo ${OUT}
    keypairid=$( jq -n "$OUT" | jq '.items[] | select(.name=="CONFIG QUERY") | .keyPairId' )
    echo "KeyPairId:"${keypairid}

    # Get Key Pair Alias
    echo "Retrieving the Key Pair alias..."
    OUT=$( make_api_request https://${pahost}:9000/pa-admin-api/v3/keyPairs )
    echo ${OUT}
    kpalias=$( jq -n "$OUT" | jq -r '.items[] | select(.id=='${keypairid}') | .alias' )
    echo "Key Pair Alias:"${kpalias}

    # Retrieve Engine Cert ID
    echo "Retrieving Engine Certificate ID..."
    OUT=$( make_api_request https://${pahost}:9000/pa-admin-api/v3/engines/certificates )
    echo ${OUT}
    certid=$( echo ${OUT} | jq --arg kpalias "${kpalias}" '.items[] | select(.alias==$kpalias and .keyPair==true) | .id' )
    echo "Engine Cert ID:"${certid}

    echo "Adding new engine"
    # Retrieve Engine ID
    OUT=$( make_api_request -X POST -d "{
            \"name\":\"${host}\",
            \"selectedCertificateId\": ${certid}
        }" https://${pahost}:9000/pa-admin-api/v3/engines )
    echo ${OUT}
    engineid=$( jq -n "$OUT" | jq '.id' )

    # Download Engine Configuration
    echo "EngineId:"${engineid}
    echo "Retrieving the engine config..."
    make_api_request -X POST https://${pahost}:9000/pa-admin-api/v3/engines/${engineid}/config -o engine-config.zip

    echo "Extracting config files to conf folder..."
    unzip -o engine-config.zip -d ${OUT_DIR}/instance

    cat ${OUT_DIR}/instance/conf/bootstrap.properties
    chmod 400 ${OUT_DIR}/instance/conf/pa.jwk

    ls -la ${OUT_DIR}/instance/conf

    echo "Cleanup zip.."
    rm engine-config.zip
fi

