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

curl -k -X POST -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" -d "{
        \"name\": \"${PA_CONSOLE_HOST}\",
        \"host\": \"${PA_CONSOLE_HOST}\",
        \"port\": \"9090\"
}" https://localhost:9000/pa-admin-api/v3/proxies > /dev/null

# Update admin config host
curl -k -X PUT -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" -d "{
        \"hostPort\": \"localhost:9090\",
        \"httpProxyId\":1,
        \"httpsProxyId\":1
}" https://localhost:9000/pa-admin-api/v3/adminConfig > /dev/null

#echo "importing data"
#curl -k -v -X POST -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "Content-Type: application/json" -H "X-Xsrf-Header: #PingAccess" 
#  -d @${STAGING_DIR}/instance/data/data.json 
#  https://localhost:9000/pa-admin-api/v3/config/import

#echo "apps after import"
#curl -k -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess" https://localhost:9000/#pa-admin-api/v3/applications