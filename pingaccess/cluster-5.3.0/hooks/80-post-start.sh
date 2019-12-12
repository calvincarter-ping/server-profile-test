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

    run_hook "81-import-initial-configuration.sh"

  elif test ${RUN_PLAN} = "RESTART" ; then

    if test -f ${OUT_DIR}/instance/pingaccess_cert_complete ; then
      echo "echo pingaccess_cert_complete will start server"
      echo "Bringing eth0 back up..."
      ip link set eth0 up
    else
      # TODO: fill in appropriate action if admin node configuration was unsuccessful
      echo "Error Occured"
    fi

  fi
fi