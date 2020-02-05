#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

if test ! -z "${OPERATIONAL_MODE}" && test "${OPERATIONAL_MODE}" = "CLUSTERED_CONSOLE"; then

  setupS3Configuration  

  S3_MASTER_KEY_URL="${TARGET_URL}/pa.jwk"
  S3_H2_DATABASE_URL="${TARGET_URL}/PingAccess.mv.db"

  S3_MASTER_KEY_FILE="$(aws s3 ls ${S3_MASTER_KEY_URL} > /dev/null 2>&1;echo $?)"
  S3_H2_DATABASE_FILE="$(aws s3 ls ${S3_H2_DATABASE_URL} > /dev/null 2>&1;echo $?)"

  # If master key and H2 database is found. Attempt to copy into container
  if test "${S3_MASTER_KEY_FILE}" = "0" && test "${S3_H2_DATABASE_FILE}" = "0"; then

    # Copy Master Key
    if test "$(aws s3 cp ${S3_MASTER_KEY_URL} ${OUT_DIR}/instance/conf/pa.jwk > /dev/null 2>&1;echo $?)" != "0"; then
      echo "Copy master key error"
      exit 1
    fi

    # Copy H2 Database
	  if test "$(aws s3 cp ${S3_H2_DATABASE_URL} ${OUT_DIR}/instance/data/PingAccess.mv.db > /dev/null 2>&1;echo $?)" != "0"; then
      echo "Copy H2 Database error"
      exit 1
    fi
    
  elif test "${S3_MASTER_KEY_FILE}" != "1" || test "${S3_H2_DATABASE_FILE}" != "1" ; then
    echo "error occured when viewing files in S3 bucket"
  fi

fi