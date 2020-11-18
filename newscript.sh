#!/bin/bash
##############################################################################
#Script to test user input for attributes
#V1.0 by Ultan Lankford
###############################################################################

echo "----------------------------------------------------"
echo "This program will look for ask for two variables. <MARKET> and <DATE>"
echo "MARKET variables will have to be one of the following."
echo "Nzx, Nsx, Pds, Pse, Adx, Dfm, Sca-Adx, Sca-Dfm"
echo -n "Market is : "
read market
if [[ $makret = "nzx" ]]; then
	echo "Run code for NZX"
elif [[ $market = "nsx" ]]; then
	echo "Run code for NSX"
elif [[ $market = "pds" ]]; then
	echo "Run code for PDS"
elif [[ $market = "adx" ]]; then
	echo "Run code for ADX"
elif [[ $market = "dfm" ]]; then
	echo "Run code for DFM"
elif [[ $market = "sca-adx" ]]; then
	echo "Run code for ADX"
elif [[ $market = "sca-dfm" ]]; then
	echo "Run code for DFM"
elif [[ -z "$market" ]]; then
	echo "NO arguments supplied"
fi
