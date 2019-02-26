#!/bin/bash

ftpsap=/usr/users/ftp
inbox="example@domain.com"

if [ "$(whoami)" != user ]; then
  echo "This is only supposed to run under user. Exiting 99."
  exit 99
fi

function filein() {
  filein=($(find $ftpsap/Vendor/Inbound/examplefile.fil -type f -daystart -mtime +2))
  if [ ${#filein[@]} -ne 0 ]; then
    printf '%s\n' "Check the File Inbound scenario and trigger the transmission to pull the current file if current one is dated last week." "${filein[@]}" | mail -s "ALERT: Todays Vendor Inbound file examplefile.fil is not on $ftpsap/Vendor/Inbound" $inbox
#  else
#    echo -e "The File Inbound file /usr/users/ftpsap/Vendor/Inbound/examplefile.fil exists. You can ignore this message." | mail -s "IGNORE: The Empower Inbound file exists." $inbox
  fi
}

filein
