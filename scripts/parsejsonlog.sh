#!/bin/bash
echo -n > $1.out
while read logentry
do
# echo $logentry | python -m json.tool >> $1.out
# $HOME/bin/jq `echo $logentry` >> $1.out
echo $logentry | $HOME/bin/jq '.' 
done < $1
