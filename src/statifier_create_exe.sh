#!/bin/bash

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This script finally create statified exe

function IsStack
{
	if [[ $val_stack_pointer -ge $Start && $val_stack_pointer -lt $Stop ]]; then 
		# It's stack seg
		is_stack=1
	else
		is_stack=0
	fi
	return 0
}

function IsLinuxGate
{
	# To do
	is_linux_gate=0
	return 0
}

function pt_load
{
	set -- Dummy $WORK_DUMPS_DIR/* || return
	local Start Stop Perm Offset Name Dummy
	local is_stack is_linux_gate
	while :; do
		shift
		read Start Stop Perm Offset Name Dummy || break
		IsStack                || return
		[ $is_stack = 1 ]      && continue # skip stack segment
		IsLinuxGate            || return
		[ $is_linux_gate = 1 ] && continue # skip linux-gate segment
		$D/pt_load_1 $Start $Stop $Perm || return
		PT_LOAD_FILES="$PT_LOAD_FILES $1"
	done || return
	return 0
}

function CreateNewExe
{
	local Func=CreateNewExe
	[ $# -ne 2 -o "x$1" = "x" -o "x$2" = "x" ] && {
		Echo "$0: Usage: $Func <OrigExe> <NewExe>"
		return 1
	}
	local OrigExe="$1"
	local NewExe="$2"

	local PT_LOAD_PHDRS=$WORK_OUT_DIR/pt_load_phdrs
	local NON_PT_LOAD=$WORK_OUT_DIR/non_pt_load
	local STARTER=$WORK_OUT_DIR/starter

	local PT_LOAD_FILES
	local E_ENTRY

	# Find entry point (i.e place) for the starter
	E_ENTRY=`$D/fep.sh $MAPS_FILE $STARTER` || return

	# Create file with PT_LOAD headers and set variable PT_LOAD_FILES
	rm -f $PT_LOAD_PHDRS || return
	pt_load < $MAPS_FILE > $PT_LOAD_PHDRS || return

	# Create non-pt-load part of the executable
	rm -f $NON_PT_LOAD || return
	$D/non_pt_load $OrigExe $PT_LOAD_PHDRS $E_ENTRY > $NON_PT_LOAD || return

	# Concatenate it with PT_LOAD part
	rm -f $NewExe || return
	cat $NON_PT_LOAD $PT_LOAD_FILES > $NewExe || return

	# Inject starter into executable
	$D/inject_starter $STARTER $NewExe || return

	# Set permission
	chmod +x $NewExe || return
	return 0
}

function Main
{
	set -e
		source $OPTION_SRC || return
		source $COMMON_SRC || return
		source $MISC_SRC   || return
	set +e

	CreateNewExe $opt_orig_exe $opt_new_exe || return
	return 0
}

#################### Main Part ###################################

# Where Look For Other Programs
D=`dirname $0`              || exit
source $D/statifier_lib.src || exit
source $D/properties.src    || exit

[ $# -ne 1 -o "x$1" = "x" ] && {
	Echo "Usage: $0 <work_dir>"
	exit 1
}

WORK_DIR=$1

SetVariables $WORK_DIR || exit
Main                   || exit
exit 0
