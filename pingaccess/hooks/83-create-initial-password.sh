#!/usr/bin/env sh
. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

curl -k -X PUT -u Administrator:2Access --silent -H "X-Xsrf-Header: PingAccess" -d '{ "email": null,
    "slaAccepted": true,
    "firstLogin": false,
    "showTutorial": false,
    "username": "Administrator"
}' https://localhost:9000/pa-admin-api/v3/users/1 > /dev/null

echo "INFO: changing initial password"
curl -k -X PUT -u Administrator:2Access --silent -H "X-Xsrf-Header: PingAccess" -d '{
  "currentPassword": "2Access",
  "newPassword": "'"${INITIAL_ADMIN_PASSWORD}"'"
}' https://localhost:9000/pa-admin-api/v3/users/1/password > /dev/null

# {\"name\":\"iPAddress\",\"value\":\"182.50.30.59\"},{\"name\":\"dNSName\",\"value\":\"${host}\"},{\"name\":\"dNSName\",\"value\":\"${PA_CONSOLE_HOST}\"},{\"name\":\"dNSName\",\"value\":\"ping-cloud-calvincarter\"}
# Generate New Key Pair Id for PingAccess Engine: ${host}"
host=`hostname`
OUT=$( make_api_request -X POST -d "{
    \"keySize\": 2048,
    \"subjectAlternativeNames\":[{\"name\":\"dNSName\",\"value\":\"${host}\"}],
    \"keyAlgorithm\":\"RSA\",
    \"alias\":\"${PA_CONSOLE_HOST}\",
    \"organization\":\"Ping Identity\",
    \"validDays\":1000,
    \"commonName\":\"${PA_CONSOLE_HOST}.*\",
    \"country\":\"US\",
    \"signatureAlgorithm\":\"SHA256withRSA\"
}" https://localhost:9000/pa-admin-api/v3/keyPairs/generate )
paEngineKeyPairId=$( jq -n "$OUT" | jq '.id' )
echo "EngineKeyPairId:"${paEngineKeyPairId}

# Retrieving Config Query Key Pair ID
OUT=$( make_api_request https://${PA_CONSOLE_HOST}:9000/pa-admin-api/v3/httpsListeners )
configQueryListenerKeyPairId=$( jq -n "$OUT" | jq '.items[] | select(.name=="CONFIG QUERY") | .keyPairId' )
echo "ConfigQueryListenerKeyPairId:"${configQueryListenerKeyPairId}

# Update CONFIG QUERY to use PingAccess Engine Key Pair
#make_api_request -X PUT -d "{
#    \"name\": \"CONFIG QUERY\",
#    \"useServerCipherSuiteOrder\": true,
#    \"keyPairId\": ${paEngineKeyPairId}
#}" https://${PA_CONSOLE_HOST}:9000/pa-admin-api/v3/httpsListeners/${configQueryListenerKeyPairId} > /dev/null

# Update admin config host
make_api_request -X PUT -d "{
    \"hostPort\": \"${PA_CONSOLE_HOST}:9090\"
}" https://localhost:9000/pa-admin-api/v3/adminConfig > /dev/null