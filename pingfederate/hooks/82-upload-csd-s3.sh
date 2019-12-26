#!/usr/bin/env sh

${VERBOSE} && set -x

# TODO: may need to uncomment the following. Does PF need?
# Set PATH - since this is executed from within the server process, it may not have all we need on the path
#export PATH="${PATH}:${SERVER_ROOT_DIR}/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"

# Allow overriding the log archive URL with an arg
test ! -z "${1}" && PF_ARCHIVE_URL="${1}"
echo "Uploading to location ${PF_ARCHIVE_URL}"

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

# Check for archive folder on server
if test -d "${OUT_DIR}/instance/server/default/data/archive"; then
  
  # cd into archive directory
  cd "${OUT_DIR}/instance/server/default/data/archive"

  #TODO - look into s3 sync. s3 sync will give you the ability to upload new files
  PF_BACKUP_OUT=$(find . -name data\*zip -type f | sort | tail -1)

  # aws s3 cp calvin.txt "${PF_ARCHIVE_URL}/${DST_FILE}"
  aws s3 cp ${PF_BACKUP_OUT} "${PF_ARCHIVE_URL}"

  echo "Upload return code: ${?}"

  # Remove the CSD file so it is doesn't fill up the server's filesystem.
  #rm -f "${PF_BACKUP_OUT}"

  # Print the filename so callers can figure out the name of the CSD file that was uploaded.
  echo "${PF_BACKUP_OUT#./}"

else
  echo "Nothing to archive at the moment"
fi