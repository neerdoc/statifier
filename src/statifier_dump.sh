#!/bin/bash

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Dump all data from the statified process

function DumpRegistersAndMemory
{
	rm -f $LOG_FILE || return
	$GDB                                                \
		--batch                                     \
		-nx                                         \
		--command "$WORK_GDB_CMD_DIR/statifier.gdb" \
	> $LOG_FILE || return
	return 0
}

function GDB_Name
{
	local Func=GDB_Name
	[ $# -ne 2 -o "x$1" = "x" -o "x$2" = "x" ] && {
		Echo "$0: Usage: $Func <ElfClass> <UnameM>"
		return 1
	}
	local ElfClass=$1
	local UnameM=$2
	local GDB="gdb"
	case "$ElfClass" in
		32)
			case "$UnameM" in
				x86_64) GDB=gdb32;;
			esac || return
		;;

		64)
			GDB="gdb"
		;;
		*)
			Echo "$0: $Func: ElfClass '$ElfClass'. Should be '32' or '64'"
			return 1
		;;
	esac || return

	echo $GDB || return
	return 0
}

function CreateEnv
{
	# Create file with environment to be set by gdb (may be empty)
	local current=0
        local var
	echo "# Environment for running program"
	while [ $current -lt $opt_loader_num_var ]; do
		current=$[current + 1]               || return
		eval var="\$opt_loader_var_$current" || return
		echo "$var"                          || return 
	done || return
	return 0
}			

function CreateVar
{
	local val_has_hit_msg
	case $val_uname_m in
		alpha* | mips*) val_has_hit_msg=1;;
		*)              val_has_hit_msg=0;;
	esac || return

	# Create var.gdb
	echo "# Variables for gdb"                                     || return
	echo "set \$BREAKPOINT_START  = ${val_breakpoint_start}"       || return
	echo "set \$BREAKPOINT_THREAD = ${val_breakpoint_thread:-0x0}" || return
	echo "set \$val_has_tls       = ${val_has_tls}"                || return
	echo "set \$val_has_hit_msg   = ${val_has_hit_msg}"            || return

	return 0
}

function Main
{
	local GDB

	set -e
		source $OPTION_SRC || return
		source $COMMON_SRC || return
		source $LOADER_SRC || return
	set +e

	# Different variables
	EXECUTABLE_FILE=$opt_orig_exe
	LOG_FILE="$WORK_GDB_OUT_DIR/log"
	MAPS_FILE="$WORK_GDB_OUT_DIR/maps"
	DUMPS_SH="$D/dumps.sh"
	SET_THREAD_AREA_GDB="$D/set_thread_area.gdb"
	SPLIT_SH="$D/split.sh"
	DUMPS_GDB="$WORK_GDB_CMD_DIR/dumps.gdb"
	ENV_GDB="$WORK_GDB_CMD_DIR/env.gdb"
	VAR_GDB="$WORK_GDB_CMD_DIR/var.gdb"
	# End of variables

	# Determine debugger name
	GDB=`GDB_Name $val_elf_class $val_uname_m` || return

	# Create env.gdb
	CreateEnv > $ENV_GDB || return

	# Create env.gdb
	CreateVar > $VAR_GDB || return

	# Transform file for gdb
	local File="statifier.gdb"
	sed                                                          \
        	-e "s#@CORE_FILE@#$CORE_FILE#g"                      \
        	-e "s#@DUMPS_GDB@#$DUMPS_GDB#g"                      \
        	-e "s#@DUMPS_SH@#$DUMPS_SH#g"                        \
        	-e "s#@ENV_GDB@#$ENV_GDB#g"                          \
        	-e "s#@EXECUTABLE_FILE@#$EXECUTABLE_FILE#g"          \
        	-e "s#@LOG_FILE@#$LOG_FILE#g"                        \
        	-e "s#@MAPS_FILE@#$MAPS_FILE#g"                      \
        	-e "s#@REGISTERS_FILE@#$REGISTERS_FILE#g"            \
        	-e "s#@SET_THREAD_AREA_GDB@#$SET_THREAD_AREA_GDB#g"  \
        	-e "s#@SPLIT_SH@#$SPLIT_SH#g"                        \
        	-e "s#@VAR_GDB@#$VAR_GDB#g"                          \
        	-e "s#@WORK_DUMPS_DIR@#$WORK_DUMPS_DIR#g"            \
	< $D/$File > $WORK_GDB_CMD_DIR/$File || return

	DumpRegistersAndMemory || return
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
Main                   || exit
exit 0
