#!/bin/bash

##############################################################################
#Script to compare SMARTS builds of Production and Production Replicas Servers
#V1.0 by Ultan Lankford
###############################################################################

#Set parameters
EMAIL="ultan.lankford@nasdaqomx.com"
DATE=$(date)
DAY=$(date +%d)
MONTH=$(date +%m)
YEAR=$(date +%Y)
YESTERDAY=$(date -d 'yesterday' '+%d')
SMARTSDATE=$YEAR$MONTH$YESTERDAY

SMARTS_CHECK_DIR="/root/scripts/smartsonline/smartspatchcheck/smartslogdata"
BUILDLOG="smartscheck.log"
TEMPGREP="tempgrep.log"
INFOLOG="infolog.log"
FINALHTML="finallog.html"

GHEADER="/root/scripts/smartsonline/smartspatchcheck/headGood"
BHEADER="/root/scripts/smartsonline/smartspatchcheck/headBad"
PREPEND="/root/scripts/smartsonline/smartspatchcheck/smartslogdata/prepend.body"

PRODLIST=("sca-adx-prod-apps" "sca-dfm-prod-apps" "nsx-prod-apps" "nzx-prod-apps" "pds-prod-apps" "adx-prod-apps" "dfm-prod-apps")
REPLICALIST=("sca-adx-prod-r-apps" "sca-dfm-prod-r-apps" "nsx-prod-r-apps" "nzx-prod-r-apps" "pds-prod-r-apps" "adx-prod-r-apps" "dfm-prod-r-apps")

#Precheck will delete all old log files
precheck()
{
find $SMARTS_CHECK_DIR/ -maxdepth 2 -type f -exec rm -f {} \;
}

client_id()
{
if [ "$PRODSERVER" = "sca-adx-prod-apps" ]; then
		CLIENT=$(echo $PRODSERVER | cut -c5-7)
	elif [ "$PRODSERVER" = "sca-dfm-prod-apps" ]; then
		CLIENT=$(echo $PRODSERVER | cut -c5-7)
	else
		CLIENT=$(echo $PRODSERVER | cut -c1-3)
fi
}

client_id_compare()
{
if [ "$PRODSERVER" = "sca-adx-prod-apps" ]; then
		CLIENT=$(echo $PRODSERVER | cut -c1-7)
	elif [ "$PRODSERVER" = "sca-dfm-prod-apps" ]; then
		CLIENT=$(echo $PRODSERVER | cut -c1-7)
	else
		CLIENT=$(echo $PRODSERVER | cut -c1-3)
fi
}


ssh_sca_gather_favsize()
{
ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com "ls -alh /smarts/data/$CLIENT/track/$YEAR/$MONTH | grep $SMARTSDATE > /tmp/SmartsFAVSize$SCAPRODSERVER.log"
ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com "ls -alh /smarts/data/$CLIENT/track/$YEAR/$MONTH | grep $SMARTSDATE > /tmp/SmartsFAVSize$SCAREPLICASERVER.log"
}

ssh_sca_gather_favop()
{
ssh -t backup@$PRODSERVER.sol.smms.nasdaqomx.com "sudo /smarts/builds/latest-core/bin/favop tot -m $CLIENT $SMARTSDATE > /tmp/SmartsFAVOPTOT$SCAPRODSERVER.log 2>&1"
ssh -t backup@$REPLICASERVER.sol.smms.nasdaqomx.com "sudo /smarts/builds/latest-core/bin/favop tot -m $CLIENT $SMARTSDATE > /tmp/SmartsFAVOPTOT$SCAREPLICASERVER.log 2>&1" 
}

ssh_sca_gather_alerts()
{
ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com "cat /smarts/data/$CLIENT/alerts/$YEAR/$MONTH/$SMARTSDATE.als/$SMARTSDATE.alerts | grep AL | wc -l > /tmp/SmartsAlerts$SCAPRODSERVER.log"
ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com "cat /smarts/data/$CLIENT/alerts/$YEAR/$MONTH/$SMARTSDATE.als/$SMARTSDATE.alerts | grep AL | wc -l > /tmp/SmartsAlerts$SCAREPLICASERVER.log"
}

