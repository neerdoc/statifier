#!/bin/sh

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

[ $# -ne 3 -o "x$1" = "x" -o "x$2" = "x" -o "x$3" = "x" ] && {
	echo "Usage: $0 <maps_file> <dir_for_dumps> <gdb_dump_commands_file>" 1>&2
	exit 1
}

Maps=$1
DumpsDir=$2
Output=$3

awk -vDumpsDir="$DumpsDir" '
	BEGIN {
		FileNumber = 1;
	}
	{
		StartAddr = $1
		EndAddr   = $2
		ObjFile   = $5
                FileName  = sprintf("%s/%.6d.dmp", DumpsDir, FileNumber);
		FileNumber++
   		printf "my_dump %s %s %s %s\n", FileName, StartAddr, EndAddr, ObjFile;
	}
' < $Maps > $Output || exit
exit 0 

# This awk get input looks like following:
# Start Stop Permission Offset FileName
