#!/bin/bash

#original author vgheorgh 11.2018

#used to HTTPS PUT from PI SFTP Adapter to S3
#see scenario AD_Village in Integration Builder for usage
#uses either the PI sec store for the AWS key pair in production OR /home/user/s3.apikey for development
# /usr/sap/${piSystem}/J21/sec/s3.apikey
# [PI_Scenario]
# AccessKey=xxxxx
# SecretKey=xxxxx

#To debug use below:
#/bin/bash -x /home/hrhrproc/sap-xi-s3-integration.sh /tmp file.csv.gpg file.csv.gpg.log dev (or prd) S3Bucket
#writes debug logs depending on $3

filePath=$1
fileName=$2
logFileName=$3
env=$4
S3Bucket=$5

piSystem=`find /usr/sap -maxdepth 1 | grep '/usr/sap/[D,A,P]30' | tr -d '/usr/sap/'` #which PI system is this running on?
devSecStore="/home/user/villages3.apikey"
prdSecStore="/usr/sap/${piSystem}/J21/sec/villages3.apikey"

#Sanity checks for dev and prd.

if [ ${env} == 'prd' ]; then
  if [[ -f ${prdSecStore} && -r ${prdSecStore} ]]; then
    #We assume at this point that the sec store file has proper syntax
    AccessKey=`cat ${prdSecStore} | /usr/bin/base64 -d | grep -oP 'S3AccessKey="\K[^"]+' | /usr/bin/base64 -d`
    SecretKey=`cat ${prdSecStore} | /usr/bin/base64 -d | grep -oP 'S3SecretKey="\K[^"]+' | /usr/bin/base64 -d`
  else
    echo $(date -u) "The secure store file ${prdSecStore} is not available to `whoami` on ${piSystem}. Exiting 89." >> ${filePath}/${logFileName}
    exit 89
  fi
elif [ ${env} == 'dev' ]; then
  if [[ -f ${devSecStore} && -r ${devSecStore} ]]; then
    #We assume at this point that the sec store file has proper syntax
    AccessKey=`cat ${devSecStore} | /usr/bin/base64 -d | grep -oP 'S3AccessKey="\K[^"]+' | /usr/bin/base64 -d`
    SecretKey=`cat ${devSecStore} | /usr/bin/base64 -d | grep -oP 'S3SecretKey="\K[^"]+' | /usr/bin/base64 -d`
  else
    echo $(date -u) "The secure store file ${devSecStore} is not available to `whoami` on ${piSystem}. Exiting 88." >> ${filePath}/${logFileName}
    exit 88
  fi
else
  echo $(date -u) "The 4th parameter of villages3.sh must be either dev or prd. Exiting 87." >> ${filePath}/${logFileName}
  exit 87
fi

RFCDate=`date -R`
S3Path="/${S3Bucket}/${fileName}"

ContentType="application/octet-stream"
StringToSign="PUT\\n\\n${ContentType}\\n${RFCDate}\\n${S3Path}"
SignString=`echo -en ${StringToSign} | /usr/bin/openssl sha1 -hmac ${SecretKey} -binary | /usr/bin/base64`

while true;
do
  /bin/ping -c 1 "${S3Bucket}.s3.amazonaws.com" &> /dev/null
  #is sc-pull responsive?
  if [ $? -eq 0 ]; then
  #is the file really there?
  if [[ "${fileName}" == "file.csv.gpg" && -f "${filePath}/${fileName}" ]]; then
    # build the aws s3 cp HTTPS PUT
    /usr/bin/curl -X PUT -T "${filePath}/${fileName}" \
    -H "Host: ${S3Bucket}.s3.amazonaws.com" \
    -H "Date: ${RFCDate}" \
    -H "Content-Type: ${ContentType}" \
    -H "Authorization: AWS ${AccessKey}:${SignString}" \
    http://${S3Bucket}.s3.amazonaws.com/${fileName}
    # write a few log files entries for debugging
    echo $(date -u) "Sent file ${fileName} to '${S3Bucket}.s3.amazonaws.com/' via ${piSystem}. Exiting 0." >> ${filePath}/${logFileName}
    rm -f ${filePath}/${fileName}
    exit 0
  else
    echo $(date -u) "No ${filePath}/${fileName} file is available on ${piSystem}. Exiting 99." >> ${filePath}/${logFileName}
    exit 99
  fi
else
  echo $(date -u) "'${S3Bucket}.s3.amazonaws.com' is unreachable via ${piSystem}. Exiting 98." >> ${filePath}/${logFileName}
  exit 98
fi
done
