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
	res="`readelf --program-headers $OrigExe`" || return 
	echo "$res" | awk '{
		if ($0 ~ "[[].*]") {
			print substr($NF, 1, match($NF, "]") - 1);
			exit 0;
		}
	}' || return
	return 0
}

function GetElfClass
{
	res="`readelf --file-header $OrigExe`" || return 
	echo "$res" | awk '{
		if ($NF == "ELF32") { print "32"; exit 0;}
		if ($NF == "ELF64") { print "64"; exit 0;}
	}' || return
	return 0
}

function GetDataFromInterp
{
	[ $# -ne 1 -o "x$1" = "x" ] && {
		echo "$0: Usage: GetDataFromInterp <Interpreter>" 1>&2
		return 1
	}
	local Interp="$1"
	local Dump
	local Symbol
	local SymList="_dl_start_user _dl_argc _dl_argv _environ _dl_auxv _dl_platform _dl_platformlen"
        local NameList="DL_START_USER DL_ARGC DL_ARGV DL_ENVIRON DL_AUXV DL_PLATFORM DL_PLATFORMLEN"
	# "-" - have to have value
	# otherwise default value in case symbol not found
	# value shoud be in hex and without leading 0x
	local DefaultList="- - - - - 0 0"

	Dump=`objdump --syms $Interp` || return
	echo "$Dump" | 
	awk                                      \
		-vName="$0: GetDataFromInterp: " \
		-vInterp="$Interp"               \
		-vSymList="$SymList"             \
		-vNameList="$NameList"           \
		-vValueList="$DefaultList"       \
	'
		BEGIN {
			found = 0
			num1 = split(SymList  , aSymList  );
			num2 = split(NameList , aNameList );
			num3 = split(ValueList, aValueList);
			if (num1 != num2) {
				system("echo " Name "SymList and NameList have different number of elements. 1>&2")
				exit(1)
			}
			if (num1 != num3) {
				system("echo " Name "SymList and ValueList have different number of elements. 1>&2")
				exit(1)
			}
			num = num1
		}
		{
			for (i = 1; i <= num; i++) {
				if ($NF == aSymList[i]) {
					aValueList[i] = $1
					found++
					if (found == num) exit(0)
				}
			}
		}
		END {
			if (found != num) {
				is_error = 0
				for (i = 1; i <= num; i++) {
					if (aValueList[i] == "-") {
						is_error = 1
						system("echo " Name aSymList[i] " not found in the " Interp " 1>&2")
					}
				}
				if (is_error) exit(1);	
			}
			for (i = 1; i <= num; i++) {
				print aNameList[i] "=0x" aValueList[i]
			} 
			exit(0);
		}
	' || return
	return 0
}

function GetInterpreterBase
{
	[ $# -ne 1 -o "x$1" = "x" ] && {
		echo "$0: Usage: GetInterpeterBase <Interpreter>" 1>&2
		return 1
	}
	local Interp="$1"
	local RealInterp
	RealInterp=`$STATIFIER_ROOT_DIR/readlink $Interp` || return
	awk -vInterp="$RealInterp" '{ 
		if ($NF == Interp) {
			print $1; 
			exit 0;
		}
	}' < $MAPS_FILE || return
	return 0

}

function DumpRegistersAndMemory
{
	rm -f $LOG_FILE || return
	gdb                                                            \
		--batch                                                \
		-n                                                     \
		-x "$WORK_GDB_CMD_DIR/first.gdb"                       \
		${HAS_TLS:+-x "$WORK_GDB_CMD_DIR/set_thread_area.gdb"} \
		-x "$WORK_GDB_CMD_DIR/map_reg_core.gdb"                \
		-x "$DUMPS_GDB"                                        \
	> $LOG_FILE || return
	return 0
}

function CreateStarter
{
	[ $# -ne 1 -o "x$1" = "x" ] && {
		echo "$0: Usage: CreateStarter <Starter>" 1>&2
		return 1
	}
	local Starter="$1"

	local STARTER=$STATIFIER_ROOT_DIR/starter
	local REGISTERS_BIN=$WORK_OUT_DIR/reg
	local DL_VAR=$STATIFIER_ROOT_DIR/dl-var
	local DL_VAR_BIN=$WORK_OUT_DIR/dl-var
	local TLS_LIST=

	[ "$HAS_TLS" = "yes" ] && {
		$STATIFIER_ROOT_DIR/set_thread_area.sh $WORK_GDB_OUT_DIR/set_thread_area $WORK_OUT_DIR/set_thread_area || return
		TLS_LIST="
			$STATIFIER_ROOT_DIR/set_thread_area 
			$WORK_OUT_DIR/set_thread_area
		"
	}

	# Create binary file with dl-var variables
	rm -f $DL_VAR_BIN || return
	local dl_var_list="$DL_BASE $DL_ARGC $DL_ARGV $DL_ENVIRON $DL_AUXV $DL_PLATFORM $DL_PLATFORMLEN"
	$STATIFIER_ROOT_DIR/strtoul $dl_var_list > $DL_VAR_BIN || return
	# Create binary file with registers' values
	$STATIFIER_ROOT_DIR/regs.sh $REGISTERS_FILE $REGISTERS_BIN || return
	cat $DL_VAR $DL_VAR_BIN $TLS_LIST $STARTER $REGISTERS_BIN > $Starter || return
	return 0 
}
function CreateNewExe
{
	[ $# -ne 1 -o "x$1" = "x" ] && {
		echo "$0: Usage: CreateNewExe <NewExe>" 1>&2
		return 1
	}
	local NewExe="$1"
	local DL_BASE

	DL_BASE=`GetInterpreterBase $Interp` || return
	[ "x$DL_BASE" = "x" ] && {
		echo "$0: Can't find interpreter '$Interp' base address" 1>&2
		return 1
	}
	STARTER=$WORK_OUT_DIR/starter
	FIRST_SEGMENT=$WORK_OUT_DIR/first.seg

	CreateStarter $STARTER || return
	# All but last - I don't need previous stack
	DUMP_FILES="`echo $WORK_DUMPS_DIR/* | awk '{$NF = ""; print $0;}'`" || return
	$STATIFIER_ROOT_DIR/phdrs $EXECUTABLE_FILE $CORE_FILE $STARTER $DUMP_FILES > $FIRST_SEGMENT || return
	rm -f $NewExe || return
	cat $FIRST_SEGMENT $DUMP_FILES > $NewExe || return
	chmod +x $NewExe || return
	return 0
}

