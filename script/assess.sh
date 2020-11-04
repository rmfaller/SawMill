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
SUBSCRIPTION=/Volumes/twoTBdrive/sawmill/$1
FULLFILENAME=$2
SOURCETYPE=$3
ZIPTYPE=$4
LDAPCUT=1
HTTPCUT=1
FILENAME=${FULLFILENAME%.*}
FILENAMEONLY=${FILENAME##*/}
SERVICEBASE="/Users/rmfaller/projects/BlueOx/build/web"
WDIR=$(pwd)

cd $SUBSCRIPTION
mkdir $FILENAMEONLY
cd $FILENAMEONLY
# dd=`date`
# cat ./metadata.json | $JQ --arg dd "$dd" '.unzipped.starttime = $dd' > ./tmpmetadata.json
# mv ./tmpmetadata.json ./metadata.json
$JAR -xf $2
# dd=`date`
# cat ./metadata.json | $JQ --arg dd "$dd" '.unzipped.endtime = $dd' > ./tmpmetadata.json
# mv ./tmpmetadata.json ./metadata.json
mkdir tmp
mkdir report
$SCRIPTHOME/createpoi.sh $SUBSCRIPTION $FILENAMEONLY $3

# uploadtype=`cat metadata.json | jq -r '.info.uploadtype'`
#echo "<html> <head> <title>BlueOx</title> </head> <body><a name=\"extract\"></a>Extractor Report<br>" >./report/report.html
echo "<html> <head> <title>BlueOx</title> </head> <body>" >./report/report.html
echo "<h2><b> <font face=\"Arial Unicode MS\"><font color=\"#3333ff\">BlueOx</font>" >>./report/report.html
echo "Report for Subscription = $SUBSCRIPTION and File = $FILENAMEONLY</font></b></h2>" >>./report/report.html
# echo "<hr><a href=./allldapops.html>LDAPOPS</a><hr>" >>./report/report.html

# if [[ "$uploadtype" = "dsextract" ]]; then
if [ "$ZIPTYPE" = "x" ]; then
  #  dd=`date`;
  #  cat ./metadata.json | $JQ --arg dd "$dd" '.extracted.starttime = $dd' > ./tmpmetadata.json;
  #  mv ./tmpmetadata.json ./metadata.json
  cd ./support-data/config
  # $SCRIPT_HOME/extractor2.1b.sh  -r $FILENAME -h -e
#  $SCRIPTHOME/extractor.sh -r $FILENAMEONLY -h
  mv $FILENAMEONLY.html ../../report/.
  # echo "moved $FILENAMEONLY.html"
  cd ../../
  #  cat ./report/$FILENAMEONLY.html >>./report/report.html
  #  dd=`date`;
  #  cat ./metadata.json | $JQ --arg dd "$dd" '.extracted.endtime = $dd' > ./tmpmetadata.json;
  #  mv ./tmpmetadata.json ./metadata.json
  echo "<hr size=\"2\" width=\"100%\"><font face=\"Arial Unicode MS\"><a href=./$FILENAMEONLY.html>Directory Server Extractor Report</a><br></font>" >>./report/report.html
fi

# rotatedldaplogs=$(ls ./support-data/logs/ldap-access.audit.json.*)
rotatedldaplogs=$(find . -name "ldap-access.audit.json.*" -print)
# ldaplogs="$(echo $rotatedldaplogs)  $(ls ./support-data/logs/ldap-access.audit.json)"
ldaplogs="$(echo $rotatedldaplogs)  $(find . -name "ldap-access.audit.json" -print)"
rotatedhttplogs=$(find . -type f \( -name "access.audit.json-*" -o -name "http-access.audit.json.*" \) -print)
httplogs="$(echo $rotatedhttplogs) $(find . -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)"

if [ -n "$ldaplogs" ]; then
  # dd=`date`
  # cat ./metadata.json | $JQ --arg dd "$dd" '.operationsassessed.starttime = $dd' > ./tmpmetadata.json
  # mv ./tmpmetadata.json ./metadata.json
  ldaplogcount=0
  for log in $ldaplogs; do
    if [ -f $log ]; then
      filesize=$(wc -c $log | awk '{print $1}')
      if (($filesize > 0)); then
        filename=$(echo "$log" | sed "s/.*\///")
        printf -v cnt "%05d" $ldaplogcount
        if (($ldaplogcount == 0)); then
          echo "<pre>Operation assessment for $FILENAME</pre>" >./tmp/$cnt-ldap-operations.html
          /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}ldap-poi.json --condense $log >>./tmp/$cnt-ldap-ops.csv
          #        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/${SOURCETYPE}ldap-poi.json --filltimegap --condense $log >>./tmp/$cnt-ldap-ops.csv
          cat $log | $JQ '.userId,.response.status' | tr " " ~ | paste -d " " - - | grep -v null >./tmp/$cnt-ldap-ids.txt
        else
          /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}ldap-poi.json --noheader --condense $log >>./tmp/$cnt-ldap-ops.csv
          #        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/${SOURCETYPE}ldap-poi.json --noheader --filltimegap --condense $log >>./tmp/$cnt-ldap-ops.csv
          cat $log | $JQ '.userId,.response.status' | tr " " ~ | paste -d " " - - | grep -v null >>./tmp/$cnt-ldap-ids.txt
        fi
        echo "<pre>Operations from log file $filename</pre>" >>./tmp/$cnt-ldap-operations.html
        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}ldap-poi.json --totalsonly --condense $log --sla --html >>./tmp/$cnt-ldap-operations.html
        echo "Cnt | e | operation" >./tmp/$cnt-ldap-ms.txt
        cat $log | $JQ '.response.elapsedTime, .request.operation' | paste -d " " - - | sort -k1 -n | uniq -c | sort -k2 -n >>./tmp/$cnt-ldap-ms.txt
        cat $log | $JQ '.client.ip,.response.status' | paste -d " " - - | grep -v null | tr -d "\"" >>./tmp/$cnt-ldap-ip.txt
        #      cat $log | $HOME/bin/jq '.client.ip,.response.status' | paste -d " " - - | grep -v null | tr -d "\"" | sort -n | uniq -c >>./tmp/$cnt-ldap-ip.txt
        #      echo "<hr><hr>" >> ./tmp/$cnt-ldap-operations.html
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
          /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}http-poi.json --cut 10000 --condense $log >>./tmp/$cnt-rest-ops.csv
          #        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/${SOURCETYPE}http-poi.json --filltimegap --condense $log >>./tmp/$cnt-rest-ops.csv
          cat $log | $JQ '.userId,.response.status' | tr " " ~ | paste -d " " - - | grep -v null >./tmp/$cnt-rest-ids.txt
        else
          /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}http-poi.json --cut 10000 --noheader --condense $log >>./tmp/$cnt-rest-ops.csv
          #        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/${SOURCETYPE}http-poi.json --noheader --filltimegap --condense $log >>./tmp/$cnt-rest-ops.csv
          cat $log | $JQ '.userId,.response.status' | tr " " ~ | paste -d " " - - | grep -v null >>./tmp/$cnt-rest-ids.txt
        fi
        echo "<pre>Operations from log file $filename</pre>" >>./tmp/$cnt-rest-operations.html
        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/$FILENAMEONLY/${SOURCETYPE}http-poi.json --totalsonly --cut 10000 --condense $log --sla --html >>./tmp/$cnt-rest-operations.html
        echo "Cnt | e | operation" >./tmp/$cnt-rest-ms.txt
        cat $log | $JQ '.response.elapsedTime, .request.operation' | paste -d " " - - | sort -k1 -n | uniq -c | sort -k2 -n >>./tmp/$cnt-rest-ms.txt &
        cat $log | $JQ '.client.ip,.response.status' | paste -d " " - - | grep -v null | tr -d "\"" >>./tmp/$cnt-rest-ip.txt
        #      cat $log | $HOME/bin/jq '.client.ip,.response.status' | paste -d " " - - | grep -v null | tr -d "\"" | sort -n | uniq -c >>./tmp/$cnt-rest-ip.txt
        #      echo "<hr><hr>" >> ./tmp/$cnt-rest-operations.html
        # curl --silent ipinfo.io/40.112.181.172
        ((httplogcount++))
      fi
    fi
  done
  # wait

  # echo "<a name=\"operationassessment\"></a>Operation Assessment<br>" >>./report/report.html
  echo "<hr size=\"2\" width=\"100%\"><font face=\"Arial Unicode MS\"><a href=./operation-assessment.html>Operation Assessment</a><br></font><hr size=\"2\" width=\"100%\">" >>./report/report.html
  logs=$(ls ./tmp/*-operations.html)
  echo "" >./report/operation-assessment.html
  for log in $logs; do
    echo "<hr size=\"2\" width=\"100%\">" >>./report/operation-assessment.html
    cat $log >>./report/operation-assessment.html
  done

  # dd=`date`
  # cat ./metadata.json | $JQ --arg dd "$dd" '.operationsassessed.endtime = $dd' > ./tmpmetadata.json
  # mv ./tmpmetadata.json ./metadata.json

  # dd=`date`
  # cat ./metadata.json | $JQ --arg dd "$dd" '.activitygraphed.starttime = $dd' > ./tmpmetadata.json
  # mv ./tmpmetadata.json ./metadata.json

  cat ./tmp/*-ops.csv >./tmp/allops.csv

  if (($ldaplogcount != 0)); then
    cat ./tmp/*ldap-ops.csv >./tmp/allldapops.csv
    $SCRIPTHOME/chartprep.sh ./tmp/allldapops.csv
    cat /Users/robert.faller/projects/SawMill/content/chartheader.phtml ./opscolumns.data ./etimescolumns.data ./ops.data ./etimes.data /Users/robert.faller/projects/SawMill/content/charttailer.phtml >./report/allldapops.html
    echo "<font face=\"Arial Unicode MS\"><a href=./allldapops.html>LDAP operations (DS | CTS | Config store)</a><br></font><hr size=\"2\" width=\"100%\">" >>./report/report.html
  fi

  if (($httplogcount != 0)); then
    cat ./tmp/*rest-ops.csv >./tmp/allrestops.csv
    $SCRIPTHOME/chartprep.sh ./tmp/allrestops.csv
    cat /Users/robert.faller/projects/SawMill/content/chartheader.phtml ./opscolumns.data ./etimescolumns.data ./ops.data ./etimes.data /Users/robert.faller/projects/SawMill/content/charttailer.phtml >./report/allrestops.html
    echo "<font face=\"Arial Unicode MS\"><a href=./allrestops.html>REST operations</a><br></font><hr size=\"2\" width=\"100%\">" >>./report/report.html
  fi

  cat ./tmp/*-ip.txt | sed -e s"/SUCCESSFUL//" | sed -e s"/FAILED//" | sort | uniq >./tmp/all-ipsonly.txt
  cat ./tmp/*-ip.txt | sort -n | uniq -c | tr -s " " | sed -e s"/^ //" >./tmp/all-ips-sorted.txt
  cat ./tmp/*-ids.txt | sed -e s"/ \"SUCCESSFUL\"//" | sed -e s"/ \"FAILED\"//" | sort | uniq >./tmp/all-idsonly.txt
  cat ./tmp/*-ids.txt | sort | uniq -c | tr -s " " | sed -e s"/^ //" >./tmp/all-ids-sorted.txt
  wait

  # dd=`date`
  # cat ./metadata.json | $JQ --arg dd "$dd" '.ipaddressesassessed.starttime = $dd' > ./tmpmetadata.json
  # mv ./tmpmetadata.json ./metadata.json
  echo "<pre>IP addresses that have accessed this instance <br>" >>./report/report.html
  echo "<table id=\"iptable\" class=\"searchablesortable\" cellpadding=\"1\" border=\"1\">" >>./report/report.html
  # echo "<tr><td>Access count</td><td>IP address</td><td>Status</td></tr>" >>$UPLOADS/$UPLOADNAME/report/report.html
  echo "<thead><tr><th onclick=\"sortTable(0)\">IP-address</th><th onclick=\"sortTable(1)\">SUCCESSFUL-operations</th><th onclick=\"sortTable(2)\">FAILED-operations</th></tr></thead><tbody>" >>./report/report.html
  while read ipvalue; do
    failed=$(grep "$ipvalue" ./tmp/all-ips-sorted.txt | grep FAILED | cut -f1 -d" ")
    successful=$(grep "$ipvalue" ./tmp/all-ips-sorted.txt | grep SUCCESSFUL | cut -f1 -d" ")
    echo "<tr><td><pre><a href=https://ipinfo.io/$ipvalue>$ipvalue</a></pre></td><td><pre>$successful</pre></td><td><pre>$failed</pre></td></tr>" >>./report/report.html
  done <./tmp/all-ipsonly.txt
  echo "<tr><td><pre><a href=https://ipinfo.io/40.112.181.172>40.112.181.172</a></pre></td><td><pre>SAMPLE</pre></td><td><pre>-</pre></td></tr>" >>./report/report.html
  echo "</tbody></table>" >>./report/report.html
  # dd=`date`
  # cat ./metadata.json | $JQ --arg dd "$dd" '.ipaddressesassessed.endtime = $dd' > ./tmpmetadata.json
  # mv ./tmpmetadata.json ./metadata.json
  # dd=`date`
  # cat ./metadata.json | $JQ --arg dd "$dd" '.accessassessed.starttime = $dd' > ./tmpmetadata.json
  # mv ./tmpmetadata.json ./metadata.json
  echo "<pre>Identities that have accessed this instance <br>" >>./report/report.html
  echo "<table id=\"idtable\" class=\"searchablesortable\" cellpadding=\"1\" border=\"1\"><tbody>" >>./report/report.html
  echo "<tr><td>Id</td><td>Number of SUCCESSFUL operations</td><td>Number of FAILED operations</td><td>success:fail ratio score</td></tr>" >>./report/report.html
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
    #  echo "<tr><td><pre>$headervalue" >>./report/report.html
    echo "<tr><td><pre>" >>./report/report.html
    #  echo "<form id=\"dig_$idvaluecount\" name=\"dig_$idvaluecount\" method=\"POST\" action=\"kestreldig\">" >>./report/report.html
    #  echo "<input id=\"submit_$idvaluecount\" type=\"submit\" value=$idvalue></form>" >>./report/report.html
    #    idonly=$(echo $idvalue | cut -f1 -d",")
    #    echo "$idonly" >>./report/report.html
    echo "$idvalue" >>./report/report.html
    echo "</pre></td>" >>./report/report.html
    ((idvaluecount++))
    if (($failed == 0)); then
      echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td><pre>$score</pre></td>" >>./report/report.html
    else
      if (($successful >= $failed)); then
        echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td bgcolor=\"lightyellow\"><pre>$score</pre></td>" >>./report/report.html
      else
        if (($successful >= 1)); then
          echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td bgcolor=\"pink\"><pre>$score</pre></td>" >>./report/report.html
        else
          echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td bgcolor=\"red\"><pre>$score</pre></td>" >>./report/report.html
        fi
      fi
    fi
    echo "</tr>" >>./report/report.html
  done <./tmp/all-idsonly.txt
  echo "</tbody></table>" >>./report/report.html
  echo "</pre><br>" >>./report/report.html
  cat $SCRIPTHOME/sortTable.js >>./report/report.html
  # cat $SCRIPT_HOME/sortTableID.js >>./report/report.html
  echo "</body> </html>" >>./report/report.html

#dd=`date`
# cat ./metadata.json | $JQ --arg dd "$dd" '.accessassessed.endtime = $dd' > ./tmpmetadata.json
# mv ./tmpmetadata.json ./metadata.json

else
  echo "<pre>No LDAP log files found</pre>" >>./tmp/$cnt-operations.html
  dd="No LDAP logs"
  cat ./metadata.json | $JQ --arg dd "$dd" '.operationsassessed.starttime = $dd' >./tmpmetadata.json
  mv ./tmpmetadata.json ./metadata.json
  cat ./metadata.json | $JQ --arg dd "$dd" '.operationsassessed.endtime = $dd' >./tmpmetadata.json
  mv ./tmpmetadata.json ./metadata.json
  cat ./metadata.json | $JQ --arg dd "$dd" '.activitygraphed.starttime = $dd' >./tmpmetadata.json
  mv ./tmpmetadata.json ./metadata.json
  cat ./metadata.json | $JQ --arg dd "$dd" '.activitygraphed.endtime = $dd' >./tmpmetadata.json
  mv ./tmpmetadata.json ./metadata.json
  cat ./metadata.json | $JQ --arg dd "$dd" '.ipaddressesassessed.starttime = $dd' >./tmpmetadata.json
  mv ./tmpmetadata.json ./metadata.json
  cat ./metadata.json | $JQ --arg dd "$dd" '.ipaddressesassessed.endtime = $dd' >./tmpmetadata.json
  mv ./tmpmetadata.json ./metadata.json
  cat ./metadata.json | $JQ --arg dd "$dd" '.accessassessed.starttime = $dd' >./tmpmetadata.json
  mv ./tmpmetadata.json ./metadata.json
  cat ./metadata.json | $JQ --arg dd "$dd" '.accessassessed.endtime = $dd' >./tmpmetadata.json
  mv ./tmpmetadata.json ./metadata.json
  echo "</body> </html>" >>./report/report.html

fi

# rm -r tmp
