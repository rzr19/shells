#/bin/bash
#
# READ-NG infrastructure components availability checker
#

function get_stage() {
  if [ -d '/appl/tomcat/apps/ap' ]; then
    read_stage="ap"
    read_sc_ci="P-11"
    read_nfs_stage="1835-read_p"
    rvs_linux_stage="1.2.3.3"
  elif [ -d '/appl/tomcat/apps/aq' ]; then
    read_stage="aq"
    read_sc_ci="Q-11"
    read_nfs_stage="1835-read_qs"
    rvs_linux_stage="1.2.3.4"
  else
    echo "Unknown stage. This should not be used outside of READ Q or READ P."
  fi
}

get_stage

alert_inbox="email@domain.com"

#useful environment variables
oracle_driver="ojdbc-8-12.2.0.1.jar"
jdbc_driver="jdbc2csv-2.1.jar"
java_home="/appl/tomcat/java/jdk1.8.0_251/bin"

scripts_home="/appl/tomcat/apps/${read_stage}/read/tomcat/scripts"
catalina_context_conf="/appl/tomcat/apps/${read_stage}/read/tomcat/conf/Catalina/localhost/context.xml.default"
catalina_home="/appl/tomcat/apps/${read_stage}/read/tomcat"

#all remote oracle dbs + 1 for READ_GUI check.
#If READ_GUI is unavailable all the other schemas are also unavailable.
#jdbc/read/etl/hls_vw doesn't work because the current password contains " and @ in it
list_of_dbs=('jdbc/read/etl/read_gui') # to add 'jdbc/read/etl/hls_audi' 'jdbc/read/etl/hls_poznan' 'jdbc/read/etl/hls_vw'

infra_components=('nfs' 'oracle' 'tomcat' 'rvs') #should also add F5 checks somehow

## helper functions for oracle ##
function get_db_username() {
  db_to_check=$1
  conf_file=$2
  db_username_raw=$(/bin/grep "${db_to_check}" ${conf_file} | grep -oP '(?<=username=").*?(?=")')
  db_username=$(echo ${db_username_raw} | awk '{print tolower($0)}')
}

function get_db_secret() {
  db_to_check=$1
  conf_file=$2
  db_secret=$(/bin/grep "${db_to_check}" ${conf_file} | grep -oP '(?<=password=").*?(?=")' | sed 's/\&quot\;/\"/')
}

function get_db_conn_string() {
  db_to_check=$1
  conf_file=$2
  db_conn_string=$(/bin/grep "${db_to_check}" ${conf_file} | grep -oP '(?<=url=").*?(?=")' | sed 's/.*@\/\///')
}
## helper functions for oracle ##

#This func is needed so that we have some persistent memory store for previous sent emails.
#There's no need for more than 1 alert if a component is down. We'll keep this tracking with 0 or 1 values in these files.
function email_spam_check_monitor_file() {
  component=$1
  if [ ! -f "$scripts_home"/check_"${component}"_spam_email.txt ]; then
    echo "The monitor file for READ-ng ${i} Infrastucture monitoring does not exist. Creating it."
    echo "0" > ${scripts_home}/check_"${component}"_spam_email.txt
  else
    echo "The monitor file for READ-ng ${component} Infrastructure monitoring exists."
  fi
}

#Finally, we're ready to do non-redundant email alerting.

# Common Body for email variable:
body_shortcut="Email."

nfs_shortcut="AUTOMATIC ALERT: The READ-NG ${read_sc_ci} NFS mount point /nfs/${read_nfs_stage} is not available."
tomcat_shortcut="AUTOMATIC ALERT: The READ-NG ${read_sc_ci} Tomcat instance is not running."
oracle_shortcut="AUTOMATIC ALERT: The READ-NG ${read_sc_ci} Oracle backend ${db_conn_string} is not available."
rvs_shortcut="AUTOMATIC ALERT: The READ-NG ${read_sc_ci} RVS station ${rvs_linux_stage} is not available."


