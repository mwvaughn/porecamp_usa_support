#!/bin/bash

DATADIR=$1
CWD=$PWD

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

cd $DATADIR

{
	info "Fixing permissions and ownership on $PWD"
	info "Folder group permissions"
	find . -type d | xargs -n1 -I '{}' -P 12 chmod g+rwxs,o+rx {}
	info "Folder ownership"
	find . -type d | xargs -n1 -I '{}' -P 12 chgrp $PROJGRP {}
	info "File permissions"
	find . -type f | xargs -n1 -I '{}' -P 12 chmod g+rw,o+r {}
	info "File ownership"
	find . -type f | xargs -n1 -I '{}' -P 12 chgrp $PROJGRP {}
} || {
	warn "Failed"
}

cd $CWD