rsync_sca_gather()
{
rsync -ae ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com:/tmp/Smarts{Alerts,FAVOPTOT,FAVSize}$SCAPRODSERVER.log $SMARTS_CHECK_DIR
rsync -ae ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com:/tmp/Smarts{Alerts,FAVOPTOT,FAVSize}$SCAREPLICASERVER.log $SMARTS_CHECK_DIR
}


#Gather SMARTS FAV Size
Gather_fav_size()
{
for i in "${!PRODLIST[@]}"
do
	PRODSERVER="${PRODLIST[$i]}"
	REPLICASERVER="${REPLICALIST[$i]}"
		if [ "$PRODSERVER" = "sca-adx-prod-apps" ]; then
			SCAPRODSERVER=$PRODSERVER
			SCAREPLICASERVER=$REPLICASERVER
			client_id
			PRODSERVER="sca-prod-apps"
			REPLICASERVER="sca-prod-r-apps"
			ssh_sca_gather_favsize
		elif [ "$PRODSERVER" = "sca-dfm-prod-apps" ]; then
			SCAPRODSERVER=$PRODSERVER
			SCAREPLICASERVER=$REPLICASERVER
			client_id
			PRODSERVER="sca-prod-apps"
			REPLICASERVER="sca-prod-r-apps"
			ssh_sca_gather_favsize
		else
			PRODSERVER="${PRODLIST[$i]}"
			REPLICASERVER="${REPLICALIST[$i]}"
			client_id
			ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com "ls -alh /smarts/data/$CLIENT/track/$YEAR/$MONTH | grep $SMARTSDATE > /tmp/SmartsFAVSize$PRODSERVER.log"
			ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com "ls -alh /smarts/data/$CLIENT/track/$YEAR/$MONTH | grep $SMARTSDATE > /tmp/SmartsFAVSize$REPLICASERVER.log"
	fi
done
}

#Gather SMARTS FAVOP TOT Data
Gather_favtot_data()
{
for i in "${!PRODLIST[@]}"
do
	PRODSERVER="${PRODLIST[$i]}"
	REPLICASERVER="${REPLICALIST[$i]}"
		if [ "$PRODSERVER" = "sca-adx-prod-apps" ]; then
			SCAPRODSERVER=$PRODSERVER
			SCAREPLICASERVER=$REPLICASERVER
			client_id
			PRODSERVER="sca-prod-apps"
			REPLICASERVER="sca-prod-r-apps"
			ssh_sca_gather_favop
		elif [ "$PRODSERVER" = "sca-dfm-prod-apps" ]; then
			SCAPRODSERVER=$PRODSERVER
			SCAREPLICASERVER=$REPLICASERVER
			client_id
			PRODSERVER="sca-prod-apps"
			REPLICASERVER="sca-prod-r-apps"
			ssh_sca_gather_favop
		else
			PRODSERVER="${PRODLIST[$i]}"
			REPLICASERVER="${REPLICALIST[$i]}"
			client_id
			ssh -t backup@$PRODSERVER.sol.smms.nasdaqomx.com "sudo /smarts/builds/latest-core/bin/favop tot -m $CLIENT $SMARTSDATE > /tmp/SmartsFAVOPTOT$PRODSERVER.log 2>&1"
			ssh -t backup@$REPLICASERVER.sol.smms.nasdaqomx.com "sudo /smarts/builds/latest-core/bin/favop tot -m $CLIENT $SMARTSDATE > /tmp/SmartsFAVOPTOT$REPLICASERVER.log 2>&1" 
	fi
done
}

