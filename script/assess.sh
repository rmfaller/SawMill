#!/bin/bash
# arg 1 = file system location to work in (i.e. unzip files, create poi, etc)
# arg 2 = full path on file system to zipped file
# arg 3 = source of logs files - Use one of the following: am, ds, cts, cfg, idm, idr, ig"
#   am  = AM JSON logs
#   ds  = DS (User store) JSON logs
#   cts = DS (CTS) JSON logs
#   cfg = DS (config store for AM) JSON logs
#   idm = IDM JSON logs
#   idr = DS (IDM repository) JSON logs
#   ig  = IG JSON logs
# arg 4 = if included must be the letter x to note that the zip file is a DS support extract.
# BOH="/blueox/forgerock/tomcat/webapps/BlueOx"
# BOH="/Users/rmfaller/projects/BlueOx/build/web"
BOH="/Users/robert.faller/projects"
# JQ="/usr/bin/jq"
JQ="/Users/robert.faller/bin/jq"
BIN="/usr/bin"
# $JAR="$BIN/jar"
JAR="jar"
SAWMILLHOME="$BOH/SawMill"
SCRIPTHOME="$SAWMILLHOME/script"
HTMLHOME="$SAWMILLHOME/html"
# SUBSCRIPTION="$BOH/build/web/uploads/$1"
SUBSCRIPTIONHOME=/Users/rmfaller
#SUBSCRIPTIONHOME=/Volumes/twoTBdrive
SUBSCRIPTION=$SUBSCRIPTIONHOME/sawmill/$1
FULLFILENAME=$2
SOURCETYPE=$3
ZIPTYPE=$4
ALLLOGS=true
LDAPCUT=1
HTTPCUT=1
FILENAME=${FULLFILENAME%.*}
FILENAMEONLY=${FILENAME##*/}
SERVICEBASE="/Users/rmfaller/projects/BlueOx/build/web"
WDIR=$(pwd)

cd $SUBSCRIPTION
mkdir $FILENAMEONLY
cd $FILENAMEONLY
$JAR -xf $2
mkdir tmp
mkdir report
chmod -R 700 *
$SCRIPTHOME/createpoi.sh $SUBSCRIPTION $FILENAMEONLY $3

# uploadtype=`cat metadata.json | jq -r '.info.uploadtype'`
echo "<html> <head> <title>BlueOx</title> </head> <body>" >./report/report.html
echo "<h2><b> <font face=\"Arial Unicode MS\"><font color=\"#3333ff\">BlueOx</font>" >>./report/report.html
echo "Report for Subscription = $SUBSCRIPTION and File = $FILENAMEONLY</font></b></h2>" >>./report/report.html

if [ "$ZIPTYPE" = "x" ]; then
  cd ./support-data/config
  $SCRIPTHOME/extractor.sh -r $FILENAMEONLY -h
  mv $FILENAMEONLY.html ../../report/.
  cd ../../
  echo "<hr size=\"2\" width=\"100%\"><font face=\"Arial Unicode MS\"><a href=./$FILENAMEONLY.html>Directory Server Extractor Report</a><br></font>" >>./report/report.html
fi
if $ALLLOGS; then
  rotatedldaplogs=$(find . -name "ldap-access.audit.json.*" -print | sort)
  ldaplogs="$(echo $rotatedldaplogs)  $(find . -name "ldap-access.audit.json" -print)"
  rotatedhttplogs=$(find . -type f \( -name "access.audit.json-*" -o -name "http-access.audit.json.*" \) -print | sort)
  httplogs="$(echo $rotatedhttplogs) $(find . -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)"
else
  ldaplogs=$(find . -name "ldap-access.audit.json" -print)
  httplogs=$(find . -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)
fi

#if [ -n "$ldaplogs" ]; then
ldaplogcount=0
for log in $ldaplogs; do
  if [ -f $log ]; then
    filesize=$(wc -c $log | awk '{print $1}')
    if (($filesize > 0)); then
      filename=$(echo "$log" | sed "s/.*\///")
      printf -v cnt "%05d" $ldaplogcount
      if (($ldaplogcount == 0)); then
        echo "<pre>Operation assessment for $FILENAME</pre>" >./tmp/$cnt-ldap-operations.html
        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --cut $LDAPCUT --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}ldap-poi.json --condense $log >>./tmp/$cnt-ldap-ops.csv
        #        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/${SOURCETYPE}ldap-poi.json --filltimegap --condense $log >>./tmp/$cnt-ldap-ops.csv
        cat $log | $JQ '.userId,.response.status' | tr " " ~ | paste -d " " - - | grep -v null >./tmp/$cnt-ldap-ids.txt
      else
        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --cut $LDAPCUT --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}ldap-poi.json --noheader --condense $log >>./tmp/$cnt-ldap-ops.csv
        #        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/${SOURCETYPE}ldap-poi.json --noheader --filltimegap --condense $log >>./tmp/$cnt-ldap-ops.csv
        cat $log | $JQ '.userId,.response.status' | tr " " ~ | paste -d " " - - | grep -v null >>./tmp/$cnt-ldap-ids.txt
      fi
      echo "<pre>Operations from log file $filename</pre>" >>./tmp/$cnt-ldap-operations.html
      /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}ldap-poi.json --totalsonly --condense $log --sla --html >>./tmp/$cnt-ldap-operations.html
      echo "Cnt | e | operation" >./tmp/$cnt-ldap-ms.txt
      cat $log | $JQ '.response.elapsedTime, .request.operation' | paste -d " " - - | sort -k1 -n | uniq -c | sort -k2 -n >>./tmp/$cnt-ldap-ms.txt
      cat $log | $JQ '.client.ip,.response.status' | paste -d " " - - | grep -v null | tr -d "\"" >>./tmp/$cnt-ldap-ip.txt
      # curl --silent ipinfo.io/40.112.181.172
      ((ldaplogcount++))
    fi
  fi
