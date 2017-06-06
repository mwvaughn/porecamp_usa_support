#!/usr/bin/env bash

# Run on Hikari

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

CWD=$(pwd)

cd $WORK_BASE

for JOBFILE in $(find . -type f -name "*slurm.sh")
do
	info "Submitting: $(basename $JOBFILE)"
	{
	  sbatch ${JOBFILE} && info "Success" && mv ${JOBFILE} ${JOBFILE}.submitted
	} || {
		warn "Failure to submit"
	}
done
