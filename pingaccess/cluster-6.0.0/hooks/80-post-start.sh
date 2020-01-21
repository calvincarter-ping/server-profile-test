#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"

if test ! -z "${OPERATIONAL_MODE}" && \
   test "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE"; then
    if test ! -f ${OUT_DIR}/instance/pingaccess_cert_complete_flag; then
      run_hook "81-import-initial-configuration.sh"
    else
      echo "run plan ${RUN_PLAN}"
      echo "restart logic"
    fi
fi