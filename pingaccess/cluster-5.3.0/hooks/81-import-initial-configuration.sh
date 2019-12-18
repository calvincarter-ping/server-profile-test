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

# Wait until pingaccess admin localhost is available
pingaccess_admin_localhost_wait

set -x

# Accept EULA
make_initial_api_request -X PUT -d '{ "email": null,
    "slaAccepted": true,
    "firstLogin": false,
    "showTutorial": false,
    "username": "Administrator"
}' https://localhost:9000/pa-admin-api/v3/users/1 > /dev/null

# Change default password
make_initial_api_request -X PUT -d '{
  "currentPassword": "2Access",
  "newPassword": "'"${INITIAL_ADMIN_PASSWORD}"'"
}' https://localhost:9000/pa-admin-api/v3/users/1/password > /dev/null

# Generate new KeyPair for cluster
OUT=$( make_api_request -X POST -d "{
          \"keySize\": 2048,
          \"subjectAlternativeNames\":[],
          \"keyAlgorithm\":\"RSA\",
          \"alias\":\"pingaccess-console\",
          \"organization\":\"Ping Identity\",
          \"validDays\":${PING_ACCESS_CERT_VALID_DAYS},
          \"commonName\":\"${K8S_STATEFUL_SET_SERVICE_NAME_PA}\",
          \"country\":\"US\",
          \"signatureAlgorithm\":\"SHA256withRSA\"
        }" https://localhost:9000/pa-admin-api/v3/keyPairs/generate )

PINGACESS_KEY_PAIR_ID=$( jq -n "$OUT" | jq '.id' )

# Retrieving CONFIG QUERY id
OUT=$( make_api_request https://localhost:9000/pa-admin-api/v3/httpsListeners )
CONFIG_QUERY_LISTENER_KEYPAIR_ID=$( jq -n "$OUT" | jq '.items[] | select(.name=="CONFIG QUERY") | .keyPairId' )
echo "CONFIG_QUERY_LISTENER_KEYPAIR_ID:${CONFIG_QUERY_LISTENER_KEYPAIR_ID}"

# Update CONFIG QUERY with cluster KeyPair
make_api_request -X PUT -d "{
    \"name\": \"CONFIG QUERY\",
    \"useServerCipherSuiteOrder\": false,
    \"keyPairId\": ${PINGACESS_KEY_PAIR_ID}
}" https://localhost:9000/pa-admin-api/v3/httpsListeners/${CONFIG_QUERY_LISTENER_KEYPAIR_ID}

# Update admin config host
make_api_request -X PUT -d "{
                            \"hostPort\":\"${K8S_STATEFUL_SET_SERVICE_NAME_PA}:9090\",
                            \"httpProxyId\": 0,
                            \"httpsProxyId\": 0
                        }" https://localhost:9000/pa-admin-api/v3/adminConfig

# Mark file to indicate that pingaccess cluster certificate is complete
touch ${OUT_DIR}/instance/pingaccess_cert_complete

# Terminate admin to signal a k8s restart
kill $(ps | grep "${OUT_DIR}/instance/bin/run.sh" | awk '{print $1}')