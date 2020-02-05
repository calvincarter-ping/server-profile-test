#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

if test ! -z "${OPERATIONAL_MODE}" && test "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE"; then


  setupS3Configuration

  echo ${TARGET_URL}
  

  MASTER_KEY="${TARGET_URL}/pa.jwk"
  H2_DATABASE="${TARGET_URL}/PingAccess.mv.db"

  RESULT_MASTER_KEY="$(aws s3 ls ${MASTER_KEY} > /dev/null 2>&1;echo $?)"
  RESULT_H2_DATABASE="$(aws s3 ls ${H2_DATABASE} > /dev/null 2>&1;echo $?)"

  if test "${RESULT_MASTER_KEY}" = "0" && test "${RESULT_H2_DATABASE}" = "0"; then
    if test "$(aws s3 cp ${MASTER_KEY} ${OUT_DIR}/instance/conf/pa.jwk > /dev/null 2>&1;echo $?)" != "0"; then
      echo "Copy master key error"
      exit 1
    fi

	if test "$(aws s3 cp ${H2_DATABASE} ${OUT_DIR}/instance/data/PingAccess.mv.db > /dev/null 2>&1;echo $?)" != "0"; then
      echo "Copy master key error"
      exit 1
    fi
  elif test "${RESULT_MASTER_KEY}" != "1" || test "${RESULT_H2_DATABASE}" != "1" ; then
    echo "error occured"
  fi
fi