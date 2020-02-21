#!/bin/bash
reportfile=$1
list_of_numbers=()

for i in `grep "===> Time critical DB call" $1| awk -F ":" '{print $4}' | tr -d "'"`; do
  list_of_numbers+=( $i )
done

uniq_list_of_numbers=( `for j in ${list_of_numbers[@]}; do echo $j; done | sort -u` )

#not needed
maximum_number="${uniq_list_of_numbers[0]}"
for k in ${uniq_list_of_numbers[@]}; do
  (( k > $maximum_number )) && maximum_number=$k
done

uniq_list_of_numbers_sorted=( `for j in ${uniq_list_of_numbers[@]}; do echo $j; done | sort -n` )

for x in ${uniq_list_of_numbers_sorted[@]}; do

  echo "Top 10 operations that took ${x} seconds to complete:"
  cat ${reportfile} | grep -A1 "===> Time critical DB call.*OPC: 'EXEC' time: '${x}:" | grep -o "===>.*" | grep -Ei 'INSERT INTO \w+|UPDATE \w+|DELETE FROM \w+|SELECT.*FROM \w+' | sort | uniq -c | sort -nr | head -n 10
  printf "\n"

done;
