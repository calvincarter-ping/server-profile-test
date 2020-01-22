#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

if test ! -z "${OPERATIONAL_MODE}" && test "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE"; then

  installTools

  BUCKET_URL_NO_PROTOCOL=${BACKUP_URL#s3://}
  DIRECTORY_NAME=$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')

  if test "${BACKUP_URL}" == */pingaccess; then
    TARGET_URL="${BACKUP_URL}"
  else
    TARGET_URL="${BACKUP_URL}/${DIRECTORY_NAME}"
  fi
  CERTFLAG="${TARGET_URL}/pingaccess_cert_complete_flag"

  RESULT="$(aws s3 ls ${CERTFLAG} > /dev/null 2>&1;echo $?)"
  echo "result calvin ${RESULT}"
  if test "${RESULT}" = "0"; then
    run_hook "83-download-archive-data-s3"
  elif test "${RESULT}" = "1" || test "${RESULT}" = "2"; then
    echo "error occured"
  else
    run_hook "81-import-initial-configuration.sh"
    run_hook "82-upload-archive-data-s3.sh"
    SCRIPT=$(ps | grep "${OUT_DIR}/instance/bin/run.sh" | awk '{print $1; exit}')

    # Terminate admin to signal a k8s restart
    kill -1 "${SCRIPT}"
  fi
fi