#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

for N in porecamp1 porecamp2 porecamp3 porecamp4 porecamp5 porecamp6 porecamp7
do
	info "Syncing $N"
	{
		cd ${WORKDIR} && bash scripts/01_sync_process.sh ${N} && info "Success"
	} || {
		warn "Failed"
	}
done
