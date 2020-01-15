#!/usr/bin/env sh

${VERBOSE} && set -x

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

#---------------------------------------------------------------------------------------------
# Function to obfuscate LDAP password
#---------------------------------------------------------------------------------------------

function obfuscatePassword()
{
   #
   # The master key may not exist, this means no key was passed in as a secret and this is the first run of PF 
   # for this environment, we can use the obfuscate utility to generate a master key as a byproduct of obfuscating 
   # the password used to authenticate to PingDirectory in the ldap properties file. The utility obfuscate.sh 
   # expects to run with bash which is not present in the alpine immage, howver the script does work with /bin/sh 
   # so as a temporary measure we simply change the expected environment to sh 
   #
   sed -i -e 's/bash/sh/' ./obfuscate.sh
   #
   # Obfuscate the ldap password
   #
   export PF_LDAP_PASSWORD_OBFUSCATED=$(./obfuscate.sh  ${INITIAL_ADMIN_PASSWORD}| tr -d '\n')
   #
   # Inject obfuscated password into ldap properties file. The password variable is protected with a ${_DOLLAR_}
   # prefix because the file is substituted twice the first pass sets the DN and resets the '$' on the password
   # variable so it's a legitimate candidate for substitution on this, the second pass.
   #
   mv ldap.properties ldap.properties.subst
   envsubst < ldap.properties.subst > ldap.properties
   PF_LDAP_PASSWORD_OBFUSCATED="${PF_LDAP_PASSWORD_OBFUSCATED:8}"
   mv ../server/default/data/pingfederate-ldap-ds.xml ../server/default/data/pingfederate-ldap-ds.xml.subst
   envsubst < ../server/default/data/pingfederate-ldap-ds.xml.subst > ../server/default/data/pingfederate-ldap-ds.xml

}   

#---------------------------------------------------------------------------------------------
# Function to install AWS command line tools
#---------------------------------------------------------------------------------------------

function installTools()
{
   if [ -z "$(which aws)" ]; then
      #   
      #  Install AWS platform specific tools
      #
      echo "Installing AWS CLI tools for S3 support"
      #
      # TODO: apk needs to move to the Docker file as the package manager is plaform specific
      #
      apk --update add python3
      pip3 install --no-cache-dir --upgrade pip
      pip3 install --no-cache-dir --upgrade awscli
   fi
}


#---------------------------------------------------------------------------------------------
# Main Script 
#---------------------------------------------------------------------------------------------

#
# Run script from known location 
#
currentDir="$(pwd)"
cd /opt/out/instance/bin

#
# Install AWS tools
#
if test "${BACKUP_URL#s3}" == "${BACKUP_URL}"; then
   echo_red "Upload location is not S3"
   exit 1
else
   installTools
fi

#
# Setup S3 bucket path components 
#
BUCKET_URL_NO_PROTOCOL=${BACKUP_URL#s3://}
BUCKET_NAME=$(echo ${BUCKET_URL_NO_PROTOCOL} | cut -d/ -f1)
DIRECTORY_NAME=$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')

if test "${BACKUP_URL}" == */pingfederate; then
  TARGET_URL="${BACKUP_URL}"
else
  TARGET_URL="${BACKUP_URL}/${DIRECTORY_NAME}"
fi

# directory="$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')"
# target="${BACKUP_URL}/${directory}"
# bucket="${BACKUP_URL#s3://}"
# masterKey="${BACKUP_URL}/${directory}/pf.jwk"

#
# If the Pingfederate folder does not exist in the s3 bucket, create it
# 
# if [ "$(aws s3 ls ${BACKUP_URL} > /dev/null 2>&1;echo $?)" = "1" ]; then
#    aws s3api put-object --bucket "${bucket}" --key "${directory}/"
# fi

# Get the name of the latest backup zip file from s3
DATA_BACKUP_FILE=$( aws s3api list-objects \
      --bucket "${BUCKET_NAME}" \
      --prefix "${DIRECTORY_NAME}/data" \
      --query "reverse(sort_by(Contents, &LastModified))[:1].Key" --output=text )

#
# We may already have a master key on disk if one was supplied through a secret or the 'in'
# volume. If that is the case we will use that key during obfuscation. If one does not 
# exist we check to see if one was previously uploaded to s3
#
# if ! [ -f ../server/default/data/pf.jwk ]; then
if ! [ -z "${DATA_BACKUP_FILE}" ]; then
   # echo "No local master key found check s3 for a pre-existing key"
   # result="$(aws s3 ls ${masterKey} > /dev/null 2>&1;echo $?)"
   # if [ "${result}" = "0" ]; then
   #    echo "A master key does exist on S3 attempt to retrieve it"
   #    if [ "$(aws s3 cp "${masterKey}" ../server/default/data/pf.jwk > /dev/null 2>&1;echo $?)" != "0" ]; then
   #       echo_red "Retrieval was unsuccessful - crash the container to prevent overwiting the master key"
   #       exit 1
   #    else
   #       echo "Pre-existing master key found - using it"
   #       obfuscatePassword
   #    fi
   # elif [ "${result}" != "1" ]; then
   #    echo_red "Unexpected error accessing S3 - crash the container to prevent overwiting the master key if it exists"
   #    exit 1
   # else
   #    echo "No pre-existing master key found - obfuscate will create one which we will upload"
   #    obfuscatePassword
   #    aws s3 cp ../server/default/data/pf.jwk ${target}/pf.jwk
   # fi

   DATA_BACKUP_FILE=${DATA_BACKUP_FILE#${DIRECTORY_NAME}/}

   # Rename s3 backup filename when copying onto pingfederate admin
   DST_FILE="data.zip"

   # Download latest backup file from s3 bucket
   aws s3 cp "${TARGET_URL}/${DATA_BACKUP_FILE}" "${OUT_DIR}/instance/server/default/data/drop-in-deployer/${DST_FILE}"
   AWS_API_RESULT="${?}"

   echo "Download return code: ${AWS_API_RESULT}"

   if [ "${AWS_API_RESULT}" != "0" ]; then
      echo_red "Retrieval was unsuccessful - crash the container to prevent spurious key creation"
      exit 1
   else
      # Print the filename of the downloaded file from s3
      echo "Download file name: ${DATA_BACKUP_FILE}"

      # Print listed files from drop-in-deployer
      ls ${OUT_DIR}/instance/server/default/data/drop-in-deployer
   fi
else
   echo "A pre-existing master key was found on disk - using it"
   obfuscatePassword
fi
cd "${currentDir}"