done
# wait

httplogcount=0
for log in $httplogs; do
  if [ -f $log ]; then
    filesize=$(wc -c $log | awk '{print $1}')
    if (($filesize > 0)); then
      filename=$(echo "$log" | sed "s/.*\///")
      printf -v cnt "%05d" $httplogcount
      if (($httplogcount == 0)); then
        echo "<pre>Operation assessment for $FILENAME</pre>" >./tmp/$cnt-rest-operations.html
        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --cut $HTTPCUT --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}http-poi.json --cut 10000 --condense $log >>./tmp/$cnt-rest-ops.csv
        #        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/${SOURCETYPE}http-poi.json --filltimegap --condense $log >>./tmp/$cnt-rest-ops.csv
        cat $log | $JQ '.userId,.response.status' | tr " " ~ | paste -d " " - - | grep -v null >./tmp/$cnt-rest-ids.txt
      else
        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --cut $HTTPCUT --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}http-poi.json --cut 10000 --noheader --condense $log >>./tmp/$cnt-rest-ops.csv
        #        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/${SOURCETYPE}http-poi.json --noheader --filltimegap --condense $log >>./tmp/$cnt-rest-ops.csv
        cat $log | $JQ '.userId,.response.status' | tr " " ~ | paste -d " " - - | grep -v null >>./tmp/$cnt-rest-ids.txt
      fi
      echo "<pre>Operations from log file $filename</pre>" >>./tmp/$cnt-rest-operations.html
      /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}http-poi.json --totalsonly --cut 10000 --condense $log --sla --html >>./tmp/$cnt-rest-operations.html
      echo "Cnt | e | operation" >./tmp/$cnt-rest-ms.txt
      cat $log | $JQ '.response.elapsedTime, .request.operation' | paste -d " " - - | sort -k1 -n | uniq -c | sort -k2 -n >>./tmp/$cnt-rest-ms.txt &
      cat $log | $JQ '.client.ip,.response.status' | paste -d " " - - | grep -v null | tr -d "\"" >>./tmp/$cnt-rest-ip.txt
      ((httplogcount++))
    fi
  fi
done
# wait

