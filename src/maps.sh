#!/bin/sh

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

[ $# -ne 2 -o "x$1" = "x" -o "x$2" = "x" ] && {
	echo "Usage: $0 <process_file> <maps_file>" 1>&2
	exit 1
}
process_file=$1
maps_file=$2

# Process file is output from gdb's info process and
# has following format: (without #)
#process 24039
#cmdline = '/bin/df'
#cwd = '/home/users/valery'
#exe = '/bin/df'

# Get PID of inspected file
read dummy1 pid dummy2 < $process_file || exit
rm -f $maps_file || exit

awk '{
	StartStop  = $1
	Permission = $2
	Offset     = $3
	Device     = $4
	Inode      = $5
	Name       = $6
	sub("-", " ", StartStop);
	printf "%s %s %s %s\n", StartStop, Permission, Offset, Name
}' < /proc/$pid/maps > $maps_file || exit
exit 0
