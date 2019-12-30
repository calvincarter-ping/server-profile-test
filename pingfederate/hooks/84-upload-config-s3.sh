#!/usr/bin/env sh

${VERBOSE} && set -x

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

FILES=""
for FILE in "${!PING_FEDERATE_CONFIG_BACKUP_@}"; do
    FILES="${FILES} ${!FILE}"
done

if ! test -z "${FILES}"; then
  zip config.zip ${FILES}
else
  echo "No config data to archive at the moment"
fi