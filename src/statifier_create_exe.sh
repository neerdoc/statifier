#!/bin/bash

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This script finally create statified exe

function IsInside
{
	[ $# -ne 3 -o "x$1" = "x" -o "x$2" = "x" -o "x$3" = "x" ] && {
		Echo "Usage: $0 IsInside <value> <low> <high>"
		return 1
	}
	is_inside="no"
	local Value=$1
	local Low=$2
	local High=$3
	[[ $Value -lt $Low  ]] && return
	[[ $Value -ge $High ]] && return
	is_inside="yes"
	return 0
}

function GetKernelStackStartStop
{
	local File=$WORK_GDB_OUT_DIR/init_maps
	local Start Stop Dummy
	local is_inside
	while read Start Stop Dummy; do
		case "Z$Start" in
			Z0x*) # Look's like number
				IsInside $val_stack_pointer $Start $Stop || return
				[ "$is_inside" = "yes" ] && {
					echo "$Start $Stop" 
					return
				}
			;;

			*)
				: # do nothing
			;;
		esac
	done < $File || return
	Echo "$0: can't find kernel stack"
	retrun 1
}

# Once function IsStack was very simple:
# start <= $val_stack_pointer < stop
# That's it.
# But ld-2.3.3 is too wise:
# if executable (or one of it's dynamic libraries) need executable stack
# loader split stack segment, provided by the kernel to two ones:
# with permissions 'rwx' and with 'rw-'.
# But it's not all story ! loader also resize stack segment.
# Add to it systems with stack growing down and stack growing up and you
# get a full picture of the sad reality.
# So, how I am going to find all stack segments ?
# I use "original" stack segment which kernel provide to the process.
#
#       Stack Growing Up
#       ------------------
#       | original stack |
#       ---------------------
#       | stack 1 | stack 2 |
#       ---------------------
#
#       Stack Growing Up
#          ------------------
#          | original stack |
#       ---------------------
#       | stack 1 | stack 2 |
#       ---------------------
# 
# So in any case both of the stack segments can be detected as following:
# if (SegmentStart inside original stack segment) 
# OR (SegmentStop  inside original stack segment)
# it's stack segment.
# otherwise - not.
#
# As extra safetly i check also if a stack pointer inside segment
# but i think it's redundant now.
function IsStack
{
	# It's stack seg
	is_stack=1

	local is_inside

	IsInside $val_stack_pointer $Start $Stop || return
	[ "$is_inside" = "yes" ] && return

	IsInside $Start $kernel_stack_start $kernel_stack_stop || return
	[ "$is_inside" = "yes" ] && return

	IsInside $Stop  $kernel_stack_start $kernel_stack_stop || return
	[ "$is_inside" = "yes" ] && return

	# No, it's not a stack segment
	is_stack=0
	return 0
}

function IsLinuxGate
{
	local soname
	soname=`$D/elf_soname $1` || return
	case "x$soname" in
		xlinux-gate.so.*)
			is_linux_gate=1
		;;

		*)
			is_linux_gate=0
		;;
	esac
	return 0
}

function IsIgnoredSegment
{
	# This function set is_ignored to 1 if segment should be
	# ignored, otherwise - to 0
	#	[ "$is_ignored" = "1" ] && return 0
	is_ignored=1

	local is_stack is_linux_gate
	IsStack                || return
	[ $is_stack = 1 ]      && return 0
	IsLinuxGate $1         || return
	[ $is_linux_gate = 1 ] && return 0

	is_ignored=0
	return 0
}

function pt_load
{
	# This function create two outputs:
	#  1) stdout
	#  2) set PT_LOAD_FILES variable
	local result kernel_stack_start kernel_stack_stop
	result=`GetKernelStackStartStop` || return
	set -- $result || return
	kernel_stack_start=$1
	kernel_stack_stop=$2

	set -- Dummy $WORK_DUMPS_DIR/* || return
	local Start Stop Perm Offset Name Dummy
	local is_ignored
	#	is_ignored=0
	PT_LOAD_FILES=""
	while :; do
		shift || return
		read Start Stop Perm Offset Name Dummy || break
		IsIgnoredSegment $1    || return
		[ $is_ignored = 1 ]    && continue # skip segment to be ignored
		$D/pt_load_1 $Start $Stop $Perm || return
		PT_LOAD_FILES="$PT_LOAD_FILES $1"
	done || return

	# number of lines in the stdin and $# (number of dump files)
	# should be same.
	[ $# -ne 0 ] && {
		echo "$0: internal problem: \$#=$#. should be 0" 1>&2
		return 1
	}
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
