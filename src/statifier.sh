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

function GetElfClass
{
	res="`readelf --file-header $OrigExe`" || return 
	echo "$res" | awk '{
		if ($NF == "ELF32") { print "32"; exit 0;}
		if ($NF == "ELF64") { print "64"; exit 0;}
	}' || return
	return 0
}

function Main
{
	Sanity || return

	local ElfClass
	ElfClass=`GetElfClass`
	[ "x$ElfClass" = "x" ] && {
		echo "$0: Can't determine ELF CLASS for the '$OrigExe'" 1>&2
		return 1
	}

	D=$D/$ElfClass
	[ -d $D ] || {
		echo "$0: ElfClass '$ElfClass' do not supported on this system." 1>&2
		return 1
	}

	# Prepare directory structure
	mkdir -p $WORK_COMMON_DIR  || return
	mkdir -p $WORK_GDB_CMD_DIR || return
	mkdir -p $WORK_GDB_OUT_DIR || return
	mkdir -p $WORK_DUMPS_DIR   || return
	mkdir -p $WORK_OUT_DIR     || return

	# Do it
	$D/statifier_common.sh         $WORK_DIR $OrigExe || return
	$D/statifier_before_dump.sh    $WORK_DIR          || return
	$D/statifier_dump.sh           $WORK_DIR          || return
	$D/statifier_before_starter.sh $WORK_DIR          || return
	$D/statifier_create_starter.sh $WORK_DIR          || return
	$D/statifier_create_exe.sh     $WORK_DIR $NewExe  || return
	return 0
}

#################### Main Part ###################################
[ $# -ne 2 -o "x$1" = "x" -o "x$2" = "x" ] && {
	echo "Usage: $0 <orig_exe> <statified_exe>" 1>&2
	exit 1
}

OrigExe=$1
NewExe=$2

# Temporary Work Directory
WORK_DIR="${TMPDIR:-/tmp}/statifier.tmpdir.$$"
#WORK_DIR="./.statifier"

# Where Look For Other Programs
D=`dirname $0`              || exit
source $D/statifier_lib.src || exit

rm   -rf $WORK_DIR          || exit
mkdir -p $WORK_DIR          || exit
Main
st=$? 
rm -rf $WORK_DIR || exit
exit $st
