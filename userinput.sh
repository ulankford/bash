#!/bin/bash
############################################################################
#Script to test user input for attributes
#V1.0 by Ultan Lankford
###############################################################################


EMAIL="ultan.lankford@nasdaqomx.com"
DATE=$(date)
DAY=$(date +%d)
MONTH=$(date +%m)
YEAR=$(date +%Y)
YESTERDAY=$(date -d 'yesterday' '+%d')
SMARTSDATE=$YEAR$MONTH$YESTERDAY


helpoutput()
{
echo "---------------------------------------------------------------------------------------------------------"
echo "---  This script can look for up to three variables. -m <MARKET> -d <DATE> -e <EMAIL>                 ---"
echo "---  MARKET variables will have to be one of the following <Nzx Nsx Pds Pse Adx Dfm Sca-Adx Sca-Dfm>  ---"
echo "---  DATE variable will have to be in the format of YEARMONTHDAY e.g. 20140217                        ---"
echo "---  EMAIL variable will have to be in the formate of username@nasdaqomx.com                          ---" 
echo "---                                                                                                   ---"
echo "---  If no variables are entered then the following defaults will apply.                              ---"
echo "---  -m <ALL MARKETS> -d <YESTERDAY> -e <ultan.lankford@nasdaqomx.com>                                ---"
echo "---------------------------------------------------------------------------------------------------------"
}


#The While loop checks for userinput for Market and Date to check for
while getopts ":m:d:e:h:" opt; do
	case $opt in
		m) echo "-m was triggered, Parameter: $OPTARG" >&2
			if [[ $OPTARG == nsx ]] ; then
			CNAME=$OPTARG 
			elif [[ $OPTARG == pds ]] ; then
			CNAME=$OPTARG 
			elif [[ $OPTARG == nzx ]] ; then
			CNAME=$OPTARG 
			elif [[ $OPTARG == pse ]] ; then
			echo "PSE not setup yet on SMARTS Market 6.4"
			echo "This script will not work for this market: Exiting!"
			exit 1
			#CNAME=$OPTARG 
			elif [[ $OPTARG == adx ]] ; then
			CNAME=$OPTARG 
			elif [[ $OPTARG == dfm ]] ; then
			CNAME=$OPTARG 
			elif [[ $OPTARG == sca-adx ]] ; then
			CNAME=$OPTARG 
			elif [[ $OPTARG == sca-dfm ]] ; then
			CNAME=$OPTARG 
			else
				echo "No valid Market entered: Exiting!"
				exit 1
			fi
			;;
			
		d) 	echo "-d was triggered, Parameter: $OPTARG" >&2 
			USERDATE=$OPTARG ;;
			
		e) 	echo "-e was triggered, Parameter: $OPTARG" >&2 
			USEREMAIL=$OPTARG ;;
			
		h)	helpoutput 
			if [[ -z $OPTARG ]] ; then
				helpoutput 
			else
				helpoutput 
			fi
			exit 1	;;
			
		\?) echo "Invalid option: -$OPTARG" >&2
			helpoutput 
			exit 1	;;
			
		:)	echo "Option -$OPTARG requires an argument." >&2 ;;
		
	if [[ $opt == h ]]; then
		helpoutput 
	else
		exit 1
	fi
	
	esac
done


#This will check the CNAME Variable and set it to the appropriate Array
if [[ $CNAME == nsx ]] ; then
	PRODLIST=("nsx-prod-apps")
	REPLICALIST=("nsx-prod-r-apps")
elif [[ $CNAME == nzx ]] ; then
	PRODLIST=("nzx-prod-apps")
	REPLICALIST=("nzx-prod-r-apps")
elif [[ $CNAME == pds ]] ; then
	PRODLIST=("nzx-prod-apps")
	REPLICALIST=("nzx-prod-r-apps")
elif [[ $CNAME == pse ]] ; then
	PRODLIST=("nzx-prod-apps")
	REPLICALIST=("nzx-prod-r-apps")
elif [[ $CNAME == adx ]] ; then
	PRODLIST=("nzx-prod-apps")
	REPLICALIST=("nzx-prod-r-apps")
elif [[ $CNAME == dfm ]] ; then
	PRODLIST=("nzx-prod-apps")
	REPLICALIST=("nzx-prod-r-apps")
elif [[ $CNAME == sca-adx ]] ; then
	PRODLIST=("sca-adx-prod-apps")
	REPLICALIST=("sca-adx-prod-r-apps")
elif [[ $CNAME == sca-dfm ]] ; then
	PRODLIST=("sca-dfm-prod-apps")
	REPLICALIST=("sca-dfm-prod-r-apps")
else
	PRODLIST=("sca-adx-prod-apps" "sca-dfm-prod-apps" "nsx-prod-apps" "nzx-prod-apps" "pds-prod-apps" "adx-prod-apps" "dfm-prod-apps")
	REPLICALIST=("sca-adx-prod-r-apps" "sca-dfm-prod-r-apps" "nsx-prod-r-apps" "nzx-prod-r-apps" "pds-prod-r-apps" "adx-prod-r-apps" "dfm-prod-r-apps")
fi

#Test Array
for i in "${!PRODLIST[@]}"
do
	PRODSERVER="${PRODLIST[$i]}"
	REPLICASERVER="${REPLICALIST[$i]}"
	echo "The PRODSERVER is" $PRODSERVER "and the REPLICASERVER is" $REPLICASERVER
done

#Check that the date is valid

#Arrange the output of the date
if [ -z $USERDATE ] ; then
	echo "The default date is yesterday" $SMARTSDATE
else
	echo "The user requested date is" $USERDATE
	SMARTSDATE=$USERDATE
fi

echo "The date to be used from now on is" $SMARTSDATE

#Get right email
if [ -z $USEREMAIL ] ; then
	echo "The default date is yesterday" $EMAIL
else
	echo "The user requested email to use is" $USEREMAIL
	EMAIL=$USEREMAIL
fi

echo "The email to use is" $EMAIL

	
	

