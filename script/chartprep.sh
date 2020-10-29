#!/bin/bash

# ldapheader=`head -1 ./tmp/allldapops.csv | cut -d"," -f1,5-`
# chartdata=`tail -n +2 ./tmp/allldapops.csv | cut -d"," -f1,5-`
#sed 's/^/[/' gc.log
#sed 's/^/[/; s/$/],/g' gc.log
filesize=$(wc -l <$1)
linecount=1
hbracket="["
tcbracket="],"
tbracket="]"
while read -r line; do
  if (($linecount == 1)); then
    headers=$(echo $line | cut -d"," -f5-)
    OLDIFS=$IFS
    IFS=","
    ha=($headers)
    totalheaders=${#ha[@]}
    ((totalheaders--))
    ((totalheaders--))
    echo "var opscolumns = [" >opscolumns.data
    echo "var etimescolumns = [" >etimescolumns.data
    echo "{type: 'number', label: 'clock', color: 'black', disabledColor: 'lightgray', visible: true}," >>opscolumns.data
    echo "{type: 'number', label: 'clock', color: 'black', disabledColor: 'lightgray', visible: true}," >>etimescolumns.data
    hc=0
    cc=0
    colors=(red gold magenta indigo slateblue green olive teal blue navy brown crimson darkred peru maroon cornflowerblue steelblue darkgreen purple orange firebrick salmon deeppink coral tomato violet lime darkcyan darkblue chocolate darkmagenta blueviolet)
    for header in $headers; do
      if (($hc % 2)); then
        echo -n "{type: 'number', label: '$header', color: '${colors[${cc}]}', disabledColor: 'lightgray', visible: true}" >>etimescolumns.data
        if (($hc < $totalheaders)); then
          echo "," >>etimescolumns.data
        else
          echo "];" >>etimescolumns.data
        fi
        ((cc++))
      else
        echo -n "{type: 'number', label: '$header', color: '${colors[${cc}]}', disabledColor: 'lightgray', visible: true}" >>opscolumns.data
        if (($hc < $totalheaders)); then
          echo "," >>opscolumns.data
        else
          echo "];" >>opscolumns.data
        fi
      fi
      ((hc++))
    done
    echo "function drawChart () {" >>etimescolumns.data
    echo "if (!opschart) {" >ops.data
    echo "ops = new google.visualization.DataTable();" >>ops.data
    echo "ops.addColumn('number','clock');" >>ops.data
    echo "if (!etimeschart) {" >etimes.data
    echo "etimes = new google.visualization.DataTable();" >>etimes.data
    echo "etimes.addColumn('number','clock');" >>etimes.data
    hc=0
    for header in $headers; do
      if (($hc % 2)); then
        echo "etimes.addColumn('number','$header');" >>etimes.data
        ((cc++))
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
    #    des=$(echo $line | cut -d"," -f5- | tr -s "," " ,")
    des=$(echo $line | cut -d"," -f5-)
    des="$des ,"
    #   echo "LINES = $line"
    #   echo "DES = $des"
    opvalues="$clock"
    etimevalues="$clock"
    IFS=','
    #    elementcount=$(echo $des | wc -w)
    #    echo $elementcount
    for de in $des; do
      #            for de in $(echo $des | sed "s/,/ /g"); do
      #      echo "DE = -$de-$vc-"
      if (($vc % 2)); then
        opvalues="$opvalues, $de"
      else
        etimevalues="$etimevalues, $de"
      fi
      ((vc++))
    done
    if (($linecount < $filesize)); then
      #      echo $opvalues | sed 's/^/[/; s/$/],/g' >>ops.data
      #      echo $etimevalues | sed 's/^/[/; s/$/],/g' >>etimes.data
      #      echo "$hbracket$opvalues$tcbracket" | tr -s "~" "0" >>ops.data
      #      echo "$hbracket$etimevalues$tcbracket" | tr -s "~" "0" >>etimes.data
      echo "$hbracket$opvalues$tcbracket" >>ops.data
      echo "$hbracket$etimevalues$tcbracket" >>etimes.data
    fi
    if (($linecount == $filesize)); then
      #      echo "$hbracket$opvalues$tbracket" | tr -s "~" "0" >>ops.data
      #      echo "$hbracket$etimevalues$tbracket" | tr -s "~" "0" >>etimes.data
      echo "$hbracket$opvalues$tbracket" >>ops.data
      echo "$hbracket$etimevalues$tbracket" >>etimes.data
      #      echo $opvalues | sed 's/^/[/; s/$/]/g' >>ops.data
      #      echo $etimevalues | sed 's/^/[/; s/$/]/g' >>etimes.data
    fi
    IFS=$OLDIFS
  fi
  ((linecount++))
done <$1
echo "], false);
      opsdataView = new google.visualization.DataView(ops);
                opschart = new google.visualization.LineChart(document.getElementById('opschart'));
                google.visualization.events.addListener(opschart, 'click', function (target) {
                    if (target.targetID.match(/^legendentry#\d+$/)) {
                        var index = parseInt(target.targetID.slice(12)) + 1;
                        opscolumns[index].visible = !opscolumns[index].visible;
                        etimescolumns[index].visible = !etimescolumns[index].visible;
                        drawChart();
                    }
                });
            }" >>ops.data
echo "], false);
               etimesdataView = new google.visualization.DataView(etimes);
                etimeschart = new google.visualization.LineChart(document.getElementById('etimeschart'));
                google.visualization.events.addListener(etimeschart, 'click', function (target) {
                    if (target.targetID.match(/^legendentry#\d+$/)) {
                        var index = parseInt(target.targetID.slice(12)) + 1;
                        opscolumns[index].visible = !opscolumns[index].visible;
                        etimescolumns[index].visible = !etimescolumns[index].visible;
                        drawChart();
                    }
                });
            }" >>etimes.data
