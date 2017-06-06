#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

IGNORE_LOCK=1
#_DRYRUN="-n"
_DRYRUN=

init(){
	export CWD=$(pwd)
}

CORRAL_DEST="${CORRALDIR}/outputs"

# outputs
#	porecamp1-7
#

cd $WORK_BASE
init

# Iterate thru runs
for RUNX in `find * -maxdepth 0 -mindepth 0 -type d`
do
	cd $RUNX/outputs
	for SAMPLE in `find * -maxdepth 0 -mindepth 0 -type d`
	do
		cd $SAMPLE
			mkdir_pems "${CORRAL_DEST}/${SAMPLE}"
			# barcode
			find workspace -maxdepth 1 -mindepth 1  -type d -cmin +5 -exec basename {} \; | xargs -n1 -I_dir mkdir -p "${CORRAL_DEST}/${SAMPLE}/_dir"
			for D in $(find workspace -maxdepth 1 -mindepth 1 -type d -cmin +5 -exec basename {} \;)
			do
				echo $D
			done



			find workspace -maxdepth 3 -mindepth 2  -type f -cmin +5 -name "*fast5" -exec basename {} \; | xargs -n1 -I_dir rsync -p -qarth "workspace/_dir/

			&& rsync $_DRYRUN -qartRh

			find workspace -type d -cmin +5 -path "barcode*" -path "unclassified" | xargs -n1 -I '{}' -P 12 $_DRYRUN --log-file=$CPDEST/sync.log
			find . -type f -cmin -$CTIME1 -cmin +5 -not -name "*tmp*" | xargs -n1 -I '{}' -P 12 rsync $_DRYRUN --log-file=$CPDEST/sync.log -qartRh "{}" $CPDEST/inputs/
		cd ../
	done
	cd ../../
done

