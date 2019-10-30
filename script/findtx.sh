#!/bin/bash
echo -n > findtx-$1.json
while IFS= read -r logentry
do
  elapsedtime=`echo $logentry | $HOME/bin/jq '.response.elapsedTime' | grep -v null`
  if [[ $elapsedtime -ge $2 ]]
  then
    echo $logentry >> findtx-$1.json
  fi
done < ./$1
