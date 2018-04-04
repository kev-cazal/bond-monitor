#!/usr/bin/env bash

##### SETTINGS #####

#All interfaces in the bond and the bond interface itself
IFACES="eth1 wlan1 bond0"

#The name of the bond interface
BOND="bond0"

#DEST is the IP/host that will be pinged in order to generate some traffic
#Unset this variable in order to not generate traffic with this script
DEST="192.168.1.1"

#Measurement interval in ping counts or seconds
INTERV=3

#The unit for the statistics (bytes, packets, ...)
UNIT="bytes"

##### Define functions #####

function get_stat () {
	#Returns network statistics for the specified interface
	#iface: eth0, eth1, bond0, etc...
	#way: rx, tx
	#type: bytes, packets, etc...

	iface=$1
	way=$2
	type=$3
	echo $(cat /sys/class/net/${iface}/statistics/${way}_${type})
}

function get_active_slave () {
	#Returns the name of the active interface on active/passive bond interface

	bond=$1
	echo $(cat /sys/class/net/${bond}/bonding/active_slave)
}


##### Main loop #####

while(true); do

	#Get statistics at t0
	rx0=""
	tx0=""
	for i in $IFACES; do
		rx0=$rx0','$(get_stat $i rx $UNIT)
		tx0=$tx0','$(get_stat $i tx $UNIT)
	done
	rx0=${rx0:1}
	tx0=${tx0:1}

	#Generate some traffic
	#This also define the time interval between t0 and t1.
	if [ -n $DEST ]; then 
		ping -c $INTERV $DEST 1>/dev/null
	else
		sleep $INTERV
	fi

	#Get statistics at t1
	rx1=""
	tx1=""
	for i in $IFACES; do
		rx1=$rx1','$(get_stat $i rx $UNIT)
		tx1=$tx1','$(get_stat $i tx $UNIT)
	done
	rx1=${rx1:1}
	tx1=${tx1:1}


	clear

	#Show the difference between t1 and t0
	k=1
	for i in $IFACES; do
		[ x$i = x$(get_active_slave $BOND) ] && i=$i" [active]"
		echo $i
		dRx=$(($(echo $rx1 | awk -F',' "{print \$$k}") - $(echo $rx0 | awk -F',' "{print \$$k}")))
		dTx=$(($(echo $tx1 | awk -F',' "{print \$$k}") - $(echo $tx0 | awk -F',' "{print \$$k}")))
		k=$((k+1))
		echo "ΔRx (in $UNIT):" $dRx
		echo "ΔTx (in $UNIT):" $dTx
		echo ""
	done


done
