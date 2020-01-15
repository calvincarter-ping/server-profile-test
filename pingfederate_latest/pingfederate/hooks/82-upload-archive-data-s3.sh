#!/usr/bin/env sh

. "${HOOKS_DIR}/utils.lib.sh"

${VERBOSE} && set -x

# Set PATH - since this is executed from within the server process, it may not have all we need on the path
export PATH="${PATH}:${SERVER_ROOT_DIR}/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"

# Allow overriding the backup URL with an arg
test ! -z "${1}" && BACKUP_URL="${1}"
echo "Uploading to location ${BACKUP_URL}"

# Install AWS CLI if the upload location is S3
if test "${BACKUP_URL#s3}" == "${BACKUP_URL}"; then
  echo "Upload location is not S3"
  exit 0
elif ! which aws > /dev/null; then
  echo "Installing AWS CLI"
  apk --update add python3
  pip3 install --no-cache-dir --upgrade pip
  pip3 install --no-cache-dir --upgrade awscli
fi

# Create and export archive data into file data.mm-dd-YYYY.HH.MM.SS.zip
DST_FILE="data-`date +%m-%d-%Y.%H.%M.%S`.zip"
DST_DIRECTORY="/tmp/k8s-archive"
mkdir -p ${DST_DIRECTORY}

# Make request to admin API and export latest data
make_api_request -X GET https://localhost:9999/pf-admin-api/v1/configArchive/export \
    -o ${DST_DIRECTORY}/${DST_FILE}

# Validate admin API call was successful and that zip isn't empty
if test ! $? -eq 0 || test ! -s ${DST_DIRECTORY}/${DST_FILE}; then
  echo "Failed to export archive"
  # Cleanup k8s-archive temp directory
  rm -r ${DST_DIRECTORY}
  exit 1
fi


BUCKET_URL_NO_PROTOCOL=${BACKUP_URL#s3://}
BUCKET_NAME=$(echo ${BUCKET_URL_NO_PROTOCOL} | cut -d/ -f1)
DIRECTORY_NAME=$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')

echo "Creating directory ${DIRECTORY_NAME} under bucket ${BUCKET_NAME}"
aws s3api put-object --bucket "${BUCKET_NAME}" --key "${DIRECTORY_NAME}"/

if test "${BACKUP_URL}" == */pingfederate; then
  TARGET_URL="${BACKUP_URL}"
else
  TARGET_URL="${BACKUP_URL}/${DIRECTORY_NAME}"
fi

aws s3 cp "${DST_DIRECTORY}/${DST_FILE}" "${TARGET_URL}/"

echo "Upload return code: ${?}"

# Print the filename of the uploaded file to s3
echo "Uploaded file name: ${DST_FILE}"

# Print listed files from k8s-archive
ls ${DST_DIRECTORY}

# Cleanup k8s-archive temp directory
rm -r ${DST_DIRECTORY}