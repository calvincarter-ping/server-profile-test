#!/usr/bin/env sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

host=`hostname`

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


# Update admin config host
make_api_request -X PUT -d "{
    \"hostPort\": \"${PA_CONSOLE_HOST}:9090\"
}" https://localhost:9000/pa-admin-api/v3/adminConfig > /dev/null

# {\"name\":\"iPAddress\",\"value\":\"182.50.30.59\"},{\"name\":\"dNSName\",\"value\":\"${host}\"},{\"name\":\"dNSName\",\"value\":\"${PA_CONSOLE_HOST}\"},{\"name\":\"dNSName\",\"value\":\"ping-cloud-calvincarter\"}
# Generate New Key Pair Id for PingAccess Engine: ${host}"
OUT=$( make_api_request -X POST -d "{
    \"keySize\": 2048,
    \"subjectAlternativeNames\":[{\"name\":\"dNSName\",\"value\":\"pingaccess\"}],
    \"keyAlgorithm\":\"RSA\",
    \"alias\":\"${host}\",
    \"organization\":\"Ping Identity\",
    \"validDays\":1000,
    \"commonName\":\"${host}\",
    \"country\":\"US\",
    \"signatureAlgorithm\":\"SHA256withRSA\"
}" https://localhost:9000/pa-admin-api/v3/keyPairs/generate )
paEngineKeyPairId=$( jq -n "$OUT" | jq '.id' )
echo "EngineKeyPairId:"${paEngineKeyPairId}
paEngineKeyPairAlias=$( jq -n "$OUT" | jq -r '.alias' )
echo "EngineKeyPairAlias:"${paEngineKeyPairAlias}