#!/bin/bash

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This script have to detect kernel/loader properties
# 

function GetInterpreterBaseAddr
{
	$D/loader_base_test || return
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
	val_interpreter=`$D/$elf_class/elf_data -i $opt_orig_exe` || return

	readelf --syms            $val_interpreter > $LOADER_SYMBOLS || return

	# Now it will not work for ld-linux with fixed load address.
	# but anyway I am goint to implement it by another way
	# and in another place
	local val_base_addr
	val_base_addr=`GetInterpreterBaseAddr $val_interpreter` || return

	# I saw it on linux 2.6.6 with ld 2.3.2. which has fixed VirtAddr
	#[ "x$val_base_addr" = "x0x0" ] && val_base_addr=$val_virt_addr
	#[ "x$val_base_addr" = "x0x0" ] && {
	#	# val_virt_addr = 0x0 too. Bad. Give error and exit.
	#	Echo "$0: Can't find val_base_addr for '$val_interpreter': val_base_addr=val_virt_addr=0x0"
	#	return 1
	#}

	#[ "$val_virt_addr" = "$val_base_addr" -o "$val_virt_addr" = "0x0" ] || {
	#	Echo "$0: Interpreter's '$val_interpreter' val_virt_addr='$val_virt_addr' and val_base_addr='$val_base_addr' are different."
	#	return 1
	#}

	# These variables I need only in case when 
	# autodetection used for dl variables
	
	(
		set -e
		echo "val_uname_m=$val_uname_m"
		echo "val_elf_class=$val_elf_class"
		echo "val_interpreter='$val_interpreter'"
		echo "val_base_addr='$val_base_addr'"
		$D/$elf_class/elf_data                 \
			-T val_interpreter_has_symtab= \
			-B val_virt_addr=              \
                   	-W val_virt_addr2=             \
			-S val_size2=                  \
		$val_interpreter
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