#Gather SMARTS Alerts
Gather_alerts_data()
{
for i in "${!PRODLIST[@]}"
do
	PRODSERVER="${PRODLIST[$i]}"
	REPLICASERVER="${REPLICALIST[$i]}"
		if [ "$PRODSERVER" = "sca-adx-prod-apps" ]; then
			SCAPRODSERVER=$PRODSERVER
			SCAREPLICASERVER=$REPLICASERVER
			client_id
			PRODSERVER="sca-prod-apps"
			REPLICASERVER="sca-prod-r-apps"
			ssh_sca_gather_alerts
		elif [ "$PRODSERVER" = "sca-dfm-prod-apps" ]; then
			SCAPRODSERVER=$PRODSERVER
			SCAREPLICASERVER=$REPLICASERVER
			client_id
			PRODSERVER="sca-prod-apps"
			REPLICASERVER="sca-prod-r-apps"
			ssh_sca_gather_alerts
		else
			PRODSERVER="${PRODLIST[$i]}"
			REPLICASERVER="${REPLICALIST[$i]}"
			client_id
			ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com "cat /smarts/data/$CLIENT/alerts/$YEAR/$MONTH/$SMARTSDATE.als/$SMARTSDATE.alerts | grep AL | wc -l > /tmp/SmartsAlerts$PRODSERVER.log"
			ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com "cat /smarts/data/$CLIENT/alerts/$YEAR/$MONTH/$SMARTSDATE.als/$SMARTSDATE.alerts | grep AL | wc -l > /tmp/SmartsAlerts$REPLICASERVER.log"
	fi
done
}

#Copy all logs from remote SOL Servers to Nemesis1
copy_remote_logs()
{
for i in "${!PRODLIST[@]}"
	do
		PRODSERVER="${PRODLIST[$i]}"
		REPLICASERVER="${REPLICALIST[$i]}"
		if [ "$PRODSERVER" = "sca-adx-prod-apps" ]; then
			SCAPRODSERVER=$PRODSERVER
			SCAREPLICASERVER=$REPLICASERVER
			PRODSERVER="sca-prod-apps"
			REPLICASERVER="sca-prod-r-apps"
			rsync_sca_gather
		elif [ "$PRODSERVER" = "sca-dfm-prod-apps" ]; then
			SCAPRODSERVER=$PRODSERVER
			SCAREPLICASERVER=$REPLICASERVER
			PRODSERVER="sca-prod-apps"
			REPLICASERVER="sca-prod-r-apps"
			rsync_sca_gather
		else
			PRODSERVER="${PRODLIST[$i]}"
			REPLICASERVER="${REPLICALIST[$i]}"
			rsync -ae ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com:/tmp/Smarts{Alerts,FAVOPTOT,FAVSize}$PRODSERVER.log $SMARTS_CHECK_DIR
			rsync -ae ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com:/tmp/Smarts{Alerts,FAVOPTOT,FAVSize}$REPLICASERVER.log $SMARTS_CHECK_DIR
	fi
done
}

#Compare FAV Size
compare_fav_size()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
client_id_compare
diff $SMARTS_CHECK_DIR/SmartsFAVSize$PRODSERVER.log $SMARTS_CHECK_DIR/SmartsFAVSize$REPLICASERVER.log >> $SMARTS_CHECK_DIR/"$CLIENT"FAVSize.log 2>&1
	if [ -s $SMARTS_CHECK_DIR/"$CLIENT"FAVSize.log ]
	then
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVSizeBad.flag
	else
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVSizeGood.flag
	fi
done
}

#Compare Alert Data
compare_alerts()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
client_id_compare
diff $SMARTS_CHECK_DIR/SmartsAlerts$PRODSERVER.log $SMARTS_CHECK_DIR/SmartsAlerts$REPLICASERVER.log >> $SMARTS_CHECK_DIR/"$CLIENT"Alerts.log 2>&1
if [ -s $SMARTS_CHECK_DIR/"$CLIENT"Alerts.log ]
	then
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"AlertsBad.flag
	else
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"AlertsGood.flag
	fi
done
}

#Cut FAVOPTOT Data down to relevant portions to make easier differentiation
cut_favoptot_amend()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
grep -A5 "FAV AMEND" $SMARTS_CHECK_DIR/SmartsFAVOPTOT$PRODSERVER.log  >> $SMARTS_CHECK_DIR/FAVOPTOTCutAmend$PRODSERVER.log 
grep -A5 "FAV AMEND" $SMARTS_CHECK_DIR/SmartsFAVOPTOT$REPLICASERVER.log  >> $SMARTS_CHECK_DIR/FAVOPTOTCutAmend$REPLICASERVER.log 
done
}

