#!/bin/bash

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Calculate addresses for _dl variables

function Main
{
	set -e
		source $COMMON_SRC || return
	set +e
	local Value
	local val_dl_list="$val_base_addr"
	Value=`GetSymbol _dl_argc        1 $val_virt_addr $val_base_addr` || return
	val_dl_list="$val_dl_list $Value"
	Value=`GetSymbol _dl_argv        1 $val_virt_addr $val_base_addr` || return
	val_dl_list="$val_dl_list $Value"
	Value=`GetSymbol _environ        1 $val_virt_addr $val_base_addr` || return
	val_dl_list="$val_dl_list $Value"
	Value=`GetSymbol _dl_auxv        1 $val_virt_addr $val_base_addr` || return
	val_dl_list="$val_dl_list $Value"
	Value=`GetSymbol _dl_platform    0 $val_virt_addr $val_base_addr` || return
	val_dl_list="$val_dl_list $Value"
	Value=`GetSymbol _dl_platformlen 0 $val_virt_addr $val_base_addr` || return
	val_dl_list="$val_dl_list $Value"

	echo "val_dl_list='$val_dl_list'" || return
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
Main > $STARTER_SRC    || exit
exit 0
