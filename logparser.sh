
#!/bin/bash
# Get counts of time critical DB calls in UC4 for $today
# Useful to get trends of performance moving forward

logPath="/borisn12ap/ae11/AutomationEngine/temp"
todayDate=${1:-$(date +%Y%m%d)}
todayLogs=$(find ${logPath} -name 'WPsrv_log*.txt' -type f -ctime -1 -o -name 'CPsrv_log*.txt' -type f -ctime -1)

for i in "${todayLogs}";
do
echo "Total time critical calls number for ${todayDate} is:"
grep "${todayDate}.*===> Time critical DB call" ${i} | wc -l;
for j in `seq 0 9`;
do
echo "For interval between 0${j}:00 to 0${j}:59"
grep "${todayDate}/0${j}.*===> Time critical DB call" ${i} | wc -l;
done;
for k in `seq 10 23`;
do
echo "For interval between ${k}:00 to ${k}:59"
grep "${todayDate}/${k}.*===> Time critical DB call" ${i} | wc -l;
done;
done;
