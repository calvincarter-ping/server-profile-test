#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- This script is used to import any configurations that are
#- needed after PingAccess starts

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" ]]; then
  if test ${RUN_PLAN} = "START" ; then

    if ! test -f ${OUT_DIR}/instance/initial_start_complete ; then
      run_hook "81-import-initial-configuration.sh"
    else
      echo "echo initial_start_complete detected will restart with backup configuration"
    fi

  elif test ${RUN_PLAN} = "RESTART" ; then
    run_hook "82-import-backup-configuration.sh"
  fi

fi