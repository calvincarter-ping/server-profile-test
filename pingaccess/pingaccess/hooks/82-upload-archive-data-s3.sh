#!/usr/bin/env sh

. "${HOOKS_DIR}/pingcommon.lib.sh"
. "${HOOKS_DIR}/utils.lib.sh"

${VERBOSE} && set -x

setupS3Configuration

# Wait until pingaccess admin localhost is available
pingaccess_admin_localhost_wait

echo "Uploading to location ${BACKUP_URL}"

# Create and export archive data into file data.mm-dd-YYYY.HH.MM.SS.zip
DST_FILE="data-`date +%m-%d-%Y.%H.%M.%S`.json"
DST_DIRECTORY="/tmp/k8s-s3-upload-archive"
mkdir -p ${DST_DIRECTORY}

# Make request to admin API and export latest data
make_api_request -X POST -H "Accept: application/json" -H "X-Requested-With: XMLHttpRequest" \
-H "Connection: keep-alive" https://localhost:9000/pa-admin-api/v3/config/export/workflows \
-o ${DST_DIRECTORY}/${DST_FILE}
WORKFLOW_ID=$( cat ${DST_DIRECTORY}/${DST_FILE} | jq 'select(.status=="In Progress") | .id' )

# Validate admin API call was successful and that zip isn't corrupted
if test ! $? -eq 0; then
  echo "Failed to export archive"
  # Cleanup k8s-s3-upload-archive temp directory
  #rm -rf ${DST_DIRECTORY}
  exit 0
fi

echo ${WORKFLOW_ID}

if test ! -z "${WORKFLOW_ID}"; then
  sleep 10
  make_api_request -X GET -H "Accept: application/json" \
  -H "Connection: keep-alive" https://localhost:9000/pa-admin-api/v3/config/export/workflows/${WORKFLOW_ID}/data \
  -o ${DST_DIRECTORY}/${DST_FILE}
fi

echo "Creating directory ${DIRECTORY_NAME} under bucket ${BUCKET_NAME}"
aws s3api put-object --bucket "${BUCKET_NAME}" --key "${DIRECTORY_NAME}"/

aws s3 cp "${DST_DIRECTORY}/${DST_FILE}" "${TARGET_URL}/"
AWS_API_RESULT="${?}"

echo "Upload return code: ${AWS_API_RESULT}"

if [ "${AWS_API_RESULT}" != "0" ]; then
  echo "Upload was unsuccessful - crash the container"
  exit 1
fi

# Print the filename of the uploaded file to s3
echo "Uploaded file name: ${DST_FILE}"

# Print listed files from k8s-s3-upload-archive
DST_DIR_CONTENTS=$(mktemp)
ls ${DST_DIRECTORY} > ${DST_DIR_CONTENTS}
cat ${DST_DIR_CONTENTS}

# Cleanup k8s-s3-upload-archive temp directory
rm -rf ${DST_DIRECTORY}