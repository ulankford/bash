#!bin/bash
#
#Script to extract Info from fixStorage.pl and use for the creation of Jira requests for more HDD Space

#Set Parameters
OUTPUTFILE="/tmp/output.txt"
HOST=$(hostname)
DATE=$(date)
EMAIL=$1

#Check if a parameter which should be an email address has been passed in via command line
SendMail()
{
if [ "$EMAIL" != "" ] ; then
echo "Attached is the text file that gives you Disk Resize details you want for" $HOST | mail -s "Disk Space Resize Report for Host $HOST  -  $DATE " -a $OUTPUTFILE $EMAIL
        else
echo "No email address found, output file can be found in the /tmp directory"
fi
}

#Cleanup
rm $OUTPUTFILE

#Simple Filesystem Disk Space Usage Output for /data01 and /data01/archive partitions if the latter exists
echo "{noformat}" > $OUTPUTFILE
df -h | grep /data01 >> $OUTPUTFILE
echo "{noformat}" >> $OUTPUTFILE

#Get one months SMARTS data usage via the fixStorage.pl script
echo -e "\nfixstorage -r1" >> $OUTPUTFILE
echo -e "{noformat}" >> $OUTPUTFILE
/usr/local/cmss/bin/fixStorage.pl -t alertweb -r 1 2>&1 | tail -n3 >> $OUTPUTFILE
TWO_MONTH="$(grep 'Will move' $OUTPUTFILE | awk '{print $9}')"
#/usr/local/cmss/bin/fixStorage.pl -t alertweb -r 1 2>&1 | grep 'Will move' | head -1 | awk '{print $9}' > /tmp/storage.txt
echo -e "{noformat}" >> $OUTPUTFILE

#Get two months SMARTS data usage via the fixStorage.pl script
echo -e "\nfixstorage -r30" >> $OUTPUTFILE
echo -e "{noformat}" >> $OUTPUTFILE
/usr/local/cmss/bin/fixStorage.pl -t alertweb -r 30 2>&1 | tail -n3 >> $OUTPUTFILE
LAST_MONTH="$(awk '/Will move/{i++}i==2' $OUTPUTFILE | awk '{print $9}' | head -1)"

#Check if LAST_MONTH has a value, otherwise exit
if [ -z "$LAST_MONTH"  ] ; then
	NOTHING_CHECK="$(/usr/local/cmss/bin/fixStorage.pl -t alertweb -r 30 2>&1 | tail -n1 | awk '{print $7}')"
		if [ $NOTHING_CHECK = "Nothing" ] ; then 
			echo -e "Nothing to Move for 30 Days" >> $OUTPUTFILE
		else
			echo -e "Unknown Error, Run fixStorage Manually" >> $OUTPUTFILE
			SendMail
			exit 0
		fi
SendMail
exit 0
else
:
fi

#Calculate the variable SUMONE which is the total growth of the past month and the variable TOTAL which outputs it in GB
SUMONE=$(expr ${TWO_MONTH} - ${LAST_MONTH})
TOTAL=$( echo "scale=4;${SUMONE}/1073741824" | bc)
echo -e "\n1 Month in growth used disk space data01 (GB): ${TOTAL}" >> $OUTPUTFILE

#Calculate cachesize
CACHE_SIZE=$(du -shc /data01/cmss/data/cache/*/$(date --date="last month" +%Y%m)* | grep total | awk -F "G" '{print $1}')
echo -e "1 month cache size (GB): ${CACHE_SIZE}" >> $OUTPUTFILE

#Calculate required size
EXISTING_SIZE=$( echo "scale=4;$(df --block=1 | grep /data01 | head -1 | awk '{print $2}')/1073741824" | bc)
EXISTING_USED=$( echo "scale=4;$(df --block=1 | grep /data01 | head -1 | awk '{print $3}')/1073741824" | bc)
SIZE_REQUIRED=$(echo "${TOTAL}+${CACHE_SIZE}" | bc)
PARTITION_REQUIRED=$( echo "scale=4;${SIZE_REQUIRED}*3+${EXISTING_SIZE}" | bc )
echo -e "Extra disk required per month due to growth (GB): ${SIZE_REQUIRED}"  >> $OUTPUTFILE
echo -e "Partition size required based on current partition size and future growth: ${PARTITION_REQUIRED}" >> $OUTPUTFILE


#Check if Disk is numbered in TB or GB
Disk_Flag=$(df -h | grep data01$ | awk '{print $2}' | sed 's/[0-9]*//g' | sed 's/\.//g')
	if [ $Disk_Flag = "G" ] ; then
		DISK_SIZE=$(df -h | grep data01$ | awk '{print $2}' | sed 's/G//')
	elif  [ $Disk_Flag = "T" ] ; then
		DISK_SIZE=$(df -h | grep data01$ | awk '{print $2}' | sed 's/T//')
	else
		echo "Error with Disk Flag"
		SendMail
		exit 0
	fi

#Calculate data01 variables
INCREASE_AMOUNT=$( echo "scale=1;${PARTITION_REQUIRED} - ${DISK_SIZE}" | bc )
PERCENT_USED_AFTER=$( echo "scale=1;${EXISTING_USED}*100/${PARTITION_REQUIRED}" | bc )

echo -e "\n||Partition||% Used||Monthly Growth||Increase by||% Used after" >> $OUTPUTFILE
echo "|data01|$(df -h | grep /data01 | awk '{print $5}' | head -1)|${SIZE_REQUIRED} GB|${INCREASE_AMOUNT} GB|${PERCENT_USED_AFTER}%" >> $OUTPUTFILE

#Check if /data01/archive parition exsits, if so output results.
df -h | grep --quiet /data01/archive
if [ $? -eq 0 ] ; then
ARCHIVE_EXISTING_SIZE=$( echo "scale=4;$(df --block=1 | grep /data01/archive | awk '{print $2}')/1073741824" | bc)
ARCHIVE_EXISTING_USED=$( echo "scale=4;$(df --block=1 | grep /data01/archive | awk '{print $3}')/1073741824" | bc)
ARCHIVE_SIZE_REQUIRED=$(echo "${TOTAL}+${CACHE_SIZE}" | bc)
ARCHIVE_PARTITION_REQUIRED=$( echo "scale=4;${ARCHIVE_SIZE_REQUIRED}*3+${ARCHIVE_EXISTING_SIZE}" | bc )
ARCHIVE_INCREASE=$( echo "scale=1; ${TOTAL}*6" | bc)
ARCHIVE_PERCENT_USED_AFTER=$( echo "scale=1;${ARCHIVE_EXISTING_USED}*100/${ARCHIVE_PARTITION_REQUIRED}" | bc )
echo "|data01/archive|$(df -h | grep /data01/archive | awk '{print $5}')|${TOTAL} GB|${ARCHIVE_INCREASE} GB|${ARCHIVE_PERCENT_USED_AFTER} %" >> $OUTPUTFILE
        else
echo "data01/archive partition does not exist on this server" >> $OUTPUTFILE
fi

SendMail
