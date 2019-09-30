#!/usr/bin/env sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

echo "password calvin " ${INITIAL_ADMIN_PASSWORD}

curl -k -X PUT -u Administrator:2Access --silent -H "X-Xsrf-Header: PingAccess" -d '{ "email": null,
    "slaAccepted": true,
    "firstLogin": false,
    "showTutorial": false,
    "username": "Administrator"
}' https://localhost:9000/pa-admin-api/v3/users/1 > /dev/null

# echo "INFO: changing initial password"
curl -k -X PUT -u Administrator:2Access --silent -H "X-Xsrf-Header: PingAccess" -d '{
  "currentPassword": "2Access",
  "newPassword": "'"${INITIAL_ADMIN_PASSWORD}"'"
}' https://localhost:9000/pa-admin-api/v3/users/1/password > /dev/null

# {\"name\":\"IPAddress\",\"value\":\"10.0.2.68\"}
# Generate Cert for PingAccess Host
curl -k -X POST -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" -d "{
        \"keySize\": 2048,
        \"subjectAlternativeNames\":[],
        \"keyAlgorithm\":\"RSA\",
        \"alias\":\"PingAccess: CONFIG QUERY\",
        \"organization\":\"Ping Identity\",
        \"validDays\":365,
        \"commonName\":\"pingaccess\",
       \"country\":\"US\",
        \"signatureAlgorithm\":\"SHA256withRSA\"
}" https://localhost:9000/pa-admin-api/v3/keyPairs/generate > /dev/null

curl -k -X PUT -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" -d "{
    \"name\": \"CONFIG QUERY\",
    \"useServerCipherSuiteOrder\": false,
    \"keyPairId\": 5
}" https://localhost:9000/pa-admin-api/v3/httpsListeners/2 > /dev/null

# Update admin config host
curl -k -X PUT -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" -d "{
        \"hostPort\": \"pingaccess:443\",
        \"httpProxyId\": 0,
        \"httpsProxyId\": 0
}" https://localhost:9000/pa-admin-api/v3/adminConfig > /dev/null

#echo "importing data"
#curl -k -v -X POST -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "Content-Type: application/json" -H "X-Xsrf-Header: #PingAccess" 
#  -d @${STAGING_DIR}/instance/data/data.json 
#  https://localhost:9000/pa-admin-api/v3/config/import

#echo "apps after import"
#curl -k -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" https://localhost:9000/#pa-admin-api/v3/applications