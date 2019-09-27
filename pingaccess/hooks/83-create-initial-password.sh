#!/usr/bin/env sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

host=`hostname`

echo "host cal ${host}"

curl -k -X PUT -u Administrator:2Access --silent -H "X-Xsrf-Header: PingAccess" -d '{ "email": null,
    "slaAccepted": true,
    "firstLogin": false,
    "showTutorial": false,
    "username": "Administrator"
}' "https://${host}:9000/pa-admin-api/v3/users/1"

# echo "INFO: changing initial password"
curl -k -X PUT -u Administrator:2Access --silent -H "X-Xsrf-Header: PingAccess" -d '{
  "currentPassword": "2Access",
  "newPassword": "'"${INITIAL_ADMIN_PASSWORD}"'"
}' "https://${host}:9000/pa-admin-api/v3/users/1/password"