#!/bin/bash

export PROJDIR=porecamp_usa
export PROJGRP=G-819124
export PROJCONF=${HOME}/.${PROJDIR}

export WORKDIR="${STOCKYARD}/${PROJDIR}"
export CORRALDIR="/corral-tacc/projects/${PROJDIR}"
export CORRAL_BASE=${CORRALDIR}/shared/
export WORK_BASE=${WORKDIR}/staging

CONTAINER_ROOT=${WORKDIR}/containers
TACC_ALBACORE_1_1_1=tacc_albacore_1.1.1-2017-05-26-0d20c97af8d1.img
TACC_ALBACORE_1_1_2=tacc_albacore_1.1.2-2017-06-01-9a92467ab3d4.img
TACC_ALBACORE_1_2_1=tacc_albacore_1.2.1-2017-06-02-641365ec15d7.img

export TACC_ALBACORE="${CONTAINER_ROOT}/${TACC_ALBACORE_1_1_2}"
export TACC_ALBACORE_VERS=1_1_2
export ALBA_CONFIG="/opt/albacore/r94_250bps_2d.cfg"
export ALBA_BATCH=4000
export THREADS=23
# Time budget for 60,000 5000bp fast5 files
export RUNTIME_PER_UNIT=2

# Baseline date for rsync, in seconds
export STARTDATE=$(date +%s -d"Fri Jun  2 08:00:00 CDT 2017")
# Target seconds between rsync runs
# 30 min
export RSYNC_REPEAT=$(echo "60 * 30" | bc)
# Delay in seconds before a file is considered to be done writing
# 5 min
export RSYNC_DELAY=$(echo "60 * 5" | bc)

# Test for root
if [ $(id -u) = 0 ]; then
   die "You are not Groot. Please don't run as root."
fi

# Logging
die(){
    echo "[FATAL] $1"
    exit 1
}
export -f die

warn(){
    echo "[WARNING] $1"
}
export -f warn

info(){
    echo "[INFO] $1"
}
export -f info

roundup1(){

	d=$(echo "($1+0.5)/1" | bc)

	if [ "$d" -lt "1" ]
	then
		d="1"
	fi
	echo $d

}
export -f roundup1

function check_installed {
	_CMD=$1
	type $_CMD >/dev/null 2>&1 || { die "I require $_CMD but it's not installed."; }
}

function check_path {
	_PATH=$1
	stat $_PATH >/dev/null 2>&1 || { die "Can't find or access $_PATH"; }
}

function get_container {

	_CONTAINER_NAME=$1
	CONTAINER_PATH=$WORKDIR/containers/$_CONTAINER_NAME
	check_path $CONTAINER_PATH
	echo "${CONTAINER_PATH}"
}

check_path "$WORKDIR"
# do not check for Corral on Hikari compute node
# check_path "$CORRALDIR"
