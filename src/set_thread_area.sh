#!/bin/sh 

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

[ $# -ne 2 -o "x$1" = "x" -o "x$2" = "x" ] && {
	echo "Usage: $0 <input_file> <output_file>" 1>&2
	exit 1
}

Input=$1
Output=$2
TmpFile=$Output.S
D=`dirname $0` || exit

rm -f $TmpFile || exit
awk '
	BEGIN {
		i = 1;
		P[i++] = "SYSCALL_NUM";
		P[i++] = "ENTRY_NUMBER";
		P[i++] = "BASE";
		P[i++] = "LIMIT";
		P[i++] = "FLAGS";
	}
	{
		value = (NR == 1) ? $2 : $NF;	
		printf("%s:\t.long %s\n", P[NR], value);
	}
' < $Input > $TmpFile || exit
Data="`awk '{print $3}' < $TmpFile`" || exit
rm -f $Output || exit
$D/strtoul $Data > $Output || exit

# For gcc / strtoul cross-check 
#gcc $TmpFile -o $Output.1 -Wl,--oformat,binary,--entry,0x0 -nostdlib || exit

exit 0
