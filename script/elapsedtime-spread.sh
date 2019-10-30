#!/bin/bash
#
# DISCLAIMER: The sample code described herein is provided on an "as is" basis, 
# without warranty of any kind, to the fullest extent permitted by law. 
# ForgeRock does not warrant or guarantee the individual success developers may 
# have in implementing the sample code on their development platforms or 
# in production configurations.
# 
# ForgeRock does not warrant, guarantee or make any representations regarding the 
# use, results of use, accuracy, timeliness or completeness of any data or 
# information relating to the sample code. ForgeRock disclaims all warranties, 
# expressed or implied, and in particular, disclaims all warranties of merchantability, 
# and warranties related to the code, or any service or software related thereto.
#
# ForgeRock shall not be liable for any direct, indirect or consequential damages or 
# costs of any type arising out of any action taken by you or others related to the sample code.
#

logs=`ls -t $1*`
for log in $logs
do

# Uncomment the following line for analyzing DS-based stores i.e. User store, CTS, config store
# cat $log | $HOME/bin/jq '.response.elapsedTime, .request.operation, .timestamp, ._id, .transactionId' | paste -d " " - - - - - | grep -v null | awk '$1>2000' | tr -s " " "," > et-$log.txt

# Uncomment the following line for analyzing AM
# cat $log | $HOME/bin/jq '.response.elapsedTime, .http.request.method, .timestamp, ._id, .transactionId' | paste -d " " - - - - - | grep -v null | awk '$1>2000' | tr -s " " ","  > et-$log.txt

done
wait
echo -n > ./all-et.txt
for log in $logs
do
  cat ./et-$log.txt >> ./all-et.txt
done
