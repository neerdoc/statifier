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
# and
# different addresses I need to create starter.

function ForDump
{
	local val_breakpoint_start

	val_breakpoint_start=`GetSymbol _dl_start_user 1`   || return
	echo "val_breakpoint_start='$val_breakpoint_start'" || return
	return 0
}

function ForStarter
{
	local Value 
	local Var
	local val_dl_list

	val_dl_list="$val_base_addr"
	echo "#"
	echo "# val_base_addr=$val_base_addr"
	echo "#"

	Var="_dl_argc"
	Value=`GetSymbol $Var 1` || return
	val_dl_list="$val_dl_list $Value"

	Var="_dl_argv"
	Value=`GetSymbol $Var 1` || return
	echo "# $Var=$Value"     || return
	val_dl_list="$val_dl_list $Value"

	Var="_environ"
	Value=`GetSymbol $Var 1` || return
	echo "# $Var=$Value"     || return
	val_dl_list="$val_dl_list $Value"

	Var="_dl_auxv"
	Value=`GetSymbol $Var 1` || return
	echo "# $Var=$Value"     || return
	val_dl_list="$val_dl_list $Value"

	Var="_dl_platform"
	Value=`GetSymbol $Var 0` || return
	echo "# $Var=$Value"     || return
	val_dl_list="$val_dl_list $Value"

	Var="_dl_platformlen"
	Value=`GetSymbol $Var 0` || return
	echo "# $Var=$Value"     || return
	val_dl_list="$val_dl_list $Value"

	echo "val_dl_list='$val_dl_list'" || return
	return 0
}

function Main
{
	set -e
		source $COMMON_SRC || return
	set +e
	ForDump    || return
	ForStarter || return
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
Main > $LOADER_SRC     || exit
exit 0
