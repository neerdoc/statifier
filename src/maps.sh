#!/bin/sh

# Copyright (C) 2004, 2005 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

[ $# -ne 4 -o "x$1" = "x" -o "x$2" = "x" -o "x$3" = "x" -o "x$4" = "x" ] && {
	echo "Usage: $0 <uname_m> <pid> <output> <output_all_mappings>" 1>&2
	exit 1
}
uname_m=$1
pid="$2"
output="$3"
output_all_mappings="$4"

input="/proc/$pid/maps"
output_orig="$output".orig

cat $input > $output_orig || exit

awk -v uname_m="$uname_m" -v output_all_mappings="$output_all_mappings" '{
	StartStop  = $1
	Permission = $2
	Offset     = $3
	Device     = $4
	Inode      = $5
	Name       = $6
	split(StartStop, Array, "-");
	Start = Array[1]
	Stop  = Array[2]
	if (output_all_mappings == "0") {
		if (Permission == "---p") next
		if (Name == "[vdso]") next
		if (Name == "[stack]") next
		if (Name == "[vsyscall]") next
		if (Start == "ffffffffff600000") {
			if (uname_m == "x86_64") {
				# (at least) linux 2.6.9 on amd64 
				# (2.6.9-1.667smp) has vsyscall area,
				# which can`t be dumped by gdb.
				# So, let us skip it (anyway i don`t need it)
				next
			}
		}
	}
	printf "0x%s 0x%s %s 0x%s %s\n", Start, Stop, Permission, Offset, Name
}' $output_orig > $output || exit
exit 0
