#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- This script is used to import any configurations that are
#- needed after PingAccess starts

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

INITIAL_ADMIN_PASSWORD=${INITIAL_ADMIN_PASSWORD:=2FederateM0re}

# START scenario
# 1) pa.jwk isn't loaded. Container is built for 1st time, run 81-import-initial-configuration.sh. PV will retain OUT_DIR
# 2) OUT_DIR  


if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" ]]; then
  if test ${RUN_PLAN} = "START" ; then
  #if ! test -f ${OUT_DIR}/instance/conf/pa.jwk ; then
  #  echo "INFO: No 'pa.jwk' found in /instance/conf"
  #  if ! test -f ${OUT_DIR}/instance/data/data.json ; then
  #    echo "INFO: No file named 'data.json' found in /instance/data"
  #    echo "INFO: skipping config import"
  #  fi
  #else 
    if ! test -f ${OUT_DIR}/instance/conf/initial_start_complete ; then
      run_hook "81-import-initial-configuration.sh"
    else
      "echo initial_start_complete detected will restart with backup configuration"
    fi
  elif test ${RUN_PLAN} = "RESTART" ; then
    echo "echo running restart calvin"
  fi
fi

#if [[ ! -z "${OPERATIONAL_MODE}" && "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" ]]; then
#  echo "Bringing eth0 back up..."
#  ip link set eth0 up
#fi 