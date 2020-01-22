#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

${VERBOSE} && set -x

# Allow overriding the backup URL with an arg
test ! -z "${1}" && BACKUP_URL="${1}"
echo "Downloading from location ${BACKUP_URL}"

# Install AWS CLI if the upload location is S3
if test "${BACKUP_URL#s3}" == "${BACKUP_URL}"; then
   echo_red "Upload location is not S3"
   exit 1
else
   installTools
fi

BUCKET_URL_NO_PROTOCOL=${BACKUP_URL#s3://}
BUCKET_NAME=$(echo ${BUCKET_URL_NO_PROTOCOL} | cut -d/ -f1)

DIRECTORY_NAME=$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')

if test "${BACKUP_URL}" == */pingaccess; then
  TARGET_URL="${BACKUP_URL}"
else
  TARGET_URL="${BACKUP_URL}/${DIRECTORY_NAME}"
fi

# Filter data.zip to most recent uploaded files that occured 3 days ago.
# AWS has a 1000 list-object limit per request. This will help filter out older backup files.
FORMAT="+%Y-%m-%d"
DAYS=${S3_BACKUP_FILTER_DAY_COUNT-3}
DAYS_AGO=$(date --date="@$(($(date +%s) - (${DAYS} * 24 * 3600)))" "${FORMAT}")

# Get the name of the latest backup zip file from s3
DATA_BACKUP_FILE=$( aws s3api list-objects \
  --bucket "${BUCKET_NAME}" \
  --prefix "${DIRECTORY_NAME}/data" \
  --query 'reverse(sort_by(Contents[?LastModified>=`${DAYS_AGO}`], &LastModified))[0].Key' \
  | tr -d '"' )

# If a backup file in s3 exist
if ! test -z "${DATA_BACKUP_FILE}"; then

  # extract only the file name
  DATA_BACKUP_FILE=${DATA_BACKUP_FILE#${DIRECTORY_NAME}/}

  # Rename s3 backup filename when copying onto pingfederate admin
  DST_FILE="data.json"
  DST_DIRECTORY="/tmp/k8s-s3-download-archive"
  mkdir -p ${DST_DIRECTORY}

  # Download latest backup file from s3 bucket
  aws s3 cp "${TARGET_URL}/${DATA_BACKUP_FILE}" "${DST_DIRECTORY}/${DST_FILE}"
  AWS_API_RESULT="${?}"

  echo "Download return code: ${AWS_API_RESULT}"

  if [ "${AWS_API_RESULT}" != "0" ]; then
    echo_red "Download was unsuccessful - crash the container"
    exit 1
  fi

  echo "importing data"
  make_api_request -X POST -H "Content-Type: application/json" \
    -d @${DST_DIRECTORY}/${DST_FILE} \
    https://localhost:9000/pa-admin-api/v3/config/import

  # Validate admin API call was successful and that zip isn't corrupted
  if test ! $? -eq 0; then
    echo "Failed to export archive"
    # Cleanup k8s-s3-upload-archive temp directory
    #rm -rf ${DST_DIRECTORY}
    exit 0
  fi

  # Print the filename of the downloaded file from s3
  echo "Download file name: ${DATA_BACKUP_FILE}"

  # Print listed files from drop-in-deployer
  DST_DIR_CONTENTS=$(mktemp)
  ls ${OUT_DIR}/instance/server/default/data/drop-in-deployer > ${DST_DIR_CONTENTS}
  cat ${DST_DIR_CONTENTS}

else

  echo "No archive data found"
  
fi