cut_favoptot_enter()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
grep -A5 "FAV ENTER" $SMARTS_CHECK_DIR/SmartsFAVOPTOT$PRODSERVER.log  >> $SMARTS_CHECK_DIR/FAVOPTOTCutEnter$PRODSERVER.log
grep -A5 "FAV ENTER" $SMARTS_CHECK_DIR/SmartsFAVOPTOT$REPLICASERVER.log  >> $SMARTS_CHECK_DIR/FAVOPTOTCutEnter$REPLICASERVER.log 
done
}

cut_favoptot_delet()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
grep -A5 "FAV DELET" $SMARTS_CHECK_DIR/SmartsFAVOPTOT$PRODSERVER.log  >> $SMARTS_CHECK_DIR/FAVOPTOTCutDelet$PRODSERVER.log
grep -A5 "FAV DELET" $SMARTS_CHECK_DIR/SmartsFAVOPTOT$REPLICASERVER.log  >> $SMARTS_CHECK_DIR/FAVOPTOTCutDelet$REPLICASERVER.log 
done
}

cut_favoptot_cantr()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
grep -A5 "FAV CANTR" $SMARTS_CHECK_DIR/SmartsFAVOPTOT$PRODSERVER.log  >> $SMARTS_CHECK_DIR/FAVOPTOTCutCantr$PRODSERVER.log
grep -A5 "FAV CANTR" $SMARTS_CHECK_DIR/SmartsFAVOPTOT$REPLICASERVER.log  >> $SMARTS_CHECK_DIR/FAVOPTOTCutCantr$REPLICASERVER.log 
done
}

cut_favoptot_trade()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
grep -A5 "FAV TRADE" $SMARTS_CHECK_DIR/SmartsFAVOPTOT$PRODSERVER.log  >> $SMARTS_CHECK_DIR/FAVOPTOTCutTrade$PRODSERVER.log
grep -A5 "FAV TRADE" $SMARTS_CHECK_DIR/SmartsFAVOPTOT$REPLICASERVER.log  >> $SMARTS_CHECK_DIR/FAVOPTOTCutTrade$REPLICASERVER.log 
done
}

#Call all smaller favoptot functions
cut_favoptot_data()
{
cut_favoptot_amend
cut_favoptot_enter
cut_favoptot_delet
cut_favoptot_cantr
cut_favoptot_trade
}

#Compare FAVOPTOT Data
compare_favoptot_trade()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
client_id_compare
diff $SMARTS_CHECK_DIR/FAVOPTOTCutTrade$PRODSERVER.log $SMARTS_CHECK_DIR/FAVOPTOTCutTrade$REPLICASERVER.log >> $SMARTS_CHECK_DIR/"$CLIENT"FAVOPTOTTrade.log 2>&1
if [ -s $SMARTS_CHECK_DIR/"$CLIENT"FAVOPTOTTrade.log ]
	then
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTTradeBad.flag
	else
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTTradeGood.flag
	fi
done
}

compare_favoptot_cantr()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
client_id_compare
diff $SMARTS_CHECK_DIR/FAVOPTOTCutCantr$PRODSERVER.log $SMARTS_CHECK_DIR/FAVOPTOTCutCantr$REPLICASERVER.log >> $SMARTS_CHECK_DIR/"$CLIENT"FAVOPTOTCantr.log 2>&1
if [ -s $SMARTS_CHECK_DIR/"$CLIENT"FAVOPTOTCantr.log ]
	then
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTCantrBad.flag
	else
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTCantrGood.flag
	fi
done
}

compare_favoptot_delet()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
client_id_compare
diff $SMARTS_CHECK_DIR/FAVOPTOTCutDelet$PRODSERVER.log $SMARTS_CHECK_DIR/FAVOPTOTCutDelet$REPLICASERVER.log >> $SMARTS_CHECK_DIR/"$CLIENT"FAVOPTOTDelet.log 2>&1
if [ -s $SMARTS_CHECK_DIR/"$CLIENT"FAVOPTOTDelet.log ]
	then
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTDeletBad.flag
	else
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTDeletGood.flag
	fi
done
}


compare_favoptot_enter()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
client_id_compare
diff $SMARTS_CHECK_DIR/FAVOPTOTCutEnter$PRODSERVER.log $SMARTS_CHECK_DIR/FAVOPTOTCutEnter$REPLICASERVER.log >> $SMARTS_CHECK_DIR/"$CLIENT"FAVOPTOTEnter.log 2>&1
if [ -s $SMARTS_CHECK_DIR/"$CLIENT"FAVOPTOTEnter.log ]
	then
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTEnterBad.flag
	else
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTEnterGood.flag
	fi