echo "<hr size=\"2\" width=\"100%\"><font face=\"Arial Unicode MS\"><a href=./operation-assessment.html>Operation Assessment</a><br></font><hr size=\"2\" width=\"100%\">" >>./report/report.html
logs=$(ls ./tmp/*-operations.html)
echo "<html><head></head><body>" >./report/operation-assessment.html
for log in $logs; do
  echo "<hr size=\"2\" width=\"100%\">" >>./report/operation-assessment.html
  cat $log >>./report/operation-assessment.html
done
echo "</body></html>" >>./report/operation-assessment.html
echo "<table cellspacing=\"2\" cellpadding=\"2\" border=\"1\"><tr><th>File</th><th>Time span</th><th>Epoch time span</th><th>Length of time</th></tr>" >>./report/report.html
OLDIFS=$IFS
IFS=$'\n'
rows=$(grep 'Operations from log file \|Time span: \|Epoch time: \|Length of time = ' ./report/operation-assessment.html | paste -d" " - - - - | sed 's/pre/td/g')
for row in $rows; do
  echo "<tr><tt>$row</tt></tr>" >>./report/report.html
done
echo "</table><hr>" >>./report/report.html
IFS=$OLDIFS

if (($ldaplogcount != 0)); then
  cat ./tmp/*ldap-ops.csv >./tmp/allldapops.csv
  $SCRIPTHOME/chartprep.sh ./tmp/allldapops.csv
  echo "<div id=\"note\"></div>" >./report/ldapnote.phtml
  if (($ldaplogcount > 1)); then
    echo "<pre><b>Note: </b>More than one log file is being used for the graphs above which <font color=red><b>may</b></font> result in some data discrepancy around (+ or - 1,000ms) these epoch times (shown in milliseconds):</pre>" >>./report/ldapnote.phtml
  fi
  echo "<table cellspacing=\"2\" cellpadding=\"2\" border=\"1\"><tr><th>File</th><th>Time span</th><th>Epoch time span</th><th>Length of time</th></tr>" >>./report/ldapnote.phtml
  OLDIFS=$IFS
  IFS=$'\n'
  rows=$(grep 'Operations from log file \|Time span: \|Epoch time: \|Length of time = ' ./report/operation-assessment.html | paste -d" " - - - - | grep ldap | sed 's/pre/td/g')
  for row in $rows; do
    echo "<tr><tt>$row</tt></tr>" >>./report/ldapnote.phtml
  done
  echo "</table><hr>" >>./report/ldapnote.phtml
  IFS=$OLDIFS
  cat /Users/robert.faller/projects/SawMill/content/chartheader.phtml ./opscolumns.data ./etimescolumns.data ./ops.data ./etimes.data /Users/robert.faller/projects/SawMill/content/charttailer.phtml ./report/ldapnote.phtml >./report/allldapops.html
  echo "</body></html>" >>./report/allldapops.html
  echo "<font face=\"Arial Unicode MS\"><a href=./allldapops.html>LDAP operations (DS | CTS | Config store)</a><br></font><hr size=\"2\" width=\"100%\">" >>./report/report.html
fi

if (($httplogcount != 0)); then
  cat ./tmp/*rest-ops.csv >./tmp/allrestops.csv
  $SCRIPTHOME/chartprep.sh ./tmp/allrestops.csv
  echo "<div id=\"note\"></div>" >./report/restnote.phtml
  if (($httplogcount > 1)); then
    echo "<pre><b>Note: </b>More than one log file is being used for the graphs above which <font color=red><b>may</b></font> result in some data discrepancy around (+ or - 1,000ms) these epoch times (shown in milliseconds):</pre>" >>./report/restnote.phtml
  fi
  echo "<table cellspacing=\"2\" cellpadding=\"2\" border=\"1\"><tr><th>File</th><th>Time span</th><th>Epoch time span</th><th>Length of time</th></tr>" >>./report/restnote.phtml
  OLDIFS=$IFS
  IFS=$'\n'
  rows=$(grep 'Operations from log file \|Time span: \|Epoch time: \|Length of time = ' ./report/operation-assessment.html | paste -d" " - - - - | grep -v ldap | sed 's/pre/td/g')
  for row in $rows; do
    echo "<tr><tt>$row</tt></tr>" >>./report/restnote.phtml
  done
  echo "</table><hr>" >>./report/restnote.phtml
  IFS=$OLDIFS
  cat /Users/robert.faller/projects/SawMill/content/chartheader.phtml ./opscolumns.data ./etimescolumns.data ./ops.data ./etimes.data /Users/robert.faller/projects/SawMill/content/charttailer.phtml ./report/restnote.phtml >./report/allrestops.html
  echo "</body></html>" >>./report/allrestops.html
  echo "<font face=\"Arial Unicode MS\"><a href=./allrestops.html>REST operations</a><br></font><hr size=\"2\" width=\"100%\">" >>./report/report.html
fi

cat ./tmp/*-ip.txt | sed -e s"/SUCCESSFUL//" | sed -e s"/FAILED//" | sort | uniq >./tmp/all-ipsonly.txt
cat ./tmp/*-ip.txt | sort -n | uniq -c | tr -s " " | sed -e s"/^ //" >./tmp/all-ips-sorted.txt
cat ./tmp/*-ids.txt | sed -e s"/ \"SUCCESSFUL\"//" | sed -e s"/ \"FAILED\"//" | sort | uniq >./tmp/all-idsonly.txt
cat ./tmp/*-ids.txt | sort | uniq -c | tr -s " " | sed -e s"/^ //" >./tmp/all-ids-sorted.txt
wait

echo "<html><head></head><body>" >./report/ip-assessment.html
echo "<table id=\"iptable\" class=\"searchablesortable\" cellpadding=\"1\" border=\"1\">" >>./report/ip-assessment.html
echo "<thead><tr><th onclick=\"sortTable(0)\">IP-address</th><th onclick=\"sortTable(1)\">SUCCESSFUL-operations</th><th onclick=\"sortTable(2)\">FAILED-operations</th></tr></thead><tbody>" >>./report/ip-assessment.html
while read ipvalue; do
  failed=$(grep "$ipvalue" ./tmp/all-ips-sorted.txt | grep FAILED | cut -f1 -d" ")
  successful=$(grep "$ipvalue" ./tmp/all-ips-sorted.txt | grep SUCCESSFUL | cut -f1 -d" ")
  echo "<tr><td><pre><a href=https://ipinfo.io/$ipvalue>$ipvalue</a></pre></td><td><pre>$successful</pre></td><td><pre>$failed</pre></td></tr>" >>./report/ip-assessment.html
done <./tmp/all-ipsonly.txt
echo "<tr><td><pre><a href=https://ipinfo.io/40.112.181.172>40.112.181.172</a></pre></td><td><pre>SAMPLE</pre></td><td><pre>-</pre></td></tr>" >>./report/ip-assessment.html
echo "</tbody></table></body></html>" >>./report/ip-assessment.html
echo "<a href=./ip-assessment.html>IP Assessment</a><hr>" >>./report/report.html

echo "<html><head></head><body>" >./report/id-assessment.html
echo "<table id=\"idtable\" class=\"searchablesortable\" cellpadding=\"1\" border=\"1\"><tbody>" >>./report/id-assessment.html
echo "<tr><td>Id</td><td>Number of SUCCESSFUL operations</td><td>Number of FAILED operations</td><td>success:fail ratio score</td></tr>" >>./report/id-assessment.html
# echo "<thead><tr><th onclick=\"sortTableID(0)\">ID</th><th onclick=\"sortTableID(1)\">SUCCESSFUL-operations</th><th onclick=\"sortTableID(2)\">FAILED-operations</th><th onclick=\"sortTableID(3)\">Score</th></tr></thead><tbody>" >>./report/report.html
idvaluecount=0
while read idvalue; do
  declare -i failed=$(grep "$idvalue" ./tmp/all-ids-sorted.txt | grep FAILED | cut -f1 -d" ")
  declare -i successful=$(grep "$idvalue" ./tmp/all-ids-sorted.txt | grep SUCCESSFUL | cut -f1 -d" ")
  if (($failed >= 1)); then
    #    ratio=$(echo $successful / $failed | bc -l)
    declare -i totalopcount=$(echo $successful + $failed | bc -l)
    ratio=$(echo $failed / $totalopcount | bc -l)
    printf -v score "%.4f" $ratio
  else
    ratio=$successful
    score="-"
  fi
  headervalue=$(($idvaluecount % 20))
  echo "<tr><td><pre>" >>./report/id-assessment.html
  #  echo "<form id=\"dig_$idvaluecount\" name=\"dig_$idvaluecount\" method=\"POST\" action=\"kestreldig\">" >>./report/report.html
  #  echo "<input id=\"submit_$idvaluecount\" type=\"submit\" value=$idvalue></form>" >>./report/report.html
  #    idonly=$(echo $idvalue | cut -f1 -d",")
  #    echo "$idonly" >>./report/report.html
  echo "$idvalue" >>./report/id-assessment.html
  echo "</pre></td>" >>./report/id-assessment.html
  ((idvaluecount++))
  if (($failed == 0)); then
    echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td><pre>$score</pre></td>" >>./report/id-assessment.html
  else
    if (($successful >= $failed)); then
      echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td bgcolor=\"lightyellow\"><pre>$score</pre></td>" >>./report/id-assessment.html
    else
      if (($successful >= 1)); then
        echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td bgcolor=\"pink\"><pre>$score</pre></td>" >>./report/id-assessment.html
      else
        echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td bgcolor=\"red\"><pre>$score</pre></td>" >>./report/id-assessment.html
      fi
    fi
  fi
  echo "</tr>" >>./report/id-assessment.html
done <./tmp/all-idsonly.txt
echo "</tbody></table></pre>" >>./report/id-assessment.html
cat $SCRIPTHOME/sortTable.js >>./report/id-assessment.html
echo "</body></html>" >>./report/id-assessment.html
echo "<a href=./id-assessment.html>ID Assessment</a><hr>" >>./report/report.html

# cat $SCRIPT_HOME/sortTableID.js >>./report/report.html
echo "<hr><pre> --- END OF REPORT --- </body> </html>" >>./report/report.html
echo "</body> </html>" >>./report/report.html

# rm -r tmp