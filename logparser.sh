#!/bin/bash
# Get counts of time critical DB calls in UC4 for todays date.
# Useful to get trends of performance moving forward

logPath="/borisn12ap/ae11/AutomationEngine/temp"
todayDate=${1:-$(date +%Y%m%d)}
#todayLogs=$(find ${logPath} -name 'WPsrv_log*.txt' -type f -o -name 'CPsrv_log*.txt' -type f)
#better than above find of log files
todayLogs=$(find /borisn12ap/ae11/AutomationEngine/temp -regex ".*/WPsrv_log_[0-9][0-9][0-9]_[0-9][0-9].txt" -type f -o -regex ".*/CPsrv_log_[0-9][0-9][0-9]_[0-9][0-9].txt" -type f)
dayFile="/tmp/timecriticalday.csv"
tmpReport="/tmp/timecriticalreport.tmp"
reportFile="/tmp/timecriticalreport.csv"

#this should all be properly indented
echo ${todayDate} >> ${dayFile}
for i in "${todayLogs}";
do
for j in `seq 0 9`;
do
printf "\n"
echo "For interval between 0${j}:00 to 0${j}:59"
grepfoo=$(grep "${todayDate}/0${j}.*===> Time critical DB call" ${i} | wc -l | tee -a ${dayFile});
if [ "${grepfoo}" -gt 2000 ]; then
  echo "${grepfoo}"
  grep -A1 "${todayDate}/0${j}.*===> Time critical DB call" ${i} | grep -o "===>.*" | grep -Eo 'INSERT INTO \w+|UPDATE \w+|DELETE FROM \w+|SELECT.*FROM \w+' | sort | uniq -c | sort -nr | head -n 5 | sed 's/SELECT.*FROM/SELECT FROM/'
else
  echo ${grepfoo}
fi

done;
for k in `seq 10 23`;
do
printf "\n"
echo "For interval between ${k}:00 to ${k}:59"
grepfoo2=$(grep "${todayDate}/${k}.*===> Time critical DB call" ${i} | wc -l | tee -a ${dayFile});
if [ "${grepfoo2}" -gt 2000 ]; then
  echo ${grepfoo2}
  grep -A1 "${todayDate}/${k}.*===> Time critical DB call" ${i} | grep -o "===>.*" | grep -Eo 'INSERT INTO \w+|UPDATE \w+|DELETE FROM \w+|SELECT.*FROM \w+' | sort | uniq -c | sort -nr | head -n 5 | sed 's/SELECT.*FROM/SELECT FROM/'
else
  echo "${grepfoo2}"
fi
done;
printf "\n"
echo "Total time critical calls number for ${todayDate} is:"
grep "${todayDate}.*===> Time critical DB call" ${i} | wc -l | tee -a ${dayFile};
done;

dayFileSize=$(cat ${dayFile} | wc -l)

if [ "${dayFileSize}" -eq 26 ]; then
  /bin/awk '{ printf( "%s,", $1 ); } END { printf( "\n" ); }' ${dayFile} >> ${reportFile}
  > ${dayFile}
  sort -u -t, -k1,1 ${reportFile} > ${tmpReport} && cp ${tmpReport} ${reportFile}
  > ${tmpReport}
else
  > ${dayFile}
fi
