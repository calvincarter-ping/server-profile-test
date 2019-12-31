#!/usr/bin/env sh

${VERBOSE} && set -x

# Set PATH - since this is executed from within the server process, it may not have all we need on the path
export PATH="${PATH}:${SERVER_ROOT_DIR}/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"

# Allow overriding the log archive URL with an arg
test ! -z "${1}" && PF_ARCHIVE_URL="${1}"
echo "Downloading from location ${PF_ARCHIVE_URL}"

# Install AWS CLI if the upload location is S3
if test "${PF_ARCHIVE_URL#s3}" == "${PF_ARCHIVE_URL}"; then
  echo "Upload location is not S3"
  exit 0
elif ! which aws > /dev/null; then
  echo "Installing AWS CLI"
  apk --update add python3
  pip3 install --no-cache-dir --upgrade pip
  pip3 install --no-cache-dir --upgrade awscli
fi

# Get the name of the latest backup zip file in s3
PF_DATA_BACKUP=$(aws s3 ls ${PF_ARCHIVE_URL} | sort | tail -1 | awk '{print $4}')

# Download latest backup file from s3 if it exist
if ! test -z "${PF_DATA_BACKUP}"; then

  # Rename s3 backup filename when copying onto pingfederate admin
  DST_FILE="data.zip"

  # Download latest backup file from s3 bucket
  aws s3 cp "${PF_ARCHIVE_URL}/${PF_DATA_BACKUP}" "${OUT_DIR}/instance/server/default/data/drop-in-deployer/${DST_FILE}"

  echo "Download return code: ${?}"

  # Print the filename of the downloaded file from s3.
  ls ${OUT_DIR}/instance/server/default/data/drop-in-deployer

else
  echo "No archive data found"
fi