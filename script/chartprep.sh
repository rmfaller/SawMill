#!/bin/bash
LOCATION=$(echo $1 | sed -r "s/(.+)\/.+/\1/")
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
    echo "var opscolumns = [" >$LOCATION/opscolumns.data
    echo "var etimescolumns = [" >$LOCATION/etimescolumns.data
    echo "{type: 'number', label: 'clock', color: 'black', disabledColor: 'lightgray', visible: true}," >>$LOCATION/opscolumns.data
    echo "{type: 'number', label: 'clock', color: 'black', disabledColor: 'lightgray', visible: true}," >>$LOCATION/etimescolumns.data
    hc=0
    cc=0
    colors=(Blue Brown Cyan Green Gray Orange Pink Purple Red  \
CadetBlue Aqua GreenYellow DarkOrange LightPink Gold  \
SteelBlue Chartreuse Coral HotPink LightSalmon  \
LightSteelBlue NavajoWhite PaleTurquoise LawnGreen Silver Tomato DeepPink Plum Salmon  \
LightBlue Wheat Aquamarine Lime DarkGray OrangeRed PaleVioletRed Orchid DarkSalmon  \
PowderBlue BurlyWood Turquoise LimeGreen MediumVioletRed Violet LightCoral Moccasin  \
LightSkyBlue Tan MediumTurquoise PaleGreen LightSlateGray Fuchsia IndianRed PeachPuff  \
SkyBlue RosyBrown DarkTurquoise LightGreen SlateGray Magenta Crimson PaleGoldenRod  \
CornflowerBlue SandyBrown MediumSpringGreen DarkSlateGray MediumOrchid FireBrick Khaki  \
DeepSkyBlue GoldenRod SpringGreen Black DarkOrchid DarkRed DarkKhaki  \
DodgerBlue DarkGoldenRod MediumSeaGreen DarkViolet  \
RoyalBlue Peru SeaGreen BlueViolet  \
MediumBlue Chocolate ForestGreen DarkMagenta  \
DarkBlue Olive DarkGreen MediumPurple  \
Navy SaddleBrown YellowGreen MediumSlateBlue  \
MidnightBlue Sienna OliveDrab SlateBlue  \
Maroon DarkOliveGreen DarkSlateBlue  \
MediumAquaMarine DarkSeaGreen Indigo LightSeaGreen DarkCyan Teal \
Blue Brown Cyan Green Gray Orange Pink Purple Red  \
CadetBlue Aqua GreenYellow DarkOrange LightPink Gold  \
SteelBlue Chartreuse Coral HotPink LightSalmon  \
LightSteelBlue NavajoWhite PaleTurquoise LawnGreen Silver Tomato DeepPink Plum Salmon  \
LightBlue Wheat Aquamarine Lime DarkGray OrangeRed PaleVioletRed Orchid DarkSalmon  \
PowderBlue BurlyWood Turquoise LimeGreen MediumVioletRed Violet LightCoral Moccasin  \
LightSkyBlue Tan MediumTurquoise PaleGreen LightSlateGray Fuchsia IndianRed PeachPuff  \
SkyBlue RosyBrown DarkTurquoise LightGreen SlateGray Magenta Crimson PaleGoldenRod  \
CornflowerBlue SandyBrown MediumSpringGreen DarkSlateGray MediumOrchid FireBrick Khaki  \
DeepSkyBlue GoldenRod SpringGreen Black DarkOrchid DarkRed DarkKhaki  \
DodgerBlue DarkGoldenRod MediumSeaGreen DarkViolet  \
RoyalBlue Peru SeaGreen BlueViolet  \
MediumBlue Chocolate ForestGreen DarkMagenta  \
DarkBlue Olive DarkGreen MediumPurple  \
Navy SaddleBrown YellowGreen MediumSlateBlue  \
MidnightBlue Sienna OliveDrab SlateBlue  \
Maroon DarkOliveGreen DarkSlateBlue  \
MediumAquaMarine DarkSeaGreen Indigo LightSeaGreen DarkCyan Teal)

    for header in $headers; do
      if (($hc % 2)); then
        echo -n "{type: 'number', label: '$header', color: '${colors[${cc}]}', disabledColor: 'lightgray', visible: true}" >>$LOCATION/etimescolumns.data
        if (($hc < $totalheaders)); then
          echo "," >>$LOCATION/etimescolumns.data
        else
          echo "];" >>$LOCATION/etimescolumns.data
        fi
        ((cc++))
      else
        echo -n "{type: 'number', label: '$header', color: '${colors[${cc}]}', disabledColor: 'lightgray', visible: true}" >>$LOCATION/opscolumns.data
        if (($hc < $totalheaders)); then
          echo "," >>$LOCATION/opscolumns.data
        else
          echo "];" >>$LOCATION/opscolumns.data
        fi
      fi
      ((hc++))
    done
    echo "function drawChart () {" >>$LOCATION/etimescolumns.data
    echo "if (!opschart) {" >$LOCATION/ops.data
    echo "ops = new google.visualization.DataTable();" >>$LOCATION/ops.data
    echo "ops.addColumn('number','clock');" >>$LOCATION/ops.data
    echo "if (!etimeschart) {" >$LOCATION/etimes.data
    echo "etimes = new google.visualization.DataTable();" >>$LOCATION/etimes.data
    echo "etimes.addColumn('number','clock');" >>$LOCATION/etimes.data
    hc=0
    for header in $headers; do
      if (($hc % 2)); then
        echo "etimes.addColumn('number','$header');" >>$LOCATION/etimes.data
        ((cc++))
      else
        echo "ops.addColumn('number','$header');" >>$LOCATION/ops.data
      fi
      ((hc++))
    done
    echo "ops.addRows([" >>$LOCATION/ops.data
    echo "etimes.addRows([" >>$LOCATION/etimes.data
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
      #      echo $opvalues | sed 's/^/[/; s/$/],/g' >>$LOCATION/ops.data
      #      echo $etimevalues | sed 's/^/[/; s/$/],/g' >>$LOCATION/etimes.data
      #      echo "$hbracket$opvalues$tcbracket" | tr -s "~" "0" >>$LOCATION/ops.data
      #      echo "$hbracket$etimevalues$tcbracket" | tr -s "~" "0" >>$LOCATION/etimes.data
      echo "$hbracket$opvalues$tcbracket" >>$LOCATION/ops.data
      echo "$hbracket$etimevalues$tcbracket" >>$LOCATION/etimes.data
    fi
    if (($linecount == $filesize)); then
      #      echo "$hbracket$opvalues$tbracket" | tr -s "~" "0" >>$LOCATION/ops.data
      #      echo "$hbracket$etimevalues$tbracket" | tr -s "~" "0" >>$LOCATION/etimes.data
      echo "$hbracket$opvalues$tbracket" >>$LOCATION/ops.data
      echo "$hbracket$etimevalues$tbracket" >>$LOCATION/etimes.data
      #      echo $opvalues | sed 's/^/[/; s/$/]/g' >>$LOCATION/ops.data
      #      echo $etimevalues | sed 's/^/[/; s/$/]/g' >>$LOCATION/etimes.data
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
            }" >>$LOCATION/ops.data
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
            }" >>$LOCATION/etimes.data
