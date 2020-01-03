#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- Once both the remote (i.e. git) and local server-profiles have been merged
#- then we can push that out to the instance.  This will override any files found
#- in the ${SERVER_ROOT_DIR} directory.
#
${VERBOSE} && set -x

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

if test -d "${STAGING_DIR}/instance" && find "${STAGING_DIR}/instance" -type f | read; then

    if test ${RUN_PLAN} = "RESTART"; then
        run_hook "83-download-archive-data-s3.sh"
    elif test ! -z "${OPERATIONAL_MODE}" && test "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE" && test "${IS_MANUAL_RECOVER}" = "YES"; then
        run_hook "83-download-archive-data-s3.sh"
    else
        echo "merging ${STAGING_DIR}/instance to ${SERVER_ROOT_DIR}"
        copy_files "${STAGING_DIR}/instance" "${SERVER_ROOT_DIR}"
    fi
fi