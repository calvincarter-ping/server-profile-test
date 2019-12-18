#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- This script is used to import any configurations that are
#- needed after PingAccess starts

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" ]]; then
  echo "run plan ${RUN_PLAN}"
  #if test ${RUN_PLAN} = "START" ; then
  if ! test -f ${OUT_DIR}/instance/pingaccess_cert_complete ; then
    run_hook "81-import-initial-configuration.sh"
  elif test ${RUN_PLAN} = "RESTART" ; then
    echo "restart logic"
  fi
fi