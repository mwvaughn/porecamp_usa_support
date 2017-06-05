#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

info "Resetting $PROJDIR to default state"
{
  rm -rf ${PROJCONF}/* && rm -rf ${WORK_BASE}/* && info "Success" ;
} || {
	die "Failed for some reason..."
}

