#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"

if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" ]]; then
  run_hook "81-import-initial-configuration.sh"
fi