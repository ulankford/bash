#!bin/bash
#
#Script to extract Info from fixStorage.pl and use for the creation of Jira requests for more HDD Space

#Set parameters
FINALOUTPUT="/tmp/diskcheckoutput.txt"
TEMPOUTPUT="/tmp/storage.txt"

#Get the last month usage of disk
echo "fixstorage -r1"
echo "{noformat}"
/usr/local/cmss/bin/fixStorage.pl -t alertweb -r 1 2>&1 | tail -n3
/usr/local/cmss/bin/fixStorage.pl -t alertweb -r 1 2>&1 | grep -B1 ERROR | head -1 | awk '{print $9}' > $TEMPOUTPUT
#$TWO_MONTH="$(head -1 /tmp/storagesum.txt)"
echo "{noformat}"

#Get the second last month usage of disk
echo "fixstorage -r30"
echo "{noformat}"
/usr/local/cmss/bin/fixStorage.pl -t alertweb -r 30 2>&1 | tail -n3
/usr/local/cmss/bin/fixStorage.pl -t alertweb -r 30 2>&1 | grep 'Will move' | head -1 | awk '{print $9}' >> $TEMPOUTPUT
#LAST_MONTH="$(tail -1 /tmp/storagesum.txt)"
echo "{noformat}"

TWO_MONTH="$(head -1 $TEMPOUTPUT)"
LAST_MONTH="$(tail -1 $TEMPOUTPUT)"

#Calculate the monthly growth rate needed for disk
SUMONE=$(expr ${TWO_MONTH} - ${LAST_MONTH})
TOTAL=$( echo "scale=4;${SUMONE}/1073741824" | bc)
echo "1 month used disk space data01 (GB): ${TOTAL}"
CACHE_SIZE=$(du -shc /data01/cmss/data/cache/*/$(date --date="last month" +%Y%m)* | grep total | awk -F "G" '{print $1}')
echo "1 month cache size (GB): ${CACHE_SIZE}"
SIZE_REQUIRED=$(echo "${TOTAL}+${CACHE_SIZE}" | bc)
echo "Total disk required per month (GB): ${SIZE_REQUIRED}"

#Create the output in a nicely Jira formatted file
echo "||Partition||Size||%Used||Monthly Use||" > $FINALOUTPUT

#Get Data01 output
df -Th | grep data01 | grep -v archive
#Get Data01/archive output
df -h /data01 /data01/archive
~                                                                                                                                                                                                              
~                                                      