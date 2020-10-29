#!/bin/bash
date
files="./access.audit.json*"
ops="DELETE GET PATCH POST PUT"
status="SUCCESSFUL FAILED"
total=0
for op in $ops; do
    for stat in $status; do
        x=$(grep $op $files | grep $stat | wc -l | tr -d '\n')
        #  x=$(grep $op $files  | wc -l | tr -d '\n')
        printf "%-22s %'.f\n" "$op-$stat =" "$x"
        total=$((total + x))
    done
done
printf "%-22s %'.f\n" "total operations =" "$total"