done
}


compare_favoptot_amend()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
client_id_compare
diff $SMARTS_CHECK_DIR/FAVOPTOTCutAmend$PRODSERVER.log $SMARTS_CHECK_DIR/FAVOPTOTCutAmend$REPLICASERVER.log >> $SMARTS_CHECK_DIR/"$CLIENT"FAVOPTOTAmend.log 2>&1
if [ -s $SMARTS_CHECK_DIR/"$CLIENT"FAVOPTOTAmend.log ]
	then
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTAmendBad.flag
	else
		touch $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTAmendGood.flag
	fi
done
}


#Call all smaller compare_favoptot functions
compare_favoptot_data()
{
compare_favoptot_trade
compare_favoptot_amend
compare_favoptot_enter
compare_favoptot_delet
compare_favoptot_cantr
}

#Create Master Text file Log and check log
create_text_log()
{
for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"
client_id_compare
MAINCLIENT=$(echo $CLIENT | tr [a-z] [A-Z])

if [ -e $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTAmendGood.flag ]
	then
			PARA1=$(echo $MAINCLIENT " FAVOP TOT Amend Status is Good ")
		else
			PARA1=$(echo $MAINCLIENT " FAVOP TOT Amend Status  is Bad ")
	fi
	
if [ -e $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTDeletGood.flag ]
	then
			PARA2=$(echo $MAINCLIENT "FAVOP TOT Delete Status Good ")
		else
			PARA2=$(echo $MAINCLIENT "FAVOP TOT Delete Status Bad ")
	fi

if [ -e $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTEnterGood.flag ]
	then
			PARA3=$(echo $MAINCLIENT " FAVOP TOT Enter Status is Good ")
		else
			PARA3=$(echo $MAINCLIENT " FAVOP TOT Enter Status is Bad ")
	fi

if [ -e $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTCantrGood.flag ]
	then
			PARA4=$(echo $MAINCLIENT " FAVOP TOT Cantr Status is Good ")
		else
			PARA4=$(echo $MAINCLIENT " FAVOP TOT Cantr is Bad ")
	fi

if [ -e $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVOPTOTTradeGood.flag ]
	then
			PARA5=$(echo $MAINCLIENT " FAVOP TOT Trade Status is Good ")
		else
			PARA5=$(echo $MAINCLIENT " FAVOP TOT Trade Status is Bad ")
	fi

if [ -e $SMARTS_CHECK_DIR/flags/"$CLIENT"AlertsGood.flag ]
	then
			PARA6=$(echo $MAINCLIENT " Alerts Status is Good ")
		else
			PARA6=$(echo $MAINCLIENT " Alerts Status is Bad ")
	fi

if [ -e $SMARTS_CHECK_DIR/flags/"$CLIENT"FAVSizeGood.flag ]
	then
			PARA7=$(echo $MAINCLIENT " FAV Size is Good ")
		else
			PARA7=$(echo $MAINCLIENT " FAV Size is Bad ")
	fi
	
#echo -e "| Servers in Question  |  Check Result Status  |" >> $SMARTS_CHECK_DIR/$BUILDLOG 2>&1
echo -e "|   Results for  " $PRODSERVER "and" $REPLICASERVER "  |  $PARA1  |" >> $SMARTS_CHECK_DIR/$BUILDLOG 2>&1
echo -e "|   Results for  " $PRODSERVER "and" $REPLICASERVER "  |  $PARA2  |" >> $SMARTS_CHECK_DIR/$BUILDLOG 2>&1
echo -e "|   Results for  " $PRODSERVER "and" $REPLICASERVER "  |  $PARA3  |" >> $SMARTS_CHECK_DIR/$BUILDLOG 2>&1
echo -e "|   Results for  " $PRODSERVER "and" $REPLICASERVER "  |  $PARA4  |" >> $SMARTS_CHECK_DIR/$BUILDLOG 2>&1
echo -e "|   Results for  " $PRODSERVER "and" $REPLICASERVER "  |  $PARA5  |" >> $SMARTS_CHECK_DIR/$BUILDLOG 2>&1
echo -e "|   Results for  " $PRODSERVER "and" $REPLICASERVER "  |  $PARA6  |" >> $SMARTS_CHECK_DIR/$BUILDLOG 2>&1
echo -e "|   Results for  " $PRODSERVER "and" $REPLICASERVER "  |  $PARA7  |" >> $SMARTS_CHECK_DIR/$BUILDLOG 2>&1
echo -e "|   |   |"   >> $SMARTS_CHECK_DIR/$BUILDLOG 2>&1
done
}


