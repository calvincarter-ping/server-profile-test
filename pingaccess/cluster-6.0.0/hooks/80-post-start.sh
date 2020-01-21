#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"

if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" ]]; then
  run_hook "81-import-initial-configuration.sh"
elif [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "STANDALONE" ]]; then
  run_hook "81-import-initial-configuration.sh"
  run_hook "82-import-application-configuration.sh"
fi