# Copyright (C) 2004-2007 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

#############################################
# Defines for some commands we'll use later #
#############################################
# Command for print "start separator"
define my_separator
	echo \nSTATIFIER_FILE_SEPARATOR $arg0\n
end

# Command for print "end separator"
define my_separator_end
	echo STATIFIER_FILE_SEPARATOR_END\n
end

# Script dumps.sh generate 'my_dump' commands
# Let us translate it to the regular gdb's 'dump'.
# Reason why I not generate raw gdb's 'dump' in the script is following:
# I need to have object file name on the same line for future processing,
# but gdb does not accept comments in the end of dump command.
# So, I'll do this trick with a macro, which just ignore last argument
# Last argument (object file name) simply ignored by macro.

# arg0 - filename
# arg1 - start address
# arg2 - stop address
# arg3 - (dummy) objfile name
define my_dump
	dump binary memory $arg0 $arg1 $arg2
end

# Conditional delete
define my_delete
	if ($arg0 == 0) 
		delete
	end
end
#################################################

# Now, let us set breakpoints of interest

###################
# SET_THREAD_AREA #
###################
# Debuggers command for dumping set_thread_area parameters.
# Please note, this command should be invoked ONLY on system with
# thread local storage support. (i.e with val_has_tls = 1)
# One more thing - it's linux specific

# Set breakpoint just before 'set_thread_area' syscall 
# I got this address from 'set_thread_area_addr' program

# source set_thread_area file with define for set_thread_area command
source @SET_THREAD_AREA_GDB@

break *($BREAKPOINT_THREAD + $val_offset)
commands
	silent
	my_separator set_thread_area
		set_thread_area
	my_separator_end
	continue
end

my_delete $val_has_tls

# Debuggers command for dumping maps and registers to the files

# When hit this breakpoint real time loader will finish 
# mapping exe itself and all needed .so library 
# and do relocation.
# Also (depend on LD_BIND_NOW) symbols binding can be done too.
# Loader will stop on this breakpoint just before running .so _init function
break *($BREAKPOINT_START + $val_offset)
commands
	silent
	# Save process id. I need it to get memory mappings from the /proc
	my_separator process
		info proc
	my_separator_end

	# Save registers
	my_separator registers
		info registers
	my_separator_end

	# Here I'll run shell script, which got as input 
	# - @MAP_FILE@ file
	# and create as output file with dump command for gdb.
	# this dumps command should save all program's memory mappings.
	shell @SPLIT_SH@ @LOG_FILE@                               || kill $PPID
	shell @MAPS_SH@  @PROCESS_FILE@ @MAPS_FILE@ @val_uname_m@ || kill $PPID
	shell @DUMPS_SH@ @MAPS_FILE@ @WORK_DUMPS_DIR@ @DUMPS_GDB@ || kill $PPID

	# "Run" command for save memory's mappings
	source @DUMPS_GDB@
	# kill debugged program. without this instruction
	# on some kernels (for example FC5) program
	# not killed, but continued to run :(
	kill

	# This breakpoint should be last (in order of execution)
	# so there is NO continue command here
end
# We got here when the program is stopped on it's very first instruction

# Print stack pointer and loader's offset
my_separator misc.src
	printf "val_stack_pointer=0x%lx\n", $sp
	printf "val_offset=0x%lx\n", $val_offset
my_separator_end

# I'll get process ID from here
my_separator process
	info proc
my_separator_end

# The ld-linix (2.3.3) got a bad inhabit to split stack into to segments:
# one with 'rwx' permissions and another one with  'rw-'.
# Later I'll use $sp to find out stack segment, but it doesn't help
# much if stack is splitted to two segments.
# So, here I safe initial mappings, with stack segment created by kernel
# and yet not modified by loader.
# It'll help me later to find both of the stack segments.

# Save initial mappings
# I use 'info proc mappings' instead of MAPS_SH, because at this point
# I haven't got PROCESS_FILE.'
# Anyway, from this mapping i need only addresses, not permissions,
# so it's ok
# It was OK, now (at least FC5) it is not.
# On FC5 'info proc mappings' for some strange reason give me only vdso
# mappings, but MAPS_SH (i.e cat /proc/PID/maps work OK).
#
# So let us split log file here (I need procees id)
shell @SPLIT_SH@ @LOG_FILE@ || kill $PPID

# And now run MAPS_SH, to get initial mappings
shell @MAPS_SH@  @PROCESS_FILE@ @INIT_MAPS_FILE@ @val_uname_m@ || kill $PPID

#my_separator init_maps
#	info proc mappings
#my_separator_end

# Save registers' value passed by kernel to the program.
# It'll serve two purposes: my curiosity and debug
# Now it's NOT used in the statifying process.
my_separator regs_from_kernel
		info registers
my_separator_end

# clear trace bit
clear_trace_bit

# Do everything.
# When program will be run, it will hit a first breakpoint, stopped
# and gdb will execute all commands assotiaited with this breakpoint.
# last command - continue, so program will continue to next breakpoint.
# Where gdb will execute all commands assotiated with this breakpoint.
# Last command - continue, so it'll be procedded to the next one, etc.
# Last breakpoint have no continue command, so gdb (and program) will 
# be finished/
continue
#quit
