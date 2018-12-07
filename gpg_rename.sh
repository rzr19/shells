  #!/bin/bash

#rename ABAP generated programs to .gpg or .pgp for integration setups
#/bin/bash /usr/users/scripts/gpg_rename.sh /usr/users/secureftp/Vendor/Outbound .pgp 30

scenarioDirectory=$1
fileExtension=$2
sleepTime=$3

numberCheck='^[0-9]+$'
if ! [[ ${sleepTime} =~ ${numberCheck} ]]; then
  echo "Error: ${sleepTime} is not a number. Exiting 97."
  exit 97
else
  sleep ${sleepTime}
fi

if [ -d ${scenarioDirectory} ]; then
  if [[ "$fileExtension" == ".gpg" || "$fileExtension" == ".pgp" ]]; then
    for SAPfile in $(find ${scenarioDirectory} -type f -not -name "${fileExtension}");
    do mv ${SAPfile} ${SAPfile}${fileExtension} ;
    renamedFile="$(echo ${SAPfile} | cut -d"/" -f7)"
    echo "Rename ${renamedFile}"
    done
  else
    echo "Error: ${fileExtension} should be either .pgp or .gpg. Exiting 98."
    exit 98
  fi
else
  echo "Error: ${scenarioDirectory} does not exist. Exiting 99."
  exit 99
fi
