#!/bin/bash

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This script finally create statified exe

function GetIgnoredSegments
{
	local Func=GetIgnoredSegments
	[ $# -eq 0 ] && {
		Echo "$0: Usage: $Func <file> [<file>...]"
		return 1
	}

	local IgnoredSegments
	case "$prop_stack_under_executable" in
		0) # platform like x86, x86_64
			# For Linux before 2.5 I only need to ignore stack
			# segment (last)
			# In the 2.5-2.6 kernel create one more segment, 
			# which contains
			# ELF heasder of something (what is it ?)
			# But gdb 6.1 (opposite to gdb 6.0) does not save
			# this last elf-segment in the core file
			# For this reason I can't relay on the kernel version
			# So, if last dump file has elf-header,
			# i need to ignore both it and stack segment,
			# i.e IgnoredSegments=2.
	
			# Otherwise I need to ignore only stack segment, 
			# i.e IgnoredSegment=1

			# Let's implement it.
			local LastFileName
			local Output
			while [ $# -ne 1 ]; do
				shift || return
			done
			LastFileName=$1
			Output=`$D/elfinfo $LastFileName` || return
			case "x$Output" in
				x[Ee][Ll][Ff]) IgnoredSegments=2;; # Kernel 2.5+
				*)             IgnoredSegments=1;; # Kernel <2.5
			esac
		;;

		1) # platforms like alpha
			# I have no alpha with 2.6 kernel
			# and I have no idea were I should look 
			# for additional segment (if any)
			# So, for now IgnoredSegments is just 1
			IgnoredSegments=1
		;;
	esac
	echo "$IgnoredSegments" || return
	return 0
}

function GetDumpFiles
{
	local Func="GetDumpFiles"
	[ $# -le 2 -o "x$1" = "x" -o "x$2" = "x" ] && {
		Echo "$0: Usage: $Func <ignored_segments> <file> [<file>...]"
		return 1
	}
	local IgnoredSegments=$1
	case "x$IgnoredSegments" in
		x[0-9] | x[0-9][0-9] | x[0-9][0-9][0-9] | x[0-9][0-9][0-9][0-9])
			: # ok, nothing to do
		;;

		*)
			Echo "$0: $Func: IgnoredSegments='$IgnoredSegments' should be integer."
			return 1
		;;
	esac
	shift # ($# = $# - 1, i.e $# now is number of files)
	[ $IgnoredSegments -gt $# ] && {
		Echo "$0: $Func: try to ignore more files ($IgnoredSegments) than supplied ($#)."
		return 1
	}
	case "$prop_stack_under_executable" in
		0)
			local DumpFiles=""
			while [ $# -gt $IgnoredSegments ]; do
				echo $1 || return
				shift   || return
			done || return
		;;

		1)
			shift # remove first(stack segment)
			echo $@ || return
		;;
	esac
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

	local STARTER=$WORK_OUT_DIR/starter
	local STARTER_SEGMENT=$WORK_OUT_DIR/starter.seg
	local SECTIONS=$WORK_OUT_DIR/sections

	local IGNORED_SEGMENTS
	local DUMP_FILES

	IGNORED_SEGMENTS=`GetIgnoredSegments $WORK_DUMPS_DIR/*` || return
	DUMP_FILES="`GetDumpFiles $IGNORED_SEGMENTS $WORK_DUMPS_DIR/*`" || return
	$D/phdrs                               \
		$STARTER_SEGMENT               \
		$SECTIONS                      \
		$OrigExe                       \
		$CORE_FILE                     \
		$STARTER                       \
		$prop_stack_under_executable   \
		$prop_starter_under_executable \
		$IGNORED_SEGMENTS              \
		$DUMP_FILES                    \
	|| return
	rm -f $NewExe || return
	case "$prop_starter_under_executable" in
		0)
			cat $DUMP_FILES $STARTER_SEGMENT $SECTIONS > $NewExe || return
			$D/copy_ehdr $STARTER_SEGMENT $NewExe || return
		;;

		1)
			cat $STARTER_SEGMENT $DUMP_FILES $SECTIONS > $NewExe || return
		;;
	esac
	chmod +x $NewExe || return
	return 0
}

function Main
{
	set -e
		source $OPTION_SRC || return
		source $COMMON_SRC || return
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

case "x$prop_stack_under_executable" in
	x0 | x1) ;; # ok, do nothing
	*)
		Echo "$0: 'prop_stack_under_executable' has illegal value '$prop_stack_under_executable'
		exit 1
	;;
esac

case "x$prop_starter_under_executable" in
	x0 | x1) ;; # ok, do nothing
	*)
		Echo "$0: 'prop_starter_under_executable' has illegal value '$prop_starter_under_executable'
		exit 1
	;;
esac

SetVariables $WORK_DIR || exit
Main                   || exit
exit 0
