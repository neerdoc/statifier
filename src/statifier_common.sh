#!/bin/bash

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This script have to detect kernel/loader properties
# 

function GetProgramInterpreter
{
	[ $# -ne 1 -o "x$1" = "x" ] && {
		Echo "$0: Usage: GetProgramInterpreter <executable>"
		return 1
	}
	local Executable="$1"
	local res
	res="`readelf --program-headers $Executable`" || return 
	echo "$res" | awk '{
		if ($0 ~ "[[].*]") {
			print substr($NF, 1, match($NF, "]") - 1);
			exit 0;
		}
	}' || return
	return 0
}

function GetInterpreterBaseAddr
{
	$D/loader_base_test || return
	return 0
}

function GetInterpreterVirtAddr
{
	local Func=GetInterpreterVirtAddr
	[ $# -ne 1 -o "x$1" = "x" ] && {
		Echo "$0: Usage: $Func <Interpreter>"
		return 1
	}
	local Interpreter="$1"
	awk -vInterpreter=$Interpreter -vName="$0 $Func: " -vAP="'" '
		BEGIN {
			err = 1;
		}
		{
			if ($1 == "LOAD") {
				err = 0;
				if ($3 ~ ".*[1-9a-fA-F].*") {
					print $3;
				} else {
					print "0x0";
				}
				exit(0);
			}
		}
		END {
			if (err == 1) {
				Text=Name "no LOAD segment found in " AP Interpreter AP
				system("echo " Text " 1>&2")
				exit(1);
			}
		}
	' < $LOADER_PHDRS || return
	return 0
}

function GetInterpreterVirtAddr2
{
	local Func=GetInterpreterVirtAddr2
	[ $# -ne 1 -o "x$1" = "x" ] && {
		Echo "$0: Usage: $Func <Interpreter>"
		return 1
	}
	local Interpreter="$1"
	awk -vInterpreter=$Interpreter -vName="$0 $Func: " -vAP="'" '
		BEGIN {
			err = 2;
		}
		{
			if ($1 == "LOAD") {
				err--;
				if (err > 0) next;

				if ($3 ~ ".*[1-9a-fA-F].*") {
					print $3;
				} else {
					print "0x0";
				}
				if (NF >= 6) {
					print $6;
				} else {
					getline; 
					print $2;
				}
				exit(0);
			}
		}
		END {
			if (err > 0) {
				Text=Name "less then two LOAD segment found in " AP Interpreter AP
				system("echo " Text " 1>&2")
				exit(1);
			}
		}
	' < $LOADER_PHDRS || return
	return 0
}

function CheckTls
{
	# Test if interpreter/kernel use TLS (thread local storage)
	local val_has_tls="0"
	local val_breakpoint_thread=""
	local res
	res="`
		awk '{ 
			if ($0 ~ "tls") { 
				print "yes_probably_we_have_tls"; 
				exit(0);
			} 
		}' < $LOADER_SYMBOLS
	`" || return
	[ "x$res" = "x" ] || {
		val_breakpoint_thread="`$D/set_thread_area_addr $D/tls_test`" || return
		[ \! "x$val_breakpoint_thread" = "x" ] && {
			val_has_tls="1"
		}
	}
	echo "val_has_tls='$val_has_tls'"                     || return
	echo "val_breakpoint_thread='$val_breakpoint_thread'" || return
	return
}

function Main
{
	set -e
		source $OPTION_SRC || return
	set +e

	local val_uname_m
	val_uname_m=`uname -m` || return

	local val_interpreter
	val_interpreter=`GetProgramInterpreter $opt_orig_exe`
	[ "x$val_interpreter" = "x" ] && {
		Echo "$0: Interpreter not found in the '$opt_orig_exe'"
		return 1
	}

	readelf --syms            $val_interpreter > $LOADER_SYMBOLS || return
	readelf --program-headers $val_interpreter > $LOADER_PHDRS   || return

	local val_virt_addr val_base_addr
	val_virt_addr=`GetInterpreterVirtAddr $val_interpreter` || return
	val_base_addr=`GetInterpreterBaseAddr $val_interpreter` || return

	# I saw it on linux 2.6.6 with ld 2.3.2. which has fixed VirtAddr
	[ "x$val_base_addr" = "x0x0" ] && val_base_addr=$val_virt_addr
	[ "x$val_base_addr" = "x0x0" ] && {
		# val_virt_addr = 0x0 too. Bad. Give error and exit.
		Echo "$0: Can't find val_base_addr for '$val_interpreter': val_base_addr=val_virt_addr=0x0"
		return 1
	}
	[ "$val_virt_addr" = "$val_base_addr" -o "$val_virt_addr" = "0x0" ] || {
		Echo "$0: Interpreter's '$val_interpreter' val_virt_addr='$val_virt_addr' and val_base_addr='$val_base_addr' are different."
		return 1
	}

	# These variables I need only in case when 
	# autodetection used for dl variables
	local val
	val=`GetInterpreterVirtAddr2 $val_interpreter` || return
	set -- $val
	local val_virt_addr2=$1
	local val_size2=$2
	
	# Is interpreter stripped ?
	val=`$D/elf_stripped $val_interpreter` || return
	local val_interpreter_has_symtab
	if [ "x$val" = "x" ]; then
		val_interpreter_has_symtab="yes"
	else
		val_interpreter_has_symtab="no"
	fi

	(
		set -e
		echo "val_uname_m=$val_uname_m"
		echo "val_elf_class=$val_elf_class"
		echo "val_interpreter='$val_interpreter'"
		echo "val_interpreter_has_symtab='$val_interpreter_has_symtab'"
		echo "val_virt_addr='$val_virt_addr'"
		echo "val_base_addr='$val_base_addr'"
		echo "val_virt_addr2='$val_virt_addr2'"
		echo "val_size2='$val_size2'"
		CheckTls
	) || return 
	return 0
}

#################### Main Part ###################################

# Where Look For Other Programs
D=`dirname $0`               || exit
source $D/statifier_lib.src  || exit

[ $# -ne 2 -o "x$1" = "x" -o "x$2" = "x" ] && {
	Echo "Usage: $0 <work_dir> <elf_class>"
	exit 1
}

WORK_DIR=$1
val_elf_class=$2

SetVariables $WORK_DIR || exit
Main > $COMMON_SRC     || exit
exit 0