function email_alert() {
  type_of_alert=$1
  case ${type_of_alert} in
    nfs)
      previous_alert_check_nfs=$(cat ${scripts_home}/check_"${type_of_alert}"_spam_email.txt)
      if [[ ${previous_alert_check}_nfs -eq 0 ]]; then
        echo "The READ-NG ${read_sc_ci} NFS mount point /nfs/${read_nfs_stage} ${body_shortcut}" | mail -s "${nfs_shortcut}" ${alert_inbox}
        echo "1" > ${scripts_home}/check_nfs_spam_email.txt
      else
        echo "The READ-NG ${read_sc_ci} NFS mount point /nfs/${read_nfs_stage} is not available. Already sent alert for it. Exiting."
      fi
      ;;
    tomcat)
      previous_alert_check_tomcat=$(cat ${scripts_home}/check_"${type_of_alert}"_spam_email.txt)
      if [[ ${previous_alert_check_tomcat} -eq 0 ]]; then
        echo "The READ-NG ${read_sc_ci} Tomcat instance ${body_shortcut}" | mail -s "${tomcat_shortcut}" ${alert_inbox}
        echo "1" > ${scripts_home}/check_tomcat_spam_email.txt
      else
        echo "The READ-NG ${read_sc_ci} Tomcat instance is not running. Already sent alert for it. Exiting."
      fi
      ;;
    oracle)
      previous_alert_check_oracle=$(cat ${scripts_home}/check_"${type_of_alert}"_spam_email.txt)
      if [[ ${previous_alert_check_oracle} -eq 0 ]]; then
        echo "The READ-NG ${read_sc_ci} Oracle backend ${db_conn_string} ${body_shortcut}" | mail -s "${oracle_shortcut}" ${alert_inbox}
        echo "1" > ${scripts_home}/check_oracle_spam_email.txt
      else
        echo "The READ-NG ${read_sc_ci} Oracle backend ${db_conn_string} is not available. Already sent alert for it. Exiting."
      fi
      ;;
    rvs)
      previous_alert_check_rvs=$(cat ${scripts_home}/check_"${type_of_alert}"_spam_email.txt)
      if [[ ${previous_alert_check_rvs} -eq 0 ]]; then
        echo "The READ-NG ${read_sc_ci} RVS station ${read_rvs_stage} ${body_shortcut}" | mail -s "${rvs_shortcut}" ${alert_inbox}
        echo "1" > ${scripts_home}/check_rvs_spam_email.txt
      else
        echo "The READ-NG ${read_sc_ci} RVS station ${rvs_linux_stage} is not available. Already sent alert for it. Exiting."
      fi
      ;;
    *)
      echo "Improper use of email_alert. Exiting."
      ;;
  esac
}

#Checks the READ NFS mount point availability.
function check_nfs() {
  email_spam_check_monitor_file nfs
  #to test, change filename
  if [ -f /nfs/${read_nfs_stage}/rvs/read_nfs_check ]; then
     echo "The NFS is available. Moving on."
     #resetting the email spam counter if the component is back up.
     echo "0" > ${scripts_home}/check_nfs_spam_email.txt
  else
     email_alert nfs
  fi
}

#Checks the READ RVS stations' network availability.
function check_rvs() {
  email_spam_check_monitor_file rvs
  rvs_stage=$1
  ping -q -c 5 ${rvs_stage} > /dev/null
  #to test, change 0 to 1
  if [[ $? -eq 0 ]]; then
    echo "The READ RVS station is available via TCP/IP. Moving on."
    echo "0" > ${scripts_home}/check_rvs_spam_email.txt
  else
    email_alert rvs
  fi
}

#Checks the Tomcat instance availability on the READ server itself
function check_tomcat() {
  email_spam_check_monitor_file tomcat
  ps -ef | grep -v 'grep' | grep -o $(cat ${catalina_home}/catalina.pid)
  #to test, change 0 to 1
  if [ ${PIPESTATUS[1]} -ne 0 ]; then
    email_alert tomcat
  else
    echo "The READ Tomcat instance is available. Moving on."
    echo "0" > ${scripts_home}/check_tomcat_spam_email.txt
  fi
}

#Checks the Oracle backend availability
function check_oracle() {
  for i in "${list_of_dbs[@]}"; do
    email_spam_check_monitor_file oracle
    get_db_username "${i}" ${catalina_context_conf}
    get_db_secret "${i}" ${catalina_context_conf}
    get_db_conn_string "${i}" ${catalina_context_conf}
    ${java_home}/java -cp ${catalina_home}/lib/${oracle_driver}:${scripts_home}/${jdbc_driver} com.azsoftware.jdbc2csv.Main \
    -u "jdbc:oracle:thin:${db_username}/\"${db_secret}\"@${db_conn_string}" "select * from user_users" | grep -i ${db_username_raw}
    #to test, change 0 to 1
    if [ ${PIPESTATUS[1]} -ne 0 ]; then
      email_alert oracle
    else
      echo "0" > ${scripts_home}/check_oracle_spam_email.txt
    fi
  done
}

check_nfs
check_rvs ${rvs_linux_stage}
check_tomcat
check_oracle
