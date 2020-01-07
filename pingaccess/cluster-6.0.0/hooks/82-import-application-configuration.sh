#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

# Wait until pingaccess admin localhost is available
pingaccess_admin_localhost_wait

set -x

make_api_request -X POST -d "{
  \"secure\":true,
  \"trustedCertificateGroupId\":0,
  \"name\":\"PF Runtime Port\",
  \"port\":\"9031\"
}" https://localhost:9000/pa-admin-api/v3/engineListeners


make_api_request -X PUT -d "{
  \"description\":null,
  \"issuer\":\"https://pingfederate:9031\",
  \"trustedCertificateGroupId\":2,
  \"useProxy\":false,
  \"useSlo\":false,
  \"skipHostnameVerification\":true
}" https://localhost:9000/pa-admin-api/v3/pingfederate/runtime


make_api_request -X PUT -d "{
  \"port\":9999,
  \"adminUsername\":\"Administrator\",
  \"useProxy\":false,
  \"host\":\"pingfederate-admin\",
  \"auditLevel\":\"OFF\",
  \"adminPassword\":{\"value\":\"2FederateM0re\"},
  \"basePath\":null,
  \"secure\":true,
  \"trustedCertificateGroupId\":2
}" https://localhost:9000/pa-admin-api/v3/pingfederate/admin



make_api_request -X PUT -d "{
  \"clientId\":\"rs_client\",
  \"accessValidatorId\":1,
  \"useTokenIntrospection\":false,
  \"name\":\"PingFederate\",
  \"sendAudience\":false,
  \"tokenTimeToLiveSeconds\":-1,
  \"subjectAttributeName\":\"Username\",
  \"clientSecret\":{},
  \"cacheTokens\":false
}" https://localhost:9000/pa-admin-api/v3/pingfederate/accessTokens


OUT=$( make_api_request -X POST -d "{
  \"port\":\"443\",
  \"agentResourceCacheTTL\":900,
  \"host\":\"*\"
}" https://localhost:9000/pa-admin-api/v3/virtualhosts )
V_HOST_443_ID=$( jq -n "$OUT" | jq '.id' )

OUT=$( make_api_request -X POST -d "{
  \"port\":\"9031\",
  \"agentResourceCacheTTL\":900,
  \"host\":\"localhost\"
}" https://localhost:9000/pa-admin-api/v3/virtualhosts )
V_HOST_9031_ID=$( jq -n "$OUT" | jq '.id' )



OUT=$( make_api_request -X POST -d "{
  \"loadBalancingStrategyId\":0,
  \"targets\":[\"pingfederate:9031\"],
  \"useProxy\":false,
  \"name\":\"PingFederate Docker\",
  \"useTargetHostHeader\":false,
  \"maxConnections\":-1,
  \"maxWebSocketConnections\":-1,
  \"secure\":true,
  \"keepAliveTimeout\":0,
  \"trustedCertificateGroupId\":2,
  \"sendPaCookie\":true
}" https://localhost:9000/pa-admin-api/v3/sites )
SITE_PINGFED_ID=$( jq -n "$OUT" | jq '.id' )


OUT=$( make_api_request -X POST -d "{
  \"loadBalancingStrategyId\":0,
  \"targets\":[\"httpbin:80\"],
  \"useProxy\":false,
  \"name\":\"httpbin\",
  \"useTargetHostHeader\":false,
  \"maxConnections\":-1,
  \"maxWebSocketConnections\":-1,
  \"secure\":false,
  \"keepAliveTimeout\":0,
  \"trustedCertificateGroupId\":0,
  \"sendPaCookie\":true
}" https://localhost:9000/pa-admin-api/v3/sites )
SITE_HTTPBIN_ID=$( jq -n "$OUT" | jq '.id' )



make_api_request -X POST -d "{
  \"agentId\":null,
  \"enabled\":true,
  \"siteId\":${SITE_HTTPBIN_ID},
  \"defaultAuthType\":null,
  \"virtualHostIds\":[${V_HOST_443_ID}],
  \"requireHTTPS\":true,
  \"identityMappingIds\":{\"Web\":0,\"API\":0},
  \"accessValidatorId\":1,
  \"applicationType\":\"Web\",
  \"caseSensitivePath\":false,
  \"name\":\"httpbin\",
  \"destination\":\"Site\",
  \"realm\":null,
  \"contextRoot\":\"/anything\",
  \"spaSupportEnabled\":true,
  \"id\":0,
  \"description\":\"\",
  \"webSessionId\":0
}" https://localhost:9000/pa-admin-api/v3/applications



make_api_request -X POST -d "{
  \"agentId\":null,
  \"enabled\":true,
  \"siteId\":${SITE_PINGFED_ID},
  \"defaultAuthType\":null,
  \"virtualHostIds\":[${V_HOST_9031_ID}],
  \"requireHTTPS\":true,
  \"identityMappingIds\":{\"Web\":0,\"API\":0},
  \"accessValidatorId\":1,
  \"applicationType\":\"Web\",
  \"caseSensitivePath\":false,
  \"name\":\"PingFederate\",
  \"destination\":\"Site\",
  \"realm\":null,
  \"contextRoot\":\"/\",
  \"spaSupportEnabled\":true,
  \"id\":0,
  \"description\":\"\",
  \"webSessionId\":0
}" https://localhost:9000/pa-admin-api/v3/applications