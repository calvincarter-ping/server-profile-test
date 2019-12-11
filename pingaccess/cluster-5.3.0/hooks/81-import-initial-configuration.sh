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

while true; do
  curl -ss --silent -o /dev/null -k https://localhost:9000/pa/heartbeat.ping 
  if ! test $? -eq 0 ; then
    echo "Import Config: Server not started, waiting.."
    sleep 3
  else
    echo "PA started, begin import"
    break
  fi
done
set -x
INITIAL_ADMIN_PASSWORD=${INITIAL_ADMIN_PASSWORD:=2FederateM0re}
curl -k -v -X PUT -u Administrator:2Access --silent -H "X-Xsrf-Header: PingAccess" -d '{ "email": null,
    "slaAccepted": true,
    "firstLogin": false,
    "showTutorial": false,
    "username": "Administrator"
}' https://localhost:9000/pa-admin-api/v3/users/1 > /dev/null

curl -k -X PUT -u Administrator:2Access --silent -H "X-Xsrf-Header: PingAccess" -d '{
  "currentPassword": "2Access",
  "newPassword": "'"${INITIAL_ADMIN_PASSWORD}"'"
}' https://localhost:9000/pa-admin-api/v3/users/1/password > /dev/null

# {\"name\":\"dNSName\",\"value\":\"pingaccess\"}
curl -v -k -X POST -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" -d "{
        \"keySize\": 2048,
        \"subjectAlternativeNames\":[],
        \"keyAlgorithm\":\"RSA\",
        \"alias\":\"pingaccess-console\",
        \"organization\":\"Ping Identity\",
        \"validDays\":365,
        \"commonName\":\"pingaccess\",
        \"country\":\"US\",
        \"signatureAlgorithm\":\"SHA256withRSA\"
}" https://localhost:9000/pa-admin-api/v3/keyPairs/generate

curl -v -k -X PUT -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" -d "{
    \"name\": \"CONFIG QUERY\",
    \"useServerCipherSuiteOrder\": false,
    \"keyPairId\": 5
}" https://localhost:9000/pa-admin-api/v3/httpsListeners/2

# Update admin config host
curl -v -k -X PUT -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" -d "{
        \"hostPort\": \"pingaccess:9090\",
        \"httpProxyId\": 0,
        \"httpsProxyId\": 0
}" https://localhost:9000/pa-admin-api/v3/adminConfig

#echo "importing data"
#curl -k -v -X POST -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "Content-Type: application/json" -H "X-Xsrf-Header: PingAccess" \
#  -d @${STAGING_DIR}/instance/data/data.json \
#  https://localhost:9000/pa-admin-api/v3/config/import

#echo "apps after import"
#curl -k -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" https://localhost:9000/pa-admin-api/v3/applications

touch ${OUT_DIR}/instance/initial_start_complete