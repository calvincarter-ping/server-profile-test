#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"

if test ! -z "${OPERATIONAL_MODE}" && \
   test "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE"; then
    if test "${RUN_PLAN}" = "START"; then
      run_hook "81-import-initial-configuration.sh"
      run_hook "82-upload-archive-data-s3.sh"
      # Terminate admin to signal a k8s restart
      kill -1 $(ps | grep "${OUT_DIR}/instance/bin/run.sh" | awk '{print $1}')
    fi
fi