#!/bin/bash

# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

function IsStack
{
	if [[ $StackAddr -ge $Start && $StackAddr -lt $Stop ]]; then 
		# It's stack seg
		is_stack=1
	else
		is_stack=0
	fi
	return 0
}

function IsLinuxGate
{
	# To do
	is_linux_gate=0
	return 0
}

[ $# -ne 1 -o "x$1" = "x" ] && {
	echo "Usage $0: <stack_addr>" 1>&2
	exit 1
}

StackAddr=$1
D=`dirname $0` || exit
while :; do
	read Start Stop Perm Offset Name Dummy || break
	IsStack                || exit
	[ $is_stack = 1 ]      && continue # skip stack segment
	IsLinuxGate            || exit 
	[ $is_linux_gate = 1 ] && continue # skip linux-gate segment
	$D/pt_load_1 $Start $Stop $Perm || exit
done || exit
exit 0
