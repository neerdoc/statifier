#!/bin/bash

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# It's main script

function Sanity
{
	[ -f $OrigExe ] || {
   		echo "$0: '$OrigExe' not exsist or not regular file." 1>&2
   		return 1
	}

	[ -x $OrigExe ] || {
   		echo "$0: '$OrigExe' has not executable permission." 1>&2
   		return 1
	}

	[ -r $OrigExe ] || {
   		echo "$0: '$OrigExe' has not read permission." 1>&2
   		return 1
	}
	return 0
}

function GetProgramInterpreter
{
	res="$(readelf --program-headers $OrigExe)" || return 
	echo "$res" | awk '{
		if ($3 == "interpreter:") {
			print substr($4, 1, match($4, "]") - 1);
			exit 0;
		}
	}' || return
	return 0
}

function GetStartAddress
{
	[ $# -ne 2 -o "x$1" = "x" -o "x$2" = "x" ] && {
		echo "$0: Usage: GetStartAddress <Interpreter> <FuncName>" 1>&2
		return 1
	}
	local Interp="$1"
	local FuncName="$2"
	local Dump
	Dump=$(objdump --syms $Interp) || return
	echo "$Dump" | awk -vFuncName="$FuncName" '{ 
		if ($NF == FuncName) {
			print $1; 
			exit 0;
		}
	}' || return
	return 0
}

function DumpRegistersAndMemory
{
	gdb --batch -n -x "$WORK_GDB_CMD_DIR/map_reg_core.gdb" -x "$DUMPS_GDB" || return
	return 0
}

function CreateNewExe
{
	[ $# -ne 1 -o "x$1" = "x" ] && {
		echo "$0: Usage: CreateNewExe <NewExe>" 1>&2
		return 1
	}
	local NewExe="$1"

	STARTER=$STATIFIER_ROOT_DIR/starter
	FIRST_SEGMENT=$WORK_OUT_DIR/first.seg
	REGISTERS_BIN=$WORK_OUT_DIR/reg

	$STATIFIER_ROOT_DIR/regs.sh $REGISTERS_FILE $REGISTERS_BIN || return
	# All but last - I don't need previous stack
	DUMP_FILES="`echo $WORK_DUMPS_DIR/* | awk '{$NF = ""; print $0;}'`" || return
	$STATIFIER_ROOT_DIR/phdrs $EXECUTABLE_FILE $CORE_FILE $STARTER $REGISTERS_BIN $DUMP_FILES > $FIRST_SEGMENT || return
	rm -f $NewExe || return
	cat $FIRST_SEGMENT $DUMP_FILES > $NewExe || return
	chmod 555 $NewExe || return
	return 0
}

function Main
{
	local Interp
	local StartAddr
	local StartFunc="_dl_start_user"
	local WorkDir=$WORK_DIR

	# Different variables
	EXECUTABLE_FILE=$OrigExe
	BREAKPOINT="*$StartFunc"
	LOG_FILE="$WORK_GDB_OUT_DIR/log"
	MAPS_FILE="$WORK_GDB_OUT_DIR/maps"
	REGISTERS_FILE="$WORK_GDB_OUT_DIR/registers"
	CORE_FILE="$WORK_GDB_OUT_DIR/core"
	DUMPS_SH="$STATIFIER_ROOT_DIR/dumps.sh"
	DUMPS_GDB="$WORK_GDB_CMD_DIR/dumps.gdb"
	# End of variables
	Sanity || return
	Interp=$(GetProgramInterpreter)
	[ "x$Interp" = "x" ] && {
		echo "$0: Interpretor not found in the '$OrigExe'" 1>&2
		return 1
	}
	StartAddr="$(GetStartAddress $Interp $StartFunc)" || return
	[ "x$StartAddr" = "x" ] && {
		echo "$0: StartFunction '$StartFunc' not found in the interpretor '$Interp'" 1>&2
		return 1
	}
	# Prepare directory structure
	mkdir -p $WORK_GDB_CMD_DIR || return
	mkdir -p $WORK_GDB_OUT_DIR || return
	mkdir -p $WORK_DUMPS_DIR   || return
	mkdir -p $WORK_OUT_DIR     || return

	# List of files to be transformed
	FILE_LIST="map_reg_core.gdb dumps.gdb"

	# Transform them
	for File in $FILE_LIST; do
		sed                                            \
                   -e "s#\$0#$0#g"                             \
                   -e "s#@EXECUTABLE_FILE@#$EXECUTABLE_FILE#g" \
                   -e "s#@BREAKPOINT@#$BREAKPOINT#g"           \
                   -e "s#@LOG_FILE@#$LOG_FILE#g"               \
                   -e "s#@MAPS_FILE@#$MAPS_FILE#g"             \
                   -e "s#@REGISTERS_FILE@#$REGISTERS_FILE#g"   \
                   -e "s#@CORE_FILE@#$CORE_FILE#g"             \
                   -e "s#@DUMPS_SH@#$DUMPS_SH#g"               \
                   -e "s#@WORK_DUMPS_DIR@#$WORK_DUMPS_DIR#g"   \
                   -e "s#@DUMPS_GDB@#$DUMPS_GDB#g"             \
		< $STATIFIER_ROOT_DIR/$File > $WORK_GDB_CMD_DIR/$File || return
	done || return
	# Start addres to be passed to gdb's commands 
	DumpRegistersAndMemory || return

	CreateNewExe $NewExe || return
	return 0
}

#################### Main Part ###################################
[ $# -ne 2 -o "x$1" = "x" -o "x$2" = "x" ] && {
	echo "Usage: $0 <orig_exe> <statified_exe>" 1>&2
	exit 1
}

OrigExe=$1
NewExe=$2
# Where Look For Other Programs
STATIFIER_ROOT_DIR=`dirname $0` || exit

# Temporary Work Directory
WORK_DIR="${TMPDIR:-/tmp}/statifier.tmpdir.$$"
#WORK_DIR="./.statifier"

# Directoty for adjusted files.
WORK_GDB_CMD_DIR=$WORK_DIR/gdb_cmd

# Directory for segment files
WORK_DUMPS_DIR=$WORK_DIR/dumps

# Directory for misc output from gdb
WORK_GDB_OUT_DIR=$WORK_DIR/gdb_out

# Directory for temp files built during new exe file constructions.
WORK_OUT_DIR=$WORK_DIR/out

rm   -rf $WORK_DIR || exit
mkdir -p $WORK_DIR || exit
Main
st=$? 
rm -rf $WORK_DIR || exit
exit $st
