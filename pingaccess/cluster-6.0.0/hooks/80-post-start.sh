#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"

if test ! -z "${OPERATIONAL_MODE}" && \
   test "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE"; then

    echo "run plan ${RUN_PLAN}"

    if test "${RUN_PLAN}" = "START"; then

      echo "run plan ${RUN_PLAN}"

      run_hook "81-import-initial-configuration.sh"
      run_hook "82-upload-archive-data-s3.sh"
      SCRIPT=$(ps | grep "${OUT_DIR}/instance/bin/run.sh" | awk '{print $1; exit}')
      # Terminate admin to signal a k8s restart
      kill -1 "${SCRIPT}"
    fi
fi