#!/usr/bin/env bash

# Assumptions

# inbound: corral/scratch/MACHINE
# parameterize 01_sync_process by passing in $1 as MACHINE
# configs per machine are stored in scripts/MACHINE.sh

# processing: WORK/staging/MACHINE/RUN
# 	states: $CPDEST/.job.lock indicates that the directory is being processed
# 	states: $CPDEST/.job.sync indicates that the directory is has been called and is ready to sync out

# find $WORK_BASE/$MACHINE/$RUNDIR/.job.sync Walk up two directories.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

IGNORE_LOCK=1
#_DRYRUN="-n"
_DRYRUN=

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

CORRAL_DEST="${CORRALDIR}/outputs"
CWD=$(pwd)
cd $WORK_BASE

exit 0

find . -type f -name "*.job.sync" -exec readlink -f {} \;
# find . -type f -name "*.job.sync"
# ./porecamp1/00000000/.job.sync

# Iterate thru runs
for RUNX in `find * -maxdepth 0 -mindepth 0 -type d`
do
	cd $RUNX/outputs
	for SAMPLE in `find * -maxdepth 0 -mindepth 0 -type d`
	do
		cd $SAMPLE
			mkdir_pems "${CORRAL_DEST}/${SAMPLE}"
		cd ../
	done
	cd ../../
done

