#!/bin/bash

###############################################################
#  SMARTS TI Main backup script  
#--------------------------------
#
# This script will do a daily backup of all SMARTSOnline client
# machines, this only includes GW and APPS.
#
# - A report will be generated and be sent out to the TI group at
# 6 every morning.
#
# - If there is an error during backup, the subject line will
# contain text "BAD!" and the report outline will be RED,
# else "GOOD!" and the report outline will be GREEN
# 
# - All jobs are listed in crontab -l 
#
# Note: DNS is just added into the host file, /etc/hosts				 
#       So if this script ever gets moved, the hosts file
#       will also need to be copied
#				 
# 07/09/2009 -
# Added txt2html to produce a nice HTML report
#
# 14/09/2009 -
# Added switches to select client and host type
#
# 02/10/2009 -
# Change the way info is collected and combined for reports
#
# 14/01/2010 -
# Final touch ups with bugs and errors, Email subject will now
# show the correct status of BAD! or GOOD!
# 
# 01/03/2010 -
# Fixed an issue where it doesn't grep the proper date from the 1st-9th due to single digit
#
# 18/03/2010 -
# Fixed an overlap where precheck was removing all of client backup except the client it backs up
#
# 14/04/2010 -
# Added if check for SCA to change APPS IP to ".7" as the ".3" in the APPS_BU function
# As ".3" is currently shutdown and ".7" is in used
#
# 4/10/2011 - David Zhang
# Modified scripts to adjust smarts online servers move to global switch data centre. 
#   1) Adjusted IP addresses to the new GS for the servers in the backup list
#   2) Replaced backup user root with the user backup, which has a default password created at each backup source server
#   3) Due to backup user privilege change, added exclude option to rync for linux servers backup
#   4) Added capture of error messages when mount command fails to mount a windows sharing folder 
#   5) Modified email statement to add send html body in addition to the html attachment
# Revised permission error according to the backup result
# For linux source servers, root public key are distributed in order for rsync to proceed without asking for a password
# Added SCA_DFM backup coverage within the script. Previously, it was not backuped as as an exception to the server naming conventions
#
#17/04/2013 - Ultan Lankford
#Installed Mutt 1.5.21 from source.
#This will fix the issues of HTML attachments not being embeded in the emails
#
# 20/05/2013 - David Zhang
# Add new client PDS
#
# 9/8/2013 - David Zhang
# Minor adjustment to take the -z out (no compression during file transfer) from the rsync arg paramerter strings (RSYNC_ARGS) 
# This hopes to resolve below error encountered in the backup
#     Error!
#     inflate (token) returned -5
#     rsync error: error in rsync protocol data stream (code 12) at token.c(604) [receiver=3.0.6] rsync: connection unexpectedly closed (221 bytes received so far) [generator] rsync error: error in rsync protocol data stream (code 12) at io.c(600) [generator=3.0.6]
################################################################


DATE=$(date)
TIMESTAMP=$(date +%r)
TODAY=$(date +%d)
YESTERDAY=$(date -d 'yesterday' '+%d')
EMAIL="SMMS-OPS@nasdaqomx.com"
BACKUP_DEST="/backup/SMARTSOnline"
RULEGOOD="/root/scripts/smartsonline/headGood"
RULEBAD="/root/scripts/smartsonline/headBad"
PREPEND="/root/scripts/smartsonline/prepend.body.rules"

BACKUP_DEST="/backup/SMARTSOnline"
HISTORY="/backup/SMARTSOnline/history"
#RULEGOOD="/root/scripts/smartsonline/headGood"
#RULEBAD="/root/scripts/smartsonline/headBad"
#PREPEND="/root/scripts/smartsonline/prepend.body.rules"

# Client Network
#ADSM="10.169.64"
ADSM="10.30.100"
#DFM="10.169.68"
DFM="10.30.102"
#DIFX="192.168.136"
NSX="10.30.116"
NZX="10.30.114"
#PSE="10.169.76"
PSE="10.30.106"
#SCA="10.169.72"
SCA="10.30.104"
#SCA_DFM="10.169.72.14"
SCA_DFM="10.30.104.14"
PDS="10.30.112"

# Host details
APPS=linux
CLI=windows
CLI_IP=2
APPS_IP=3
GW_IP=4
CLIENT=""

### Help on Usage ###
USAGE= echo -e "
Usage: $0 [-C ClientName] [-g type] [-a type] [-r]

  -C - Client  Name of client [ADSM, DFM, NSX, NZX, PSE, DIFX, SCA, SCA_DFM]
  -g - GW      No defaults, needs to specify a host type for this command to work
  -a - APPS    Defaults to linux
  -p   PreChk  Will remove all necessary files before backup commence
  -r - Report  To produce an html report to an email recipient

Eg: $0 -C ADSM -g linux -a windows"