#add headers to the log file and add informational text to log
extra_info()
{
sed -i "1i  |  Environment   |   Check Result Status   |" $SMARTS_CHECK_DIR/$BUILDLOG

for i in "${!PRODLIST[@]}"
do
PRODSERVER="${PRODLIST[$i]}"
REPLICASERVER="${REPLICALIST[$i]}"

echo -e "\nFAVOP TOT Amend result for" $PRODSERVER "and" $REPLICASERVER "servers" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
diff -y $SMARTS_CHECK_DIR/FAVOPTOTCutAmend$PRODSERVER.log $SMARTS_CHECK_DIR/FAVOPTOTCutAmend$REPLICASERVER.log >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "\n___________________________________________________________\n" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1

echo -e "\nFAVOP TOT Delete result for" $PRODSERVER "and" $REPLICASERVER "servers" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
diff -y $SMARTS_CHECK_DIR/FAVOPTOTCutDelet$PRODSERVER.log $SMARTS_CHECK_DIR/FAVOPTOTCutDelet$REPLICASERVER.log >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "\n___________________________________________________________\n" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1

echo -e "\nFAVOP TOT Enter result for" $PRODSERVER "and" $REPLICASERVER "servers" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
diff -y $SMARTS_CHECK_DIR/FAVOPTOTCutEnter$PRODSERVER.log $SMARTS_CHECK_DIR/FAVOPTOTCutEnter$REPLICASERVER.log >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "\n___________________________________________________________\n" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1

echo -e "\nFAVOP TOT Cantr result for" $PRODSERVER "and" $REPLICASERVER "servers" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
diff -y $SMARTS_CHECK_DIR/FAVOPTOTCutCantr$PRODSERVER.log $SMARTS_CHECK_DIR/FAVOPTOTCutCantr$REPLICASERVER.log >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "\n___________________________________________________________\n" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1

echo -e "\nFAVOP TOT Trade result for" $PRODSERVER "and" $REPLICASERVER "servers" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
diff -y $SMARTS_CHECK_DIR/FAVOPTOTCutTrade$PRODSERVER.log $SMARTS_CHECK_DIR/FAVOPTOTCutTrade$REPLICASERVER.log >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "\n___________________________________________________________\n" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1

echo -e "\nResult for number of Alerts for" $PRODSERVER "and" $REPLICASERVER "servers" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
diff -y $SMARTS_CHECK_DIR/SmartsAlerts$PRODSERVER.log $SMARTS_CHECK_DIR/SmartsAlerts$REPLICASERVER.log >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "\n___________________________________________________________\n" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1

echo -e "\nFAV Size result for" $PRODSERVER "and" $REPLICASERVER "servers" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
diff -y $SMARTS_CHECK_DIR/SmartsFAVSize$PRODSERVER.log $SMARTS_CHECK_DIR/SmartsFAVSize$REPLICASERVER.log >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1
echo -e "\n___________________________________________________________\n" >> $SMARTS_CHECK_DIR/$INFOLOG 2>&1

done
}


