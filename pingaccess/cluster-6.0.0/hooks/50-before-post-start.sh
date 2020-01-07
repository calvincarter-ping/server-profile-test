#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"

echo `set`
echo_green 'Checking if OPERATIONAL_MODE is set...'
echo "OPERATIONAL_MODE:"${OPERATIONAL_MODE}

if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_ENGINE" ]]; then
  run_hook "51-add-engine.sh"
fi