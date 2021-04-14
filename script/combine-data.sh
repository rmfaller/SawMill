#!/bin/bash
SAWMILL_HOME="$HOME/projects/SawMill"

if [[ $1 ]]; then
  SOURCE=$1
  if [ ! -d $SOURCE ]; then
    echo "$SOURCE does not exist."
    exit
  fi
else
  echo "Argument 1 - name of directory where files to combine exist."
  exit
fi

if [[ $2 ]]; then
  TARGET=$2
else
  echo "Argument 2 - name to use for combined output."
  exit
fi

files=$(find $SOURCE -name all*ops.csv -print | sort)
echo "<hr>Sources included:" > $SOURCE/$TARGET-sources.html
let x=0
for file in $files
do
echo "<br>$x : $file" >> $SOURCE/$TARGET-sources.html
((x++))
done
echo "<hr></body></html>" >> $SOURCE/$TARGET-sources.html

java -jar $SAWMILL_HOME/dist/SawMill.jar --usenull --startcut 1618176508000 --laminate $files > $SOURCE/$TARGET.csv
$SAWMILL_HOME/script/chartprep.sh $SOURCE/$TARGET.csv
cat $SAWMILL_HOME/content/chartheader.phtml $SOURCE/opscolumns.data $SOURCE/etimescolumns.data $SOURCE/ops.data $SOURCE/etimes.data $SAWMILL_HOME/content/charttailer.phtml $SOURCE/$TARGET-sources.html > $SOURCE/$TARGET.html

