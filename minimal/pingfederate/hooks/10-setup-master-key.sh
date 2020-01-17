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
   # Ensure Java home is set
   #
   if [ -z "${JAVA_HOME}" ]; then
      export JAVA_HOME=/usr/lib/jvm/default-jvm/jre/
   fi   
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
# Setup S3 bucket path components 
#
directory="$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')"
target="${BACKUP_URL}/${directory}"
bucket="${BACKUP_URL#s3://}"
masterKey="${BACKUP_URL}/${directory}/pf.jwk"

#
# Install AWS tools
#
installTools 

#
# If the Pingfederate folder does not exist in the s3 bucket, create it
# 
if [ "$(aws s3 ls ${BACKUP_URL} > /dev/null 2>&1;echo $?)" = "1" ]; then
   aws s3api put-object --bucket "${bucket}" --key "${directory}/"
fi

#
# We may already have a master key on disk if one was supplied through a secret or the 'in'
# volume. If that is the case we will use that key during obfuscation. If one does not 
# exist we check to see if one was previously uploaded to s3
#
if ! [ -f ../server/default/data/pf.jwk ]; then
   echo "No local master key found check s3 for a pre-existing key"
   result="$(aws s3 ls ${masterKey} > /dev/null 2>&1;echo $?)"
   if [ "${result}" = "0" ]; then
      echo "A master key does exist on S3 attempt to retrieve it"
      if [ "$(aws s3 cp "${masterKey}" ../server/default/data/pf.jwk > /dev/null 2>&1;echo $?)" != "0" ]; then
         echo_red "Retrieval was unsuccessful - crash the container to prevent overwiting the master key"
         exit 1
      else
         echo "Pre-existing master key found - using it"
         obfuscatePassword
      fi
   elif [ "${result}" != "1" ]; then
      echo_red "Unexpected error accessing S3 - crash the container to prevent overwiting the master key if it exists"
      exit 1
   else
      echo "No pre-existing master key found - obfuscate will create one which we will upload"
      obfuscatePassword
      aws s3 cp ../server/default/data/pf.jwk ${target}/pf.jwk
   fi 
else
   echo "A pre-existing master key was found on disk - using it"
   obfuscatePassword
fi
cd "${currentDir}"

