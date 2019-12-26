#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- This is called after the start or restart sequence has finished and before 
#- the server within the container starts
#

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

${VERBOSE} && set -x

echo_green "Before-post-start script running plan ${RUN_PLAN}"
if test ${RUN_PLAN} = "START" ; then
  #run_hook "83-download-csd-s3.sh"
fi