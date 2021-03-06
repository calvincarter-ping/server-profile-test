#!/usr/bin/env sh

########################################################################################################################
# Makes curl request to PingAccess API to configure.
#
# Arguments
#   $@ -> The URL and additional needed data to make request
########################################################################################################################
function make_api_request()
{
    curl -k --retry ${API_RETRY_LIMIT} --max-time ${API_TIMEOUT_WAIT} --retry-delay 1 --retry-connrefuse -u Administrator:${INITIAL_ADMIN_PASSWORD} -H "X-Xsrf-Header: PingAccess " "$@"
    if test ! $? -eq 0; then
        echo "Admin API connection refused"
        exit 1
    fi
}

########################################################################################################################
# Makes curl request to PingAccess API to configure.
#
# Arguments
#   $@ -> The URL and additional needed data to make request
########################################################################################################################
function make_initial_api_request()
{
    curl -k --retry ${API_RETRY_LIMIT} --max-time ${API_TIMEOUT_WAIT} --retry-delay 1 --retry-connrefuse -u Administrator:2Access -H "X-Xsrf-Header: PingAccess " "$@"
    if test ! $? -eq 0; then
        echo "Admin API connection refused"
        exit 1
    fi
}

########################################################################################################################
# Makes curl request to localhost PingAccess admin Console heartbeat page.
# If request fails, wait for 3 seconds and try again.
#
# Arguments
#   N/A
########################################################################################################################
function pingaccess_admin_wait()
{
    while true; do
        curl -ss --silent -o /dev/null -k https://localhost:9000/pa/heartbeat.ping 
        if ! test $? -eq 0; then
            echo "Import Config: Server not started, waiting.."
            sleep 3
        else
            echo "PA started, begin import"
            break
        fi
    done
}

########################################################################################################################
# Makes curl request to PingAccess admin cluster heartbeat page.
# If request fails, wait for 3 seconds and try again.
#
# Arguments
#   N/A
########################################################################################################################
function pingaccess_engine_wait()
{
    initializeS3Configuration

    while true; do
        MASTER_KEY_FILE_NAME="$(aws s3 ls ${S3_MASTER_KEY_URL} > /dev/null 2>&1;echo $?)"
        H2_DATABASE_FILENAME="$(aws s3 ls ${S3_H2_DATABASE_URL} > /dev/null 2>&1;echo $?)"
        CERTFLAG_FILENAME="$(aws s3 ls ${S3_CERTFLAG_URL} > /dev/null 2>&1;echo $?)"

        echo "MASTERKEY: ${MASTER_KEY_FILE_NAME}"
        echo "H2_DATABASE: ${H2_DATABASE_FILENAME}"
        echo "CERTFLAG: ${CERTFLAG_FILENAME}"
        
        if test "${MASTER_KEY_FILE_NAME}" = "0" && test "${H2_DATABASE_FILENAME}" = "0" && test "${CERTFLAG_FILENAME}" = "0"; then
            echo "PingAccess admin configuration is complete, begin adding engine"
            break
        else
            echo "Adding Engine: Waiting for admin initial configuration"
            sleep 10
        fi
    done

    while true; do
        curl -ss --silent -o /dev/null -k https://${K8S_SERVICE_NAME_PINGACCESS_ADMIN}:9090/pa/heartbeat.ping
        if ! test $? -eq 0 ; then
            echo "Adding Engine: Server not started, waiting.."
            sleep 3
        else
            echo "PA started, begin adding engine"
            break
        fi
    done
}

########################################################################################################################
# Function to install AWS command line tools
#
# Arguments
#   N/A
########################################################################################################################
function installTools()
{
   if test -z "$(which aws)"; then
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

function initializeS3Configuration()
{
    unset BUCKET_URL_NO_PROTOCOL
    unset DIRECTORY_NAME
    unset TARGET_URL
    unset S3_MASTER_KEY_URL
    unset S3_H2_DATABASE_URL
    unset S3_CERTFLAG_URL

    # Install AWS CLI if the upload location is S3
    if test "${BACKUP_URL#s3}" == "${BACKUP_URL}"; then
        echo "Upload location is not S3"
        exit 1
    else
        installTools
    fi

    # Allow overriding the backup URL with an arg
    test ! -z "${1}" && BACKUP_URL="${1}"

    export BUCKET_URL_NO_PROTOCOL=${BACKUP_URL#s3://}
    export DIRECTORY_NAME=$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')

    if test "${BACKUP_URL}" == */pingaccess; then
        export TARGET_URL="${BACKUP_URL}"
    else
        export TARGET_URL="${BACKUP_URL}/${DIRECTORY_NAME}"
    fi

    export S3_MASTER_KEY_URL="${TARGET_URL}/pa.jwk"
    export S3_H2_DATABASE_URL="${TARGET_URL}/PingAccess.mv.db"
    export S3_CERTFLAG_URL="${TARGET_URL}/pingaccess_cert_complete_flag"
}