### OPTIONS ###

while getopts "C:g:a:pr" opt; do
      case $opt in
	  C ) CNAME=$OPTARG   ;;
	  g ) GW=$OPTARG      ;;
	  a ) APPS=$OPTARG    ;;
	  p ) PRECHECK=1      ;;
	  r ) REPORT=1	      ;;

         \? ) echo $USAGE
              exit 100	      ;;
      esac
done

shift $(($OPTIND - 1))

# Logs & MISC (Needs to be below OPTIONS because of $CNAME)
LOG="/backup/SMARTSOnline/$CNAME/logs/main.log"
ERRORLOG="/backup/SMARTSOnline/$CNAME/logs/error.log"
MAINERRORLOG="$HISTORY/$YESTERDAY/logs/mainerror.log"
MAINLOG="$HISTORY/$YESTERDAY/log/main.log"
LOGHTML="$HISTORY/$YESTERDAY/log/main.html"
FILL="/backup/SMARTSOnline/$CNAME/logs/fill.log"
RSYNC_ARGS="-e ssh -ax -S --numeric-ids --force --stats -h --backup --backup-dir $HISTORY/$YESTERDAY/$CNAME"
#RSYNC_ARGS="-e ssh -axz -S --numeric-ids --force --stats -h --backup --backup-dir $HISTORY/$YESTERDAY/$CNAME"
#RSYNC_ARGS="-e ssh -axz -S --numeric-ids --delete --force --stats -h --backup --backup-dir $HISTORY/$YESTERDAY/$CNAME"
RSYNC_EXCLUDE_FILE="/root/scripts/smartsonline/rsync_exclude_files.rules"


### FUNCTIONS ###

