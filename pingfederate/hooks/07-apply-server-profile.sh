#!/usr/bin/env sh

########################################################################################################################
# Copy server profile content into SERVER_ROOT_DIR.
#
# Arguments
#   N/A
########################################################################################################################
applyServerProfile() {
    if test -d "${STAGING_DIR}/instance" && find "${STAGING_DIR}/instance" -type f | read; then
        echo "merging ${STAGING_DIR}/instance to ${SERVER_ROOT_DIR}"
        copy_files "${STAGING_DIR}/instance" "${SERVER_ROOT_DIR}"
    fi
}

# Start of script
echo "Hello from the baseline server profile 07-apply-server-profile hook!"

${VERBOSE} && set -x

. "${HOOKS_DIR}/pingcommon.lib.sh"

# Only recover archive data on PingFederate Admin
if test ! -z "${OPERATIONAL_MODE}" && test "${OPERATIONAL_MODE}" != "CLUSTERED_ENGINE"; then

    # If pod is restarting due to error OR upon a manual data recover look to recover archive data
    #if test ${RUN_PLAN} = "RESTART" || test "${IS_MANUAL_RECOVER}" = "YES"; then

        run_hook "83-download-archive-data-s3.sh"

        # Script may exit with status code 3 if there was nothing to recover. If so proceed to
        # apply server profile
        if test "${?}" = 3; then
            applyServerProfile
        fi

    #else # apply server profile if its the 1st initial deployment
    #    applyServerProfile
    #fi

else
    applyServerProfile
fi