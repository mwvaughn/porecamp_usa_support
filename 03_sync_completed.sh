#!/bin/bash

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

do_gather_no_barcode(){

	_MACHINE=$1
	_RUN=$2
	_SAMPLE=$3

	_SOURCEPATH="$WORK_BASE/$_MACHINE/$_RUN/outputs/$_SAMPLE/workspace"
	_DESTPATH="$CORRAL_DEST/$_MACHINE/$_SAMPLE/workspace"

	info "Source: $_SOURCEPATH"
	info "Dest: $_DESTPATH"

	# FASTQ outputs not named in threadsafe manner
	# i.e. fastq_runid_5880e8a897b565d012ad9d9024df7d55def92c87_0.fastq not unique
	# rename using persistent counter

	if [ ! -f  "$_DESTPATH/.fastq.counter" ]
	then
		echo "0" > "$_DESTPATH/.fastq.counter"
	fi
	FASTQ_COUNTER=$(cat "$_DESTPATH/.fastq.counter")
	info "fastq file index: $FASTQ_COUNTER"

	for FQ in $(find $WORK_BASE/$_MACHINE/$_RUN/outputs/$_SAMPLE/workspace -maxdepth 1 -mindepth 1 -type f -name "*.fastq" -exec basename {} \;)
	do
		info "file: $FQ"
		NEWX="_${FASTQ_COUNTER}.fastq"
		NEWFQ=$(echo $FQ | sed -E 's|_[0-9]+.fastq|'$NEWX'|g')
		FASTQ_COUNTER=$((FASTQ_COUNTER+1))
		echo $FASTQ_COUNTER > "$_DESTPATH/.fastq.counter"
		info "rename: $NEWFQ"
		cp -a $_SOURCEPATH/$FQ $_DESTPATH/$NEWFQ  && chmod g+rw,o+r $_DESTPATH/$NEWFQ || warn "Couldn't copy $FQ"
	done

	# Copy contents of numbered destination directories in SOURCEPATH
	# Each contains ~4k files
	# No explicit linkage to calling outcomes or input so we
	# should just be able to generate on our own in DESTPATH
	if [ ! -f  "$_DESTPATH/.dir.counter" ]
	then
		echo "0" > "$_DESTPATH/.dir.counter"
	fi
	DIR_COUNTER=$(cat "$_DESTPATH/.dir.counter")
	info "directory index: $DIR_COUNTER"

	# Find all fast5 files
	CWD=$(pwd)
	info "Writing manifest..."
	rm -f $_DESTPATH/.manifest.rsync
	cd $_SOURCEPATH && find . -type f -name "*.fast5" | sed -e 's|^./||g' > $_DESTPATH/.manifest
	FILE_COUNTER=0
	DIR_COUNTER=0
	mkdir_pems "$_DESTPATH/$DIR_COUNTER"

	info "Writing rsync recipe..."
	# example
	# 0/cbgse_iMac02_dt_local_20170605_FNFAH06470_MN19421_sequencing_run_JesterKing2_18389_read_9772_ch_496_strand.fast5	/corral-tacc/projects/porecamp_usa/outputs/porecamp1/20170606_0419_JesterKing2/workspace/21/
	while read f
		do
		FILE_COUNTER=$((FILE_COUNTER+1))
		echo -e "$f\t$_DESTPATH/$DIR_COUNTER/" >> $_DESTPATH/.manifest.rsync
		if [ "$FILE_COUNTER" -gt "4000" ]
		then
			FILE_COUNTER=0
			DIR_COUNTER=$((DIR_COUNTER+1))
			echo $DIR_COUNTER > "$_DESTPATH/.dir.counter"
			mkdir_pems "$_DESTPATH/$DIR_COUNTER"
			info "dest_directory_counter: $DIR_COUNTER"
		fi
	done < $_DESTPATH/.manifest

	rm -rf $_DESTPATH/.manifest
	cd $CWD

	# Now, do the rsync via parallelism xargs
	cd $_SOURCEPATH; cat $_DESTPATH/.manifest.rsync | cut -f 1,2 | xargs -n2 -P 12 sh -c 'rsync --progress -avh $0 $1' && \
	cd $CWD && \
	rm -rf $_DESTPATH/.manifest.rsync

}

do_sync_machine_run(){

	_MACHINE=$1
	_RUN=$2
	_SAMPLE=$3

	_SOURCEPATH="$WORK_BASE/$_MACHINE/$_RUN/outputs/$_SAMPLE"
	_DESTPATH="$CORRAL_DEST/$_MACHINE/$_SAMPLE"

	info "Source: $_SOURCEPATH"
	info "Dest: $_DESTPATH"

	# Sequencing summary
	# Write header if not exists
	if [ ! -f "$_DESTPATH/sequencing_summary.txt" ]
	then
		info "Create: sequencing_summary.txt"
		head -n 1 "$_SOURCEPATH/sequencing_summary.txt" > $_DESTPATH/sequencing_summary.txt
	fi
	# Write file contents
	info "Append: sequencing_summary.txt"
	egrep -v "filename" "$_SOURCEPATH/sequencing_summary.txt" >> $_DESTPATH/sequencing_summary.txt

	# Other logs
	for _LOG in configuration.cfg pipeline.log
	do
		mkdir_pems "$_DESTPATH/${_LOG}.d"
		cp $_SOURCEPATH/$_LOG "$_DESTPATH/${_LOG}.d/${_LOG}.${_RUN}"
		info "Create: $_DESTPATH/${_LOG}.d/${_LOG}.${_RUN}"
	done

	# Sync workspace
	mkdir_pems "$_DESTPATH/workspace"
	info "Create: $_DESTPATH/workspace"

	# Barcoded vs non-barcoded outputs
	if [ -d "$_SOURCEPATH/workspace/unclassified" ]
	then
		warn "Data is barcoded. Sync not supported yet"
	else
		info "Consolidating sequence run"
		do_gather_no_barcode $_MACHINE $_RUN $_SAMPLE
	fi



}

CORRAL_DEST="${CORRALDIR}/outputs"
CWD=$(pwd)
cd $WORK_BASE

# Find runs per machine who are ready to be synced back to Corral
info $WORK_BASE
for RUNX in $(find . -mindepth 0 -maxdepth 3 -type f -name ".job.sync")
do
	MACHINEID=$(echo $RUNX | cut -f 2 -d '/')
	RUNID=$(echo $RUNX | cut -f 3 -d '/')
	info "$MACHINEID/$RUNID"
	for SAMPLEX in $(find "$WORK_BASE/$MACHINEID/$RUNID/inputs/" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
	do
		info "  $SAMPLEX"
		# Create output directories for consolidation
		mkdir_pems "$CORRAL_DEST/$MACHINEID/$SAMPLEX"
	done
	# replace with mv when I am ready to pull trigger
	cp $RUNX "$RUNX.inprogress"
	do_sync_machine_run $MACHINEID $RUNID $SAMPLEX
done

cd $CWD
exit 0
