#!/bin/sh

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

[ $# -ne 3 -o "x$1" = "x" -o "x$3" = "x" ] && {
	echo "Usage: $0 <input> <output_1> <output_2>" 1>&2
	exit 1
}
Input=$1
Output1=$2
Output2=$3

awk -vOutput="" -vOutput1="$Output1" -vOutput2="$Output2" '
	BEGIN {
		Index = 0;
		Outputs[0] = "";
		Outputs[1] = Output1;
		Outputs[2] = Output2;
		Outputs[3] = "";
		Output = Outputs[Index];
	}
	{
		if ($0 == "STATIFIER_FILE_SEPARATOR") {
			Index++;
			Output = Outputs[Index];
			next;
		}

		if (Output != "") {
			print $0 >>Output;
		}
	}
' < $Input || exit
exit
