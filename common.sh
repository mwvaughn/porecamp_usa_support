#!/bin/bash

export PROJDIR=porecamp_usa
export PROJGRP=G-819124
export PROJCONF=${HOME}/.${PROJDIR}

export WORKDIR="${STOCKYARD}/${PROJDIR}"
export CORRALDIR="/corral-tacc/projects/${PROJDIR}"
export CORRAL_BASE=${CORRALDIR}/scratch/
export WORK_BASE=${WORKDIR}/staging

CONTAINER_ROOT=${WORKDIR}/containers
TACC_ALBACORE_1_1_1=tacc_albacore_1.1.1-2017-05-26-0d20c97af8d1.img
TACC_ALBACORE_1_1_2=tacc_albacore_1.1.2-2017-06-01-9a92467ab3d4.img
TACC_ALBACORE_1_2_1=tacc_albacore_1.2.1-2017-06-02-641365ec15d7.img

export THREADS=23
export TACC_ALBACORE="${CONTAINER_ROOT}/${TACC_ALBACORE_1_1_2}"
export TACC_ALBACORE_VERS=1_1_2
export ALBA_CONFIG="/opt/albacore/r95_450bps_linear.cfg"
export ALBA_BATCH=4000
export ALBA_BARCODE="--barcoding"
export ALBA_FORMAT="fastq,fast5"
export ALBA_RECURSIVE="--recursive"
export ALBA_EXTRA_OPTS=""

# Baseline date for rsync, in seconds
export STARTDATE=$(date +%s -d"Mon Jun  5 17:00:00 CDT 2017")
# Target seconds between rsync runs
# 15 min
export RSYNC_REPEAT=$(echo "60 * 15" | bc)
# Delay in seconds before a file is considered to be done writing
# 2 min
export RSYNC_DELAY=$(echo "60 * 2" | bc)

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

# Makes a directory and tries really hard to make it group readable
mkdir_pems(){

	# Check for existence first because while mkdir -p is imdepotent, the
	# permissions operations are not and are thus expensive
	if [ ! -d $1 ]
	then
		mkdir -p $1 && chgrp ${PROJGRP} $1 && chmod g+srwx,o+rx,u+rwx $1
	fi

}
export -f mkdir_pems

check_path "$WORKDIR"
# do not check for Corral on Hikari compute node
# check_path "$CORRALDIR"
