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
# Wait for Admin node to become ready so we can get configuration. If the engine comes up first
# and no other engine is already running then it will fail to obtain configuration as it is the
# first server to join the cluster. Another server joining the cluster does *not* trigger a
# a fresh attempt to obtain configuration and manual intervention is required to push the
# configuration from the admin server. This code attempts to minimize the chance of this 
# happening without completely blocking start-up.
# 
# The worst case scenario is an enging scaling event with the admin server down. In this case it
# could take the full timebox duration before the sever starts when it could get configuration
# from another engine. The admin server usually starts within 60-90 seconds.
#
echo "Waiting up to 3 minutes for admin server to become ready"
count=180
while [ "$(kubectl get pods|grep "pingfederate-admin"|awk '{print $2}'|grep "1/1" >/dev/null 2>&1;echo "$?")" != "0" ] &&  [ "${count}" -gt "0" ]; do
   sleep 1
   count=$(( count - 1 ))
done   

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
if ! [ -f ../server/default/data/pf.jwk ]; then
   # echo "No local master key found check s3 for a pre-existing key"
   # result="$(aws s3 ls ${masterKey} > /dev/null 2>&1;echo $?)"
   # if [ "${result}" = "0" ]; then
   #    echo "A master key does exist on S3 attempt to retrieve it"
   #    if [ "$(aws s3 cp "${masterKey}" ../server/default/data/pf.jwk > /dev/null 2>&1;echo $?)" != "0" ]; then
   #       echo_red "Retrieval was unsuccessful - crash the container to prevent spurious key creation"
   #       exit 1
   #    else
   #       echo "Pre-existing master key found - using it"
   #       obfuscatePassword
   #    fi
   # elif [ "${result}" != "1" ]; then
   #    echo_red "Unexpected error accessing S3 - crash the container to prevent spurious key creation"
   #    aws s3 ls ${masterKey}
   #    exit 1
   # else
   #    echo "No pre-existing master key found - crash the container to prevent spurious key creation"
   #    exit 1
   # fi


   echo "No local master key found check s3 for a pre-existing key"
   if ! [ -z "${DATA_BACKUP_FILE}" ]; then

      echo "A master key does exist on S3 attempt to retrieve it"

      DATA_BACKUP_FILE=${DATA_BACKUP_FILE#${DIRECTORY_NAME}/}

      # Rename s3 backup filename when copying onto pingfederate admin
      DST_FILE="data.zip"

      DST_DIRECTORY="/tmp/k8s-s3-archive"

      mkdir -p ${DST_DIRECTORY}

      # Download latest backup file from s3 bucket
      aws s3 cp "${TARGET_URL}/${DATA_BACKUP_FILE}" "${DST_DIRECTORY}/${DST_FILE}"
      AWS_API_RESULT="${?}"

      echo "Download return code: ${AWS_API_RESULT}"

      if [ "${AWS_API_RESULT}" != "0" ]; then
         echo_red "Retrieval was unsuccessful - crash the container to prevent spurious key creation"
         exit 1
      else

         echo "Pre-existing master key found - using it"

         unzip "${DST_DIRECTORY}/${DST_FILE}"
         
         cp "${DST_DIRECTORY}/pf.jk" "${OUT_DIR}/instance/server/default/data"
         
         obfuscatePassword

         # Print the filename of the downloaded file from s3
         echo "Download file name: ${DATA_BACKUP_FILE}"

         # Print listed files from drop-in-deployer
         ls ${OUT_DIR}/instance/server/default/data/drop-in-deployer

         # cleanup
         #rm -r ${DST_DIRECTORY}
      fi
   else
      echo "No pre-existing master key found in s3 - obfuscate will create one which we will upload"
      obfuscatePassword
   fi

else
   echo "A pre-existing master key was found on disk - using it"
   obfuscatePassword
fi
cd "${currentDir}"
