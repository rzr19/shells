#!/bin/bash

# Get stage function:
function get_stage() {
  app_rhel7=$(hostname)
  if [ ${app_rhel7} = "host1" ]; then
    read_nfs_stage="1835-read_p"
    stage="ap"
  elif [ ${app_rhel7} = "host2" ]; then
    read_nfs_stage="1835-read_qs"
    stage="aq"
  else
    echo "Unknown stage. This should not be used outside of App1 or App2."
  fi
}

get_stage

#env paths
scripts_home="/home/load/scripts"
start_zsm_ldb_home="${scripts_home}/read_start_zsm_ldb"
rvs_zsm_home="/nfs/${read_nfs_stage}/rvs/receive/zsm"

# REST curl Links:
etl_root_url="https://localhost:8448/read-etl"
zsm1_info_link="${etl_root_url}/infoZsm"
ldb1_info_link="${etl_root_url}/infoLdb"
zsm1_start_link="${etl_root_url}/startZsm"
ldb1_start_link="${etl_root_url}/startLdb"
zsm2_info_link="${etl_root_url}/infoCompanyZsmStorage"
ldb2_info_link="${etl_root_url}/infoCompanyLdbStorage"
zsm2_start_link="${etl_root_url}/startCompanyZsmStorage"
ldb2_start_link="${etl_root_url}/startCompanyLdbStorage"
zsm_ldb_start_gui_link="${etl_root_url}/startCompanyGui"
zsm_ldb_info_gui_link="${etl_root_url}/infoCompanyGui"

function print_new_line() {
  echo "\n" >> ${status_file}
}

function start_zsm1_and_zsm2() {
  latest_zsm_file=$(find ${rvs_zsm_home} -type f -name '*LEMI*' -print | sort | tail -n1) 
  mv ${latest_zsm_file} ${rvs_zsm_home}/zsm_input
  curl -k ${zsm1_start_link}
  sleep 100
  curl -s -k ${zsm1_info_link} | grep 'COMPLETED'
  if [ $? -eq 0 ]; then
    curl -k ${zsm2_start_link}
    sleep 100
  else
    python ${scripts_home}/spamcannon/spam_cannon.py info_zsm1 noattach
  fi
}

function start_ldb1_and_ldb2() {
  curl -k ${ldb1_start_link}
  sleep 1500
  curl -s -k ${ldb1_info_link} | grep 'COMPLETED'
  if [ $? -eq 0 ]; then
    curl -k ${ldb2_start_link}
    sleep 500
  else
    python ${scripts_home}/spamcannon/spam_cannon.py info_ldb1 noattach
  fi
}

function start_company_gui() {
  ##if both ldb2_info_link and zsm2_info_link are completed then run /startCompanyGui
  info_zsm2=$(curl -k ${zsm2_info_link} | grep 'COMPLETED')
  info_ldb2=$(curl -k ${ldb2_info_link} | grep 'COMPLETED')
  if [[ -n ${info_zsm2} && -n ${info_ldb2} ]]; then
    curl -k ${zsm_ldb_start_gui_link}    
    sleep 600
    curl -s -k ${zsm_ldb_info_gui_link} | grep 'COMPLETED'
    if [ $? -ne 0 ]; then
      python ${scripts_home}/spamcannon/spam_cannon.py info_company2 noattach
    else 
      curl -k ${etl_root_url}/infoAll >> ${start_zsm_ldb_home}/zsm_ldb_status.txt      
      python ${scripts_home}/spamcannon/spam_cannon.py info_company3 attach ${start_zsm_ldb_home}/zsm_ldb_status.txt
    fi
  else
    python ${scripts_home}/spamcannon/spam_cannon.py info_company1 noattach
  fi
}

start_zsm1_and_zsm2 &
start_ldb1_and_ldb2 &

wait < <(jobs -p)
start_company_gui
rm -f ${start_zsm_ldb_home}/zsm_ldb_status.txt
