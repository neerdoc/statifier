#!/bin/sh

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

[ $# -ne 3 -o "x$1" = "x" -o "x$2" = "x" -o "x$3" = "x" ] && {
	echo "Usage: $0 <process_file> <maps_file> <uname_m>" 1>&2
	exit 1
}
process_file=$1
maps_file=$2
uname_m=$3

# Process file is output from gdb's info process and
# has following format: (without #)
#process 24039
#cmdline = '/bin/df'
#cwd = '/home/users/valery'
#exe = '/bin/df'

# Get PID of inspected file
read dummy1 pid dummy2 < $process_file || exit
rm -f $maps_file || exit

awk -v uname_m="$uname_m" '{
	StartStop  = $1
	Permission = $2
	Offset     = $3
	Device     = $4
	Inode      = $5
	Name       = $6
	if (uname_m == "x86_64") {
		# (at least) linux 2.6.9 on amd64 
		# (2.6.9-1.667smp) has vsyscall area,
		# which can`t be dumped by gdb.
		# So, let us skip it (anyway i don`t need it)
        	if (StartStop == "ffffffffff600000-ffffffffffe00000") next;
	}
	split(StartStop, Array, "-");
	printf "0x%s 0x%s %s 0x%s %s\n", Array[1], Array[2], Permission, Offset, Name
}' < /proc/$pid/maps > $maps_file || exit
exit 0
