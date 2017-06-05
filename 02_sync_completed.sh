#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

IGNORE_LOCK=1
#_DRYRUN="-n"
_DRYRUN=

init(){

	export $CWD=$(pwd)

}

cd $WORK_BASE
init

for SAMPLE in `ls .`
do

info "Syncing data from $SAMPLE"
if [ ! -f "$SAMPLE/.job.lock" ]
then

cd rsync $_DRYRUN --log-file=$SAMPLE/sync_out.log -qartRh

else
	warn "Lockfile detected. 'rm -rf $SAMPLE/.job.lock' to force sync."
fi

done