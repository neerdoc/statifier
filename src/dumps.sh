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
   		printf "my_dump %s 0x%s 0x%s %s\n", FileName, StartAddr, EndAddr, ObjFile;
	}
' < $Maps > $Output || exit
exit 0 

# This awk get input looks like following:
# (without '#') and generate command file for gdb with 'my_dump' commands
#process 24039
#cmdline = '/bin/df'
#cwd = '/home/users/valery'
#exe = '/bin/df'
#Mapped address spaces:
#
#	Start Addr   End Addr       Size     Offset objfile
#	 0x8048000  0x804f000     0x7000          0     /bin/df
#	 0x804f000  0x8050000     0x1000     0x6000     /bin/df
#	0x40000000 0x40015000    0x15000          0     /lib/ld-2.2.4.so
#	0x40015000 0x40016000     0x1000    0x14000     /lib/ld-2.2.4.so
#	0x40016000 0x40017000     0x1000          0        
#	0x4002d000 0x40159000   0x12c000          0     /lib/libc-2.2.4.so
#	0x40159000 0x4015f000     0x6000   0x12b000     /lib/libc-2.2.4.so
#	0x4015f000 0x40163000     0x4000          0        
#	0xbfffe000 0xc0000000     0x2000 0xfffff000        
