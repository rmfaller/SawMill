#!/bin/bash
headrow=`head -1 $1 | cut -f5- -d","`
IFS=,
headcnt=0
poi=0
prevhdr=null
for header in $headrow
  do
  newhdr=`echo $header | cut -f1 -d"."`
  if [ "$prevhdr" != "$newhdr" ]
    then 
    prevhdr=$newhdr
    let poi=$poi+1
  fi
  let headcnt=$headcnt+1
done
let graphs=$headcnt/$poi
let g=$graphs
echo "set terminal 'gif' size 1600, 800"
echo "set output 'output.gif'"
echo "set multiplot layout $g,1 columnsfirst scale 1.0,1.0"
echo "set rmargin 32"
echo "set lmargin 8"
echo "set tmargin 0"
echo "set bmargin 0"
echo "set datafile separator ','"
echo "set style data lines"
echo "set grid"
echo "set key autotitle columnhead"
echo "set key outside font \",10\""
# echo "plot '$1' using 1:4 title columnheader"
let c=$poi-1
for (( i=1; i<=$graphs; i++ ))
  do
  echo -n "plot '$1' "
  for (( j=0; j<$poi; j++ ))
    do
    let y=$j*$graphs
    let x=$i+$y+4
    if (( j != 0 ))
      then
      echo -n " '' using 1:$x title columnheader"
    else
      echo -n "using 1:$x title columnheader"
    fi
    if (( j < c ))
      then
      echo ", \\"
    fi
  done
  echo ""
done
echo "pause -1 \"Press any key to continue\""