#Header choice
change_header()
{
grep -i "bad" $SMARTS_CHECK_DIR/$BUILDLOG > $SMARTS_CHECK_DIR/$TEMPGREP

if [ -s $SMARTS_CHECK_DIR/$TEMPGREP ]
	then
		HEADER=$BHEADER
		echo "<h6>SMARTSOnline Replica Status Report BAD - $DATE </h6>" > $PREPEND
		echo -e "<hr>\n" >> $PREPEND
		echo -e "\n<h5>\n Check Failed for $SMARTSDATE - See below table</h5>\n\n" >> $PREPEND
		echo -e "<hr>\n" >> $PREPEND
	
	else
		HEADER=$GHEADER
		echo "<h6>SMARTSOnline Replica Status Report GOOD - $DATE </h6>" > $PREPEND
		echo -e "<hr>\n" >> $PREPEND
		echo -e "\n<h5>\n Check Passed for $SMARTSDATE - No issues to report</h5>\n\n" >> $PREPEND
		echo -e "<hr>\n" >> $PREPEND
	fi
cat $SMARTS_CHECK_DIR/$INFOLOG >> $SMARTS_CHECK_DIR/$BUILDLOG
}

#Create the HTML file from the text file
create_html_log()
{
extra_info
change_header
txt2html  --use_mosaic_header --append_head $HEADER --prepend_body $PREPEND --make_tables --bold_delimiter '#' --body_deco ' bgcolor="white"' --infile $SMARTS_CHECK_DIR/$BUILDLOG --outfile $SMARTS_CHECK_DIR/$FINALHTML
}

#Edit HTML Output to improve the look of the report
edit_html_output()
{
sed -ir '/\bEnvironment\b/s/<td>/<td bgcolor="#D0D0D0" align="center">/g' $SMARTS_CHECK_DIR/$FINALHTML
sed -ir '/\bGood\b/s/<td>/<td bgcolor="#A7C942">/2' $SMARTS_CHECK_DIR/$FINALHTML
sed -ir '/\bBad\b/s/<td>/<td bgcolor="#CC0000">/2' $SMARTS_CHECK_DIR/$FINALHTML
#sed -ir '/\bResults\b/s/<td>/<td bgcolor="#A7C942">/g' $SMARTS_CHECK_DIR/$FINALHTML
sed -ir '/\btable border\b/s/<table border="1" summary="">/<table border="1" summary="" align="center" cellpadding="10">/g' $SMARTS_CHECK_DIR/$FINALHTML
}

#Email the final data
email()
{
edit_html_output
mutt -e "set content_type=text/html" -s "SMARTS Post Patch Integrity Check" $EMAIL -a $SMARTS_CHECK_DIR/$FINALHTML < $SMARTS_CHECK_DIR/$FINALHTML
}


sca_cleanup()
{
ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com "rm -rf /tmp/Smarts{Alerts,FAVOPTOT,FAVSize}$SCAPRODSERVER.log"
ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com "rm -rf /tmp/Smarts{Alerts,FAVOPTOT,FAVSize}$SCAREPLICASERVER.log"
}


#Clean up data on Remote Servers
cleanup()
{
for i in "${!PRODLIST[@]}"
do
	PRODSERVER="${PRODLIST[$i]}"
	REPLICASERVER="${REPLICALIST[$i]}"
		if [ "$PRODSERVER" = "sca-adx-prod-apps" ]; then
			SCAPRODSERVER=$PRODSERVER
			SCAREPLICASERVER=$REPLICASERVER
			PRODSERVER="sca-prod-apps"
			REPLICASERVER="sca-prod-r-apps"
			sca_cleanup
		elif [ "$PRODSERVER" = "sca-dfm-prod-apps" ]; then
			SCAPRODSERVER=$PRODSERVER
			SCAREPLICASERVER=$REPLICASERVER
			PRODSERVER="sca-prod-apps"
			REPLICASERVER="sca-prod-r-apps"
			sca_cleanup
		else
			PRODSERVER="${PRODLIST[$i]}"
			REPLICASERVER="${REPLICALIST[$i]}"
			ssh backup@$PRODSERVER.sol.smms.nasdaqomx.com "rm -rf /tmp/Smarts{Alerts,FAVOPTOT,FAVSize}$PRODSERVER.log"
			ssh backup@$REPLICASERVER.sol.smms.nasdaqomx.com "rm -rf /tmp/Smarts{Alerts,FAVOPTOT,FAVSize}$REPLICASERVER.log"
	fi
done
}


#call all functions in relevant order
precheck
Gather_fav_size
Gather_favtot_data
Gather_alerts_data
copy_remote_logs
compare_alerts
compare_fav_size
cut_favoptot_data
compare_favoptot_data
create_text_log
create_html_log
email
cleanup
