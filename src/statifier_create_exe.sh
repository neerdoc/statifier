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

	# For Linux before 2.5 I only need to ignore stack segment last
	# In the 2.5-2.6 kernel ? create one more segment, which contains
	# ELF heasder of something (what is it ?)
	# So, if last dump file has elf-header, i need to ignore it and
	# stack segment, i.e IgnoredSegments=2.
	# Otherwis I need to ignore onle stack segment, i.e IgnoreSegment=1
	# Let's implement it.
	local IgnoredSegments
	local LastFileName
	local Output
	while [ $# -ne 1 ]; do
		shift || return
	done
	LastFileName=$1
	Output=`$D/elfinfo $LastFileName` || return
	case "x$Output" in
		x[Ee][Ll][Ff]) IgnoredSegments=2;; # Kernel 2.5+
		*)             IgnoredSegments=1;; # Kernel < 2.5
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
	local DumpFiles=""
	while [ $# -gt $IgnoredSegments ]; do
		echo $1 || return
		shift   || return
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

	local STARTER=$WORK_OUT_DIR/starter
	local FIRST_SEGMENT=$WORK_OUT_DIR/first.seg

	local IGNORED_SEGMENTS
	local DUMP_FILES

	IGNORED_SEGMENTS=`GetIgnoredSegments $WORK_DUMPS_DIR/*` || return
	DUMP_FILES="`GetDumpFiles $IGNORED_SEGMENTS $WORK_DUMPS_DIR/*`" || return
	$D/phdrs $OrigExe $CORE_FILE $STARTER $IGNORED_SEGMENTS $DUMP_FILES > $FIRST_SEGMENT || return
	rm -f $NewExe || return
	cat $FIRST_SEGMENT $DUMP_FILES > $NewExe || return
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

[ $# -ne 1 -o "x$1" = "x" ] && {
	Echo "Usage: $0 <work_dir>"
	exit 1
}

WORK_DIR=$1

SetVariables $WORK_DIR || exit
Main                   || exit
exit 0