# Check the right folder to backup exists, else create
pre_check() {
	
	# Remove old logs / backup
	echo $YESTERDAY
	rm -rf $HISTORY/$YESTERDAY/*/*
	rm -f /backup/SMARTSOnline/*/logs/*
	rm -f $LOG && touch $LOG
	rm -f $MAINERRORLOG && touch $MAINERRORLOG

        [ -d "$BACKUP_DEST/$CNAME/logs" ] || mkdir -p $BACKUP_DEST/$CNAME/logs
        [ -d "$HISTORY/$YESTERDAY/logs" ] || mkdir -p $HISTORY/$YESTERDAY/logs
	echo $YESTERDAY
}

check() {
	# convert name to IP
	if [[ $CNAME = "ADSM" ]]; then
	    CLIENT=$ADSM
	  	elif [[ $CNAME = "DFM" ]]; then
		CLIENT=$DFM
	  	elif [[ $CNAME = "NSX" ]]; then
		CLIENT="$NSX"
	  	elif [[ $CNAME = "NZX" ]]; then
		CLIENT="$NZX"
	  	elif [[ $CNAME = "PSE" ]]; then
		CLIENT="$PSE"
	  	elif [[ $CNAME = "DIFX" ]]; then
		CLIENT="$DIFX"
	  	elif [[ $CNAME = "SCA" ]]; then
		CLIENT="$SCA"
                elif [[ $CNAME = "SCA_DFM" ]]; then
                CLIENT="$SCA_DFM"
                elif [[ $CNAME = "PDS" ]]; then
                CLIENT="$PDS"
	else
	     echo -e "\nNo such client "$CNAME"!"
	     exit 2
	fi
	
	# Write log
	echo -e "             $CNAME - $TYPE \n" >> $LOG
		# Create backup folder if missing
                [ -d /backup/SMARTSOnline/$CNAME/$TYPE ] || mkdir -p /backup/SMARTSOnline/$CNAME/$TYPE | \
                echo -e "*** /backup/SMARTSOnline/$CNAME/$TYPE folder was missing and had to be created!\n---" >> $LOG \
                && echo "$CNAME - $TYPE" >> $ERRORLOG
	echo -e "\n" >> $LOG
}

backup() {
	# Checks to see if its a windows
	if [[ $OS = "windows" ]]; then

	   mount -t cifs -ro username=backup,password=mpl4Smarts //$HOST/smarts /backup-mount/SMARTSOnline/ 2> $ERRORLOG
	   #mount -t cifs -ro username=backup,password=mpl4Smarts //$HOST/smarts /backup-mount/SMARTSOnline/ 1> $ERRORLOG 2> $ERRORLOG
           if [ $? = 0 ]; then
             rsync $RSYNC_ARGS/$TYPE /backup-mount/SMARTSOnline/ /backup/SMARTSOnline/$CNAME/$TYPE/ 1> $FILL 2> $ERRORLOG

             
             sleep 10

	     umount /backup-mount/SMARTSOnline/
           else
              echo -e "\nMount failure with /"$HOST"/smarts"
           fi

	else
           rsync $RSYNC_ARGS/$TYPE --exclude-from=${RSYNC_EXCLUDE_FILE} --delete-excluded backup@$HOST:/smarts /backup/SMARTSOnline/$CNAME/$TYPE/ 1> $FILL 2> $ERRORLOG
	fi
}

log_cut() {
	
     # Only update the first four lines of --stats if there are files to backup
     # If there are errors with connections, or copying post it with the report

	if [[ -s $FILL && $(cat $FILL | head -3 | tail -n+3 | cut -d' ' -f5) = 0 ]]; then
	    echo -e "\n           No new files to back up" >> $LOG
	    echo -e " _____________________________________________\n" >> $LOG
		
        elif [ -s $ERRORLOG ]; then	# Report Error
		     echo -e "\nError!" >> $LOG
		     cat $ERRORLOG >> $LOG
		     echo -e " _____________________________________________\n" >> $LOG
	
		else
	    	     head -5  $FILL >> $LOG
	    	     echo -e " _____________________________________________\n" >> $LOG
	fi
}

GW_BU() {
	TYPE="GW"
	check
	OS=$GW
	if [[ $CLIENT = $SCA_DFM ]]; then 
          HOST=$CLIENT
        else
 	  HOST=$CLIENT.$GW_IP # Needs to be in touch $LOG after check funct, otherwise $CLIENT will not be recognised
        fi
        if [ $CNAME = "DFM" -o $CNAME = "NZX"  -o $CNAME = "ADSM" -o $CNAME = "PDS" ]; then
           : Gateway and Backup server are on the same server since SMARTS has introduced since Release 6.3
           echo -e "Backup for $CNAME Gateway server is skpped because unneeded. \n"  >$FILL
           cat /dev/null  >$ERRORLOG
        else
      	   backup
        fi
	log_cut
}

APPS_BU() {
     if [[ $CLIENT = "$SCA_DFM" ]]; then 
       : SCA_DFM only has GW connection. Therefore, do nothing with Application server.
     else  
	TYPE="APPS"
	check
	OS=$APPS

        HOST=$CLIENT.$APPS_IP
        backup
        log_cut
    fi
}

collect() {
   LIST="ADSM DFM NSX NZX PSE SCA SCA_DFM PDS"
   for SERVER in $LIST
   do
     cat /backup/SMARTSOnline/$SERVER/logs/main.log >> $HISTORY/$YESTERDAY/logs/main.log
     cat /backup/SMARTSOnline/$SERVER/logs/error.log >> $HISTORY/$YESTERDAY/logs/mainerror.log
   done
}

htmllog() {
	if [ -s $MAINERRORLOG ]; then
    	   HEADER=$RULEBAD
	else
   	   HEADER=$RULEGOOD
	fi

echo "<h6>SMARTSOnline Backup Report - $DATE </h6>" > $PREPEND


txt2html \
--use_mosaic_header \
--append_head $HEADER \
--prepend_body $PREPEND \
-ct h2 \
--bold_delimiter '#' \
--body_deco ' bgcolor="white"' \
--infile $HISTORY/$YESTERDAY/logs/main.log --outfile $HISTORY/$YESTERDAY/logs/main.html
}

mail() {
	if [ -s $MAINERRORLOG ]; then
          # comment since the reinstalled mutt does not support set content_type  Feb 19, 2013 
	  # comment reinstalled mutt 1.5.21 which supports set content_type     Apr 17, 2013 - Ultan

	   mutt -e "set content_type=text/html" -s "BAD! - SMARTSOnline backup log" $EMAIL -a $HISTORY/$YESTERDAY/logs/main.html < $HISTORY/$YESTERDAY/logs/main.html
	
	#Can probably delete this line  
	# mutt  -s "BAD! - SMARTSOnline backup log" $EMAIL -a $HISTORY/$YESTERDAY/logs/main.html < /dev/null

	else
          # comment since the reinstalled mutt does not support set content_type  Feb 19, 2013 
	  # comment reinstalled mutt 1.5.21 which supports set content_type	Apr 17, 2013 - Ultan	

	   mutt -e "set content_type=text/html" -s "GOOD! - SMARTSOnline backup log" $EMAIL -a $HISTORY/$YESTERDAY/logs/main.html < $HISTORY/$YESTERDAY/logs/main.html
	
	#Can probably delete this line  
	#mutt -s "GOOD! - SMARTSOnline backup log" $EMAIL -a $HISTORY/$YESTERDAY/logs/main.html < /dev/null 
	fi
}


# Main
if [[ $PRECHECK = "1" ]]; then  # Remove/create dirs and logs
	pre_check
	exit 0

   elif [[ $REPORT != "1" ]]; then	# Backup data
	  GW_BU
          APPS_BU
else				
	collect			# Produce report
	htmllog
	mail
fi
