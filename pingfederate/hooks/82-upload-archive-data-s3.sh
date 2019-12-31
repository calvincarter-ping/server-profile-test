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
  
  # cd into pingfederate admin archive directory
  cd "${OUT_DIR}/instance/server/default/data/archive"

  # Find at least 1 data zip file
  PF_BACKUP_OUT=$(find . -name data\*zip -type f )

  # At least 1 data zip file must exist before calling aws s3
  if ! test -z "${PF_BACKUP_OUT}"; then

    # Sycronize all data zip files to s3 bucket
    aws s3 sync --exclude "*" --include "*.zip" "${OUT_DIR}/instance/server/default/data/archive" "${PF_ARCHIVE_URL}"

    echo "Upload return code: ${?}"
    
  else
    echo "Nothing to archive at the moment"
  fi

else
  echo "Nothing to archive at the moment"
fi