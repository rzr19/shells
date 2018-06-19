#!/bin/bash
#
# Original author rzr19
# Input a file with special characters and output a ascii file without anything special to it :(

badfile=$1
zpath=$2
goodfile=$3

if [ -z $zpath$badfile ]; then
  echo -e "ALERT: A HR file to convert was not available. Check $zpath."
  exit 99;
else
  cat $zpath$badfile | iconv -f iso-8859-1 -t ascii//TRANSLIT//IGNORE > $zpath$goodfile
fi
if [ -z $zpath$goodfile ]; then
  echo -e "ALERT: A HR file was not succesfully characters-converted. Check $zpath."
  exit 98;
else
  sleep 60
  rm -f $zpath$badfile
fi
