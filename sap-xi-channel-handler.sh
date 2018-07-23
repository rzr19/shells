#!/bin/bash

# Original author rzr19
# Used to call from SAP SM37 batches the Process Orchestration 7.50 via ChannelAdminServlet for File Adapter / SFTP Adapter transfers.
# Prerequisite is a Z program that uses CALL SYSTEM or SXPG_COMMAND_EXECUTE to run OS tasks
#
# Configure it as step of jobs in dSeries/CPS/SM36 with ZUNIXCMD variant <NAME> so
# For Outbound use 4 parameters in 1 job step
# 1. /usr/users/ftpsaprh/scripts/xi_channel_handler.sh CC_SFTP_Scenario_Sender CC_SFTP_Scenario Receiver 100 HRE000
# For Inbound use 5 parameters in 2 job steps
# 1. /usr/users/ftpsaprh/scripts/xi_channel_handler.sh CC_SFTP_Scenario_Sender CC_SFTP_Scenario Receiver 100 HRE000 start
# 2. /usr/users/ftpsaprh/scripts/xi_channel_handler.sh CC_SFTP_Scenario_Sender CC_SFTP_Scenario Receiver 100 HRE000 stop

#Changelog
#05/04/2018 - added load balancing through PI message server, parsing of XML for only Channel/State, zcurl

channel1=$1
channel2=$2
naptime=$3
jobname=$4
action=$5
user='username'
token=`/bin/cat /home/user/xi_token`
inbox='email'
testhttp=`curl -s -o /dev/null --max-time 60 -w "%{http_code}" -L http://sapp30ci:8120/AdapterFramework/channelAdmin/ChannelAdmin.xsd`
url1="http://sappo.domain.net:8120/AdapterFramework/ChannelAdminServlet?party=*&service=*&channel=${channel1}&action"
url2="http://sappo.domain.net:8120/AdapterFramework/ChannelAdminServlet?party=*&service=*&channel=${channel2}&action"

if [ $# -ne 4 ] && [ $# -ne 5 ]; then #User input exception
  echo "Not enough parameters were provided to xi_channel_handler. Exiting..."
  exit 99
elif [[ "$testhttp" -lt "200" || "$testhttp" -ge "400" ]]; then #PI availability exception
  echo -e "PO is unreachable via HTTP for SAP job $jobname. Check $channel1 and $channel2." | mail -s "ALERT: The PO integration scenario was not started by $jobname" $inbox
  exit 98
fi

function zcurl() {
  zurl=$1
  zaction=$2
  /usr/bin/curl -s --location-trusted --user $user:$token "$zurl"="$zaction" | grep -E "<ChannelName>|<ActivationState>"
}

if [[ "$naptime" =~ ^-?[0-9]+$ ]]; then #User input exception at EOF
  if [[ $# -eq 5 ]]; then
    /usr/bin/curl -s --location-trusted --user $user:$token "$url1"=$action | grep "<AdminErrorInformation>" #Java stack exception in case of HTTP 200 response
    if [ $? -eq 0 ]; then
      echo -e "P30 channels are unreachable via HTTP for SAP job $jobname. Check $channel1 and $channel2 External Control." | mail -s "ALERT: The PO integration scenario was not started by $jobname" $inbox
      exit 97
    else
      zcurl $url1 $action
      zcurl $url2 $action
      sleep $naptime
      exit 96
    fi
  elif [[ $# -eq 4 ]]; then
    /usr/bin/curl -s --location-trusted --user $user:$token "$url1"=start | grep "<AdminErrorInformation>"
    if [ $? -eq 0 ]; then
      echo -e "P30 channels are unreachable via HTTP for SAP job $jobname. Check $channel1 and $channel2 External Control." | mail -s "ALERT: The PO integration scenario was not started by $jobname" $inbox
      exit 95
    else
      zcurl $url1 start
      zcurl $url2 start
      sleep $naptime
      zcurl $url1 stop
      zcurl $url2 stop
      exit 94
    fi
  fi
else
  echo "3rd parameter to xi_channel_handler.sh is not a number. Exiting..."
  exit 93
fi
