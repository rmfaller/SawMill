#!/bin/bash

# ldapheader=`head -1 ./tmp/allldapops.csv | cut -d"," -f1,5-`
# chartdata=`tail -n +2 ./tmp/allldapops.csv | cut -d"," -f1,5-`
#sed 's/^/[/' gc.log
#sed 's/^/[/; s/$/],/g' gc.log
filesize=$(wc -l <$1)
linecount=1
while read -r line; do
  if (($linecount == 1)); then
    headers=$(echo $line | cut -d"," -f5-)
    OLDIFS=$IFS
    IFS=","
    echo "var ops = new google.visualization.DataTable();" >ops.data
    echo "ops.addColumn('number','clock');" >>ops.data
    echo "var etimes = new google.visualization.DataTable();" >etimes.data
    echo "etimes.addColumn('number','clock');" >>etimes.data
    hc=0
    for header in $headers; do
      if (($hc % 2)); then
        echo "etimes.addColumn('number','$header');" >>etimes.data
      else
        echo "ops.addColumn('number','$header');" >>ops.data
      fi
      ((hc++))
    done
    echo "ops.addRows([" >>ops.data
    echo "etimes.addRows([" >>etimes.data
    IFS=$OLDIFS
  else
    OLDIFS=$IFS
    IFS=" "
    vc=1
    clock=$(echo $line | cut -d"," -f1)
    des=$(echo $line | cut -d"," -f5- | tr -s "," " ")
    opvalues=$clock
    etimevalues=$clock
    for de in $des; do
      if (($vc % 2)); then
        opvalues="$opvalues, $de"
      else
        etimevalues="$etimevalues, $de"
      fi
      ((vc++))
    done
    IFS=$OLDIFS
    if (($linecount < $filesize)); then
      echo $opvalues | sed 's/^/[/; s/$/],/g' >>ops.data
      echo $etimevalues | sed 's/^/[/; s/$/],/g' >>etimes.data
    fi
    if (($linecount == $filesize)); then
      echo $opvalues | sed 's/^/[/; s/$/]/g' >>ops.data
      echo $etimevalues | sed 's/^/[/; s/$/]/g' >>etimes.data
    fi
  fi
  ((linecount++))
done <$1
echo "]);" >>ops.data
echo "]);" >>etimes.data
