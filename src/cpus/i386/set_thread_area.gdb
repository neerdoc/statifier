# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Debuggers command for dumping set_thread_area parameters.
# Please note, this file should be invoked ONLY on system with
# thread local storage support.
# One more thing - it's linux specific

# Set breakpoint just before 'set_thread_area' syscall 
# I got this address from 'set_thread_area_addr' program
# NOTE: 
# I hope, hope, hope, that load address of dynamic loader does not
# change from one invokation to another.
# Otherwise i'll need to convert 'set_thread_area_addr' program
# to something like mini-debugger - with breakpoint,
# registers/memory dumps, etc.
# It will be nice to get rid of gdb, but from other hand
# support for breakpoint on different platforms is not an easy task. 
break @BREAKPOINT_THREAD@

# let's run now till breakpoint
run_continue

# Now dump information:
shell echo "STATIFIER_FILE_SEPARATOR set_thread_area"
	# Here syscall's number
	info register eax
	# Here parameters for syscall
	set $register_size = 4
	x $ebx + ($register_size * 0)
	x $ebx + ($register_size * 1)
	x $ebx + ($register_size * 2)
	x $ebx + ($register_size * 3)
shell echo "STATIFIER_FILE_SEPARATOR_END"
