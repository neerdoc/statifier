#!/bin/bash

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This script have to detect properties/addresses
# which I need in order to dump statified process.
# (now I am looking only for _dl_start_user address)

function Main
{
	set -e
		source $COMMON_SRC || return
	set +e
	local val_breakpoint_start
	val_breakpoint_start=`GetSymbol _dl_start_user 1` || return
	echo "val_breakpoint_start='$val_breakpoint_start'" || return
	return 0
}
#################### Main Part ###################################

# Where Look For Other Programs
D=`dirname $0`              || exit
source $D/statifier_lib.src || exit

[ $# -ne 1 -o "x$1" = "x" ] && {
	Echo "Usage: $0 <work_dir>"
	exit 1
}

WORK_DIR=$1

SetVariables $WORK_DIR || exit
Main > $DUMP_SRC       || exit
exit 0