function Main
{
	local Interp
	local ElfClass
	local Dl_Data
	local StartFunc="_dl_start_user"
	local WorkDir=$WORK_DIR

	# Different variables
	EXECUTABLE_FILE=$OrigExe
	BREAKPOINT_START="*$StartFunc"
	LOG_FILE="$WORK_GDB_OUT_DIR/log"
	MAPS_FILE="$WORK_GDB_OUT_DIR/maps"
	REGISTERS_FILE="$WORK_GDB_OUT_DIR/registers"
	CORE_FILE="$WORK_GDB_OUT_DIR/core"
	DUMPS_SH="$STATIFIER_ROOT_DIR/dumps.sh"
	SPLIT_SH="$STATIFIER_ROOT_DIR/split.sh"
	SUMPS_SH="$STATIFIER_ROOT_DIR/dumps.sh"
	DUMPS_GDB="$WORK_GDB_CMD_DIR/dumps.gdb"
	# End of variables
	Sanity || return
	Interp=`GetProgramInterpreter`
	[ "x$Interp" = "x" ] && {
		echo "$0: Interpreter not found in the '$OrigExe'" 1>&2
		return 1
	}
	ElfClass=`GetElfClass`
	[ "x$ElfClass" = "x" ] && {
		echo "$0: Can't determine ELF CLASS for the '$OrigExe'" 1>&2
		return 1
	}

	STATIFIER_ROOT_DIR=$STATIFIER_ROOT_DIR/$ElfClass
	[ -d $STATIFIER_ROOT_DIR ] || {
		echo "$0: ElfClass '$ElfClass' do not supported on this system." 1>&2
	}
	Dl_Data="`GetDataFromInterp $Interp`" || return
	eval "$Dl_Data" || return

	# Test if interpreter use TLS (thread local storage)
	HAS_TLS=""
	objdump --syms $Interp | grep "tls" >/dev/null && {
		BREAKPOINT_THREAD="`$STATIFIER_ROOT_DIR/set_thread_area_addr $STATIFIER_ROOT_DIR/tls_test`" || return
		[ \! "x$BREAKPOINT_THREAD" = "x" ] && {
			BREAKPOINT_THREAD="*$BREAKPOINT_THREAD" || return
			HAS_TLS="yes"
		}
	}

	# Prepare directory structure
	mkdir -p $WORK_GDB_CMD_DIR || return
	mkdir -p $WORK_GDB_OUT_DIR || return
	mkdir -p $WORK_DUMPS_DIR   || return
	mkdir -p $WORK_OUT_DIR     || return

	# List of files to be transformed
	FILE_LIST="first.gdb ${HAS_TLS:+set_thread_area.gdb} map_reg_core.gdb dumps.gdb"

	# Transform them
	for File in $FILE_LIST; do
		sed                                                \
                   -e "s#\$0#$0#g"                                 \
                   -e "s#@EXECUTABLE_FILE@#$EXECUTABLE_FILE#g"     \
                   -e "s#@BREAKPOINT_START@#$BREAKPOINT_START#g"   \
                   -e "s#@BREAKPOINT_THREAD@#$BREAKPOINT_THREAD#g" \
                   -e "s#@LOG_FILE@#$LOG_FILE#g"                   \
                   -e "s#@MAPS_FILE@#$MAPS_FILE#g"                 \
                   -e "s#@REGISTERS_FILE@#$REGISTERS_FILE#g"       \
                   -e "s#@CORE_FILE@#$CORE_FILE#g"                 \
                   -e "s#@DUMPS_SH@#$DUMPS_SH#g"                   \
                   -e "s#@DUMPS_SH@#$DUMPS_SH#g"                   \
                   -e "s#@SPLIT_SH@#$SPLIT_SH#g"                   \
                   -e "s#@WORK_DUMPS_DIR@#$WORK_DUMPS_DIR#g"       \
                   -e "s#@DUMPS_GDB@#$DUMPS_GDB#g"                 \
		< $STATIFIER_ROOT_DIR/$File > $WORK_GDB_CMD_DIR/$File || return
	done || return
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
