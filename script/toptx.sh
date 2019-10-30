#!/bin/bash
logs=`ls -t access.audit.json`
for log in $logs
do
  grep "\"method\":\"GET\"" $log | grep "/authn/oauth2/" | $HOME/bin/jq '.response.elapsedTime, ._id' | paste -d" " - - | grep -v null | awk '$1>300' | cut -d"\"" -f2  > ./topid-$log.txt & 
done
wait
for log in $logs
do
  echo -n > ./toptx-$log.json
  while read id
  do 
    echo "grepping for $id in $log"
    grep '\"_id\":\"$id\"' $log >> ./toptx-$log.json
  done < ./topid-$log.txt 
done
#wait

# echo -n > ./total-topop.txt
# for log in $logs
# do
  # cat ./opcount-$log >> ./total-opcount.txt
  # rm ./opcount-$log
# done
# cat ./total-opcount.txt | sort -n | uniq -c
