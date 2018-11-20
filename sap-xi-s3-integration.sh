#!/bin/bash

#original author vgheorgh 11.2018
#used to HTTPS PUT from PI SFTP Adapter to S3 via "Run operating system cmd after message processing".
#pass file to PI Linux OS by SFTP and pickup with this script to move to S3
#/bin/bash -x /home/user/s3.sh /tmp s3.csv.gpg s3.csv.gpg.log ${dev || prd}
#uses either the PI sec store for the AWS key pair in production OR /home/user/s3.conf for development
# /usr/sap/P00/J21/sec/s3.conf
# [AD_Village]
# AccessKey=xxxxx
# SecretKey=xxxxx
# AWSHostName=xxxxx
# [AD_Village]
#writes debug logs in hostname:/tmp/s3.csv.gpg.log depending on $3

filePath=$1
fileName=$2
logFileName=$3
env=$4

devSecStore="/home/user/s3.conf"
prdSecStore="/usr/sap/P00/J21/sec/s3.conf"

#Sanity checks for dev and prd.

if [ ${env} == 'prd' ]; then
  if [[ -f ${prdSecStore} && -r ${prdSecStore} ]]; then
    #We assume at this point that the sec store file has proper syntax
    AccessKey=`cat ${prdSecStore} | grep -oP 'S3AccessKey="\K[^"]+' | /usr/bin/base64 -d`
    SecretKey=`cat ${prdSecStore} | grep -oP 'S3SecretKey="\K[^"]+' | /usr/bin/base64 -d`
    S3Bucket=`grep -oP 'S3HostName="\K[^"]+' ${prdSecStore}`
  else
    echo $(date -u) "The secure store file ${prdSecStore} is not available to `whoami`. Exiting 89." >> ${filePath}/${logFileName}
    exit 89
  fi
elif [ ${env} == 'dev' ]; then
  if [[ -f ${devSecStore} && -r ${devSecStore} ]]; then
    #We assume at this point that the sec store file has proper syntax
    AccessKey=`cat ${devSecStore} | grep -oP 'S3AccessKey="\K[^"]+' | /usr/bin/base64 -d`
    SecretKey=`cat ${devSecStore} | grep -oP 'S3SecretKey="\K[^"]+' | /usr/bin/base64 -d`
    S3Bucket=`grep -oP 'S3HostName="\K[^"]+' ${devSecStore}`
  else
    echo $(date -u) "The secure store file ${devSecStore} is not available to `whoami`. Exiting 88." >> ${filePath}/${logFileName}
    exit 88
  fi
else
  echo $(date -u) "The 4th parameter of s3.sh must be either dev or prd. Exiting 87." >> ${filePath}/${logFileName}
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
  if [[ "${fileName}" == "Village.csv.gpg" && -f "${filePath}/${fileName}" ]]; then
    # build the aws s3 cp HTTPS PUT
    /usr/bin/curl -X PUT -T "${filePath}/${fileName}" \
    -H "Host: ${S3Bucket}.s3.amazonaws.com" \
    -H "Date: ${RFCDate}" \
    -H "Content-Type: ${ContentType}" \
    -H "Authorization: AWS ${AccessKey}:${SignString}" \
    http://${S3Bucket}.s3.amazonaws.com/${fileName}
    # write a few log files entries for debugging
    echo $(date -u) "Sent file ${fileName} to '${S3Bucket}.s3.amazonaws.com/'. Exiting 0." >> ${filePath}/${logFileName}
    rm -f ${filePath}/${fileName}
    exit 0
  else
    echo $(date -u) "No ${filePath}/${fileName} file is available. Exiting 99." >> ${filePath}/${logFileName}
    exit 99
  fi
else
  echo $(date -u) "'${S3Bucket}.s3.amazonaws.com' is unreachable via PI. Exiting 98." >> ${filePath}/${logFileName}
  exit 98
fi
done
