#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_ENGINE" ]]; then

    echo "This node is an engine..."

    # Install AWS CLI if the upload location is S3
    if test "${BACKUP_URL#s3}" == "${BACKUP_URL}"; then
        echo_red "Upload location is not S3"
        exit 1
    else
        installTools
    fi

    BUCKET_URL_NO_PROTOCOL=${BACKUP_URL#s3://}
    DIRECTORY_NAME=$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')

    if test "${BACKUP_URL}" == */pingaccess; then
        TARGET_URL="${BACKUP_URL}"
    else
        TARGET_URL="${BACKUP_URL}/${DIRECTORY_NAME}"
    fi

    MASTER_KEY="${TARGET_URL}/pa.jwk"
    H2_DATABASE="${TARGET_URL}/PingAccess.mv.db"
    CERTFLAG="${TARGET_URL}/pingaccess_cert_complete_flag"

    RESULT_MASTER_KEY="$(aws s3 ls ${MASTER_KEY} > /dev/null 2>&1;echo $?)"
    RESULT_H2_DATABASE="$(aws s3 ls ${H2_DATABASE} > /dev/null 2>&1;echo $?)"
    RESULT_CERTFLAG="$(aws s3 ls ${CERTFLAG} > /dev/null 2>&1;echo $?)"

    while true; do
        if test "${RESULT_MASTER_KEY}" = "0" && test "${RESULT_H2_DATABASE}" = "0" && test "${RESULT_CERTFLAG}" = "0"; then
            echo "PingAccess admin configuration is complete, begin adding engine"
            break
        else
            echo "Adding Engine: Waiting for admin initial configuration"
            sleep 10
        fi
    done

    # Wait until pingaccess admin is available
    pingaccess_external_engine_wait

    # Retrieving CONFIG QUERY id
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PINGACCESS_ADMIN}:9000/pa-admin-api/v3/httpsListeners )
    CONFIG_QUERY_LISTENER_KEYPAIR_ID=$( jq -n "$OUT" | jq '.items[] | select(.name=="CONFIG QUERY") | .keyPairId' )
    echo "CONFIG_QUERY_LISTENER_KEYPAIR_ID:${CONFIG_QUERY_LISTENER_KEYPAIR_ID}"

    echo "Retrieving the Key Pair alias..."
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PINGACCESS_ADMIN}:9000/pa-admin-api/v3/keyPairs  )
    KEYPAIR_ALIAS_NAME=$( jq -n "$OUT" | jq -r '.items[] | select(.id=='${CONFIG_QUERY_LISTENER_KEYPAIR_ID}') | .alias' )
    echo "KEYPAIR_ALIAS_NAME:"${KEYPAIR_ALIAS_NAME}

    # Retrieve Engine Cert ID
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PINGACCESS_ADMIN}:9000/pa-admin-api/v3/engines/certificates )
    ENGINE_CERT_ID=$( jq -n "$OUT" | \
                      jq --arg KEYPAIR_ALIAS_NAME "${KEYPAIR_ALIAS_NAME}" \
                      '.items[] | select(.alias==$KEYPAIR_ALIAS_NAME and .keyPair==true) | .id' )
    echo "ENGINE_CERT_ID:${ENGINE_CERT_ID}"

    # Retrieve Engine ID
    SHORT_HOST_NAME=$(hostname)
    OUT=$( make_api_request https://${K8S_STATEFUL_SET_SERVICE_NAME_PINGACCESS_ADMIN}:9000/pa-admin-api/v3/engines )
    ENGINE_ID=$( jq -n "$OUT" | \
                 jq --arg SHORT_HOST_NAME "${SHORT_HOST_NAME}" \
                 '.items[] | select(.name==$SHORT_HOST_NAME) | .id' )

    # If engine doesnt exist, then create new engine
    if test -z "${ENGINE_ID}" || test "${ENGINE_ID}" = null ; then
        OUT=$( make_api_request -X POST -d "{
            \"name\":\"${SHORT_HOST_NAME}\",
            \"selectedCertificateId\": ${ENGINE_CERT_ID},
            \"configReplicationEnabled\": true
        }" https://${K8S_STATEFUL_SET_SERVICE_NAME_PINGACCESS_ADMIN}:9000/pa-admin-api/v3/engines )
        ENGINE_ID=$( jq -n "$OUT" | jq '.id' )
    fi

    # Download Engine Configuration
    echo "ENGINE_ID:"${ENGINE_ID}
    echo "Retrieving the engine config"
    make_api_request -X POST https://${K8S_STATEFUL_SET_SERVICE_NAME_PINGACCESS_ADMIN}:9000/pa-admin-api/v3/engines/${ENGINE_ID}/config \
    -o engine-config.zip

    echo "Extracting config files to conf folder..."
    unzip -o engine-config.zip -d ${OUT_DIR}/instance
    chmod 400 ${OUT_DIR}/instance/conf/pa.jwk

    echo "Cleanup zip.."
    rm engine-config.zip
fi