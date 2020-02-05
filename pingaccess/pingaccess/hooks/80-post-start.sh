#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

if test ! -z "${OPERATIONAL_MODE}" && test "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE"; then

  setupS3Configuration

  CERTFLAG_FILE="$(aws s3 ls ${S3_CERTFLAG_URL} > /dev/null 2>&1;echo $?)"
  
  # If cert flag exist then attempt to download the latest data.json
  if test "${CERTFLAG_FILE}" = "0"; then

    run_hook "83-download-archive-data-s3.sh"

  elif test "${CERTFLAG_FILE}" != "1"; then

    echo "error occured"

  else

    # First time running import initial configuration and copy
    # certflag, master key, and H2 database to S3

    run_hook "81-import-initial-configuration.sh"
    run_hook "82-upload-archive-data-s3.sh"
    
    SERVER=$(ps | grep "${OUT_DIR}/instance/bin/run.sh" | awk '{print $1; exit}')

    touch /tmp/pingaccess_cert_complete_flag

    # Copy Cert flag to S3 Bucket
    if test "$(aws s3 cp /tmp/pingaccess_cert_complete_flag ${S3_CERTFLAG_URL} > /dev/null 2>&1;echo $?)" != "0"; then
      echo "Setting cert flag error"
      exit 1
    fi

    # Copy Master Key to S3 Bucket
    if test "$(aws s3 cp ${OUT_DIR}/instance/conf/pa.jwk ${S3_MASTER_KEY_URL} > /dev/null 2>&1;echo $?)" != "0"; then
      echo "Setting master key error"
      exit 1
    fi

    # Copy H2 Database to S3 Bucket
    if test "$(aws s3 cp ${OUT_DIR}/instance/data/PingAccess.mv.db ${S3_H2_DATABASE_URL} > /dev/null 2>&1;echo $?)" != "0"; then
      echo "Setting master key error"
      exit 1
    fi

    # Terminate admin to signal a k8s restart
    echo "Restarting PingAccess Admin"
    kill -SIGHUP "${SERVER}"
  fi

fi