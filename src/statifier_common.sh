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
		echo "$0: Usage: GetProgramInterpreter <executable>" 1>&2
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
		echo "$0: Usage: $Func <Interpreter>" 1>&2
		return 1
	}
	local Interpreter="$1"
		#Interp="/home/src/user/vreznic/mail/ld-2.3.2.so"
	readelf --program-headers $Interpreter > $LOADER_PHDRS || return
	awk -vInterp=$Interp -vName="$0 $Func: " -vAP="'" '
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
				Text=Name "no LOAD segment found in " AP Interp AP
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
	local HAS_TLS=""
	local BREAKPOINT_THREAD=""
	grep "tls" < $LOADER_SYMBOLS >/dev/null && {
		BREAKPOINT_THREAD="`$D/set_thread_area_addr $D/tls_test`" || return
		[ \! "x$BREAKPOINT_THREAD" = "x" ] && {
			HAS_TLS="yes"
		}
	}
	echo "HAS_TLS='$HAS_TLS'"                     || return
	echo "BREAKPOINT_THREAD='$BREAKPOINT_THREAD'" || return
	return
}

function Main
{
	local Interpreter

	Interpreter=`GetProgramInterpreter $Executable`
	[ "x$Interpreter" = "x" ] && {
		echo "$0: Interpreter not found in the '$Executable'" 1>&2
		return 1
	}

	objdump --syms $Interpreter > $LOADER_SYMBOLS || return

	local VirtAddr BaseAddr
	VirtAddr=`GetInterpreterVirtAddr $Interpreter` || return
	BaseAddr=`GetInterpreterBaseAddr $Interpreter` || return
	[ "$VirtAddr" = "$BaseAddr" -o "$VirtAddr" = "0x0" ] || {
		echo "$0: Interpreter's '$Interpreter' VirtAddr='$VirtAddr' and BaseAddr='$BaseAddr' are different." 1>&2 
		return 1
	}

	{
		echo "Executable='$Executable'"   && \
		echo "Interpreter='$Interpreter'" && \
		echo "VirtAddr='$VirtAddr'"       && \
		echo "BaseAddr='$BaseAddr'"       && \
		CheckTls                          && \
		:
	} || return 
	return 0
}

#################### Main Part ###################################
[ $# -ne 2 -o "x$1" = "x" -o "x$2" = "x" ] && {
	echo "Usage: $0 <work_dir> <orig_executable>" 1>&2
	exit 1
}

WORK_DIR=$1
Executable=$2

# Where Look For Other Programs
D=`dirname $0`               || exit
source $D/statifier_lib.src  || exit

Main > $COMMON_SRC           || exit
exit 0
