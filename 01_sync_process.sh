#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

LASTRUN=
RUN=
IGNORE_LOCK=1
MIN_PAST=15
#_DRYRUN="-n"
_DRYRUN=

# Self explanatory
function zero_pad {
	echo $(printf "%08d\n" $1)
}

# Escapes backslashes and spaces
escape_path(){

	echo $(echo $1 | tr -s '\/' '\\\/' | tr -s " " "\\ ")
}
export -f escape_path

# Does all the setup things
# Most importantly, reads from the state directory
init(){

	mkdir -p "${PROJCONF}"

	LASTRUN=$(date +%s)

	if [ ! -f  "${PROJCONF}/last.time" ]
	then
		LASTRUN=${STARTDATE}
	else
		LASTRUN=$(cat "${PROJCONF}/last.time")
	fi
	LASTRUN_NOW=$(date +%s)
	echo -n $LASTRUN_NOW > "${PROJCONF}/last.time"
	export LASTRUN

	if [ ! -f  "${PROJCONF}/last.runid" ]
	then
		RUN=0
	else
		RUN=$(cat "${PROJCONF}/last.runid")
		RUN=$((RUN+1))
	fi
	echo -n $RUN > "${PROJCONF}/last.runid"
	export RUN
	export CWD=$(pwd)

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

# Copies a file from Corral to its relative home on Work
cp_relpath(){

	SOURCEPATH="$1"
	CORRAL_BASE=$2
	CPDEST=$3
	RUN=$4

	DESTPATH=$(echo "$SOURCEPATH" | sed -e 's|'$CORRAL_BASE'|'$CPDEST'/|g')
	cp -af "$SOURCEPATH" "$DESTPATH"

# 	if [ "$IGNORE_LOCK" = 1 ]
# 	then
# 		cp -af "$SOURCEPATH" "$DESTPATH"
# 	elif [ ! -f "${SOURCEPATH}.${RUN}.lock" ]
# 	then
# 		cp -af "$SOURCEPATH" "$DESTPATH" && touch "${SOURCEPATH}.${RUN}.lock"
# 	fi

}
export -f cp_relpath

# Calculates run-time for job w X files in it
calc_hours(){

	WORK_UNITS=$(echo "$1 / 60000" | bc -l)
	WORK_UNITS=$(roundup1 "$WORK_UNITS")
	RUNTIME_HOURS=$(echo "$WORK_UNITS * $RUNTIME_PER_UNIT" | bc | xargs -n1 -I '{}' printf "%02d\n" {})

	if [ "$RUNTIME_HOURS" -lt "1" ]
	then
		RUNTIME_HOURS=1
	fi

	if [ "$RUNTIME_HOURS" -gt "48" ]
	then
		RUNTIME_HOURS="48"
	fi

	echo $RUNTIME_HOURS

}
export -f calc_hours

# Main code
init
info "Run: $RUN"
info "Last sync: $(date --date @$LASTRUN)"
info "Source: $CORRAL_BASE"

# Compute -ctime date range for sync
#cmin >=  (TIMENOW - LASTRUN) seconds / 60 sec/min
#cmin <=  (TIMENOW - RSYNC_DELAY) seconds / 60 sec/min
TIMENOW=$(date +%s)
CTIME1=$((($TIMENOW - $LASTRUN) / 60))
CTIME2=$((($RSYNC_DELAY) /60))
MIN=$([ $CTIME1 -le $CTIME2 ] && echo "$CTIME1" || echo "$CTIME2")

info "Syncing files modified:"
info "  Within the last $CTIME1 m"
info "  Not within the last $MIN m"

# Create run-specific directory (and kids)
info "Creating work directories..."
RUNDIR=$(zero_pad $RUN)
export CPDEST="$WORK_BASE/$RUNDIR"
{
  mkdir_pems $CPDEST && mkdir_pems $CPDEST/inputs && mkdir_pems $CPDEST/outputs && info "Success" ;
} || {
  die "Failed to create $CPDEST or children."
}
info "Destination: $WORK_BASE/$RUNDIR"

# Look for files changed since last run, but not within last 10 min
#	use chained -ctime eventually
info "Syncing new files from Corral..."
SECONDS=0
{
  time cd $CORRAL_BASE && find . -type f -cmin -$CTIME1 -cmin +$CTIME2 -not -name "*tmp*" | xargs -n1 -I '{}' -P 12 rsync $_DRYRUN --log-file=$CPDEST/sync.log -qartRh "{}" $CPDEST/inputs/  && info "Success" ;
} || {
  die "No candidate files found in $CORRAL_BASE."
}
info "${SECONDS}s elapsed"
cd $CWD

COUNTFILES=$(cat "$CPDEST/sync.log" | grep -c ">f+++++++++")
info "$COUNTFILES files transferred"
RUNTIME_HOURS=$(calc_hours $COUNTFILES)
RUNTIME_HOURS=$(printf "%02d\n" $RUNTIME_HOURS)
info "Estimated albacore runtime: $RUNTIME_HOURS h"

info "Creating and submitting basecalling jobs..."
touch $CPDEST/.job.lock

cat <<EOF > $CPDEST/job-$RUN-slurm.sh
#!/bin/bash

#SBATCH -J albacore-$TACC_ALBACORE_VERS-$THREADS-$RUN
#SBATCH -o albacore-$TACC_ALBACORE_VERS-$THREADS-$RUN.o%j
#SBATCH -N 1
#SBATCH -n 24
#SBATCH -p normal
#SBATCH -t $RUNTIME_HOURS:00:00
#SBATCH -A porecamp_usa

newgrp $PROJGRP
chmod g+srwx .
chgrp $PROJGRP .

LOG=$CPDEST/albacore-$TACC_ALBACORE_VERS-$THREADS-$RUN.log

# if [ -f $CPDEST/.job.lock.run ]
# then
# 	echo "It looks like this run is already being processed" > \$LOG
# 	exit 0
# fi
#
# if [ -f $CPDEST/.job.lock ]
# then
# 	touch $CPDEST/.job.lock.run
# else
# 	echo "It doesn't look like the sync job for this run is done"
# 	exit 0
# fi

cd $CPDEST/inputs

module load singularity/2.2.1

# Common options
filesPerbatchFolder="$ALBA_BATCH"
config="$ALBA_CONFIG"
workerThreads="$THREADS"
outputFormat="fastq,fast5"
recursive="--recursive"

for SAMPLE in \`ls .\`
do

echo "Basecalling in sample \$SAMPLE..."

input=$CPDEST/inputs/\$SAMPLE
save_path=$CPDEST/outputs/\$SAMPLE
mkdir -p \$save_path

time singularity --quiet run $TACC_ALBACORE \
--input \$input \
--save_path \$save_path \
--config \$config \$recursive \
--output_format \$outputFormat \
--worker_threads \$workerThreads \
--files_per_batch_folder \$filesPerbatchFolder

done

# ONLY do this if no error
rm $CPDEST/.job.lock

# A secondary sync script picks up $CPDEST folders
# where lock has been released and does a one-way
# rsync TO the requisite rooted location at
# $CORRAL_BASE

EOF

sbatch $CPDEST/job-$RUN-slurm.sh

