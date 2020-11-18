#!/bin/bash

##############################################################################
#Script to compare SMARTS builds of Production and Production Replicas Servers
#V1.0 by Ultan Lankford
###############################################################################
#Set parameters
DATE=$(date)
EMAIL="ultan.lankford@nasdaqomx.com"

REPLICA_CHECK_DIR="/root/scripts/smartsonline/replicacheck/replicalogdata"
DIFFLOG="diff.log"
TEMPLOG="temp.log"
BUILDLOG="smartsbuild.log"
FINALLOG="finallog.log"
FINALHTML="finallog.html"

PREPEND="/root/scripts/smartsonline/replicacheck/replicalogdata/prepend.body"
GHEADER="/root/scripts/smartsonline/replicacheck/headGood"
BHEADER="/root/scripts/smartsonline/replicacheck/headBad"

PRODLIST=("nsx-prod-apps" "nzx-prod-apps" "pds-prod-apps" "sca-prod-apps" "dfm-prod-apps" "pse-prod-apps" "pse-prod-gateway" "adx-prod-apps")
REPLICALIST=("nsx-prod-r-apps" "nzx-prod-r-apps" "pds-prod-r-apps" "sca-prod-r-apps" "dfm-prod-r-apps" "pse-prod-r-apps" "pse-prod-r-gateway" "adx-prod-r-apps" )


#Precheck
precheck()
{
rm -rf $REPLICA_CHECK_DIR/*
}


#Gather Data on Servers defined in Array Lists
gather_data()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com "rpm -qa | grep smarts | sort > /tmp/SmartsBuildInfo$PRODSERVER.log"
ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com "rpm -qa | grep smarts | sort > /tmp/SmartsBuildInfo$REPLICASERVER.log"
done
}


#Copy logs from remote SOL Servers to Nemesis1
copy_remote_logs()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
rsync -ae ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com:/tmp/SmartsBuildInfo$PRODSERVER.log $REPLICA_CHECK_DIR
rsync -ae ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com:/tmp/SmartsBuildInfo$REPLICASERVER.log $REPLICA_CHECK_DIR
done
}

#Compare files for differences
compare_diff()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
diff $REPLICA_CHECK_DIR/SmartsBuildInfo$PRODSERVER.log $REPLICA_CHECK_DIR/SmartsBuildInfo$REPLICASERVER.log >> $REPLICA_CHECK_DIR/$TEMPLOG 2>&1
cat $REPLICA_CHECK_DIR/$TEMPLOG
log_add
done
}

log_add()
{
if [ -s $REPLICA_CHECK_DIR/$TEMPLOG ]
then
	sed -i "1i Problem: Issue found with $REPLICASERVER  - See below" $REPLICA_CHECK_DIR/$TEMPLOG
	sed -i '2i ===================================================\n ' $REPLICA_CHECK_DIR/$TEMPLOG
	echo -e "<hr>" >> $REPLICA_CHECK_DIR/$TEMPLOG
	cat $REPLICA_CHECK_DIR/$TEMPLOG >> $REPLICA_CHECK_DIR/$DIFFLOG
	echo -e "\n" >> $REPLICA_CHECK_DIR/$DIFFLOG
	rm -rf $REPLICA_CHECK_DIR/$TEMPLOG
else
	:
fi
}

#Compare files for information
compare_info()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
echo -e "\nInfo: Comparing the" $PRODSERVER "and" $REPLICASERVER "SMARTS Build Server" >> $REPLICA_CHECK_DIR/$BUILDLOG 2>&1
echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $REPLICA_CHECK_DIR/$BUILDLOG 2>&1
diff -y $REPLICA_CHECK_DIR/SmartsBuildInfo$PRODSERVER.log $REPLICA_CHECK_DIR/SmartsBuildInfo$REPLICASERVER.log >> $REPLICA_CHECK_DIR/$BUILDLOG 2>&1
echo -e "\n_________________________________________________________\n" >> $REPLICA_CHECK_DIR/$BUILDLOG 2>&1
done
}

#Create an HTML output and log output of the data
create_logs()
{
if [ -s $REPLICA_CHECK_DIR/$DIFFLOG ]
then
	HEADER=$BHEADER
	echo "<h6>SMARTSOnline Replica Status Report - $DATE </h6>" > $PREPEND
	echo -e "<hr>\n" >> $PREPEND
	echo -e "\n<h5>\n Check Failed - See below</h5>\n\n" >> $PREPEND
	echo -e "<hr>\n" >> $PREPEND
	cat $REPLICA_CHECK_DIR/$DIFFLOG >> $REPLICA_CHECK_DIR/$FINALLOG
	cat $REPLICA_CHECK_DIR/$BUILDLOG >> $REPLICA_CHECK_DIR/$FINALLOG
	
else
	HEADER=$GHEADER
	echo "<h6>SMARTSOnline Replica Status Report - $DATE </h6>" > $PREPEND
	echo -e "<hr>\n" >> $PREPEND
	echo -e "\n<h5>\n Check Passed - No issues to report</h5>\n\n" >> $PREPEND
	echo -e "<hr>\n" >> $PREPEND
	cat $REPLICA_CHECK_DIR/$BUILDLOG >> $REPLICA_CHECK_DIR/$FINALLOG
fi

txt2html  --use_mosaic_header --append_head $HEADER --prepend_body $PREPEND --bold_delimiter '#' --body_deco ' bgcolor="white"' --infile $REPLICA_CHECK_DIR/$FINALLOG --outfile $REPLICA_CHECK_DIR/$FINALHTML
}


#Email results
email()
{
if [ -s $REPLICA_CHECK_DIR/$DIFFLOG ]
then
	mutt -e "set content_type=text/html" -s "BAD - Issue with Replica Status!" $EMAIL -a $REPLICA_CHECK_DIR/$FINALHTML < $REPLICA_CHECK_DIR/$FINALHTML
else
	mutt -e "set content_type=text/html" -s "GOOD - Production Replica Status is OK" $EMAIL -a $REPLICA_CHECK_DIR/$FINALHTML < $REPLICA_CHECK_DIR/$FINALHTML
fi
}


#Clean up logs on remote SOL servers
cleanup()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com "rm /tmp/SmartsBuildInfo$PRODSERVER.log"
ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com "rm /tmp/SmartsBuildInfo$REPLICASERVER.log"
done
}


#Main where functions defined above are called
precheck
gather_data
copy_remote_logs
compare_diff
compare_info
create_logs
email
cleanup
