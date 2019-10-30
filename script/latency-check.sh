#!/bin/bash
logs=`ls -tr $2*`
for log in $logs
do
  $HOME/projects/SawMill/script/findtx.sh $log $1 &
done
wait
echo -n > latency-check.log.json
for log in $logs
do
  cat findtx-$log.json >> latency-check.log.json  
done
