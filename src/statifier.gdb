# Copyright (C) 2004 Valery Reznic
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
# NOTE: 
# I hope, hope, hope, that load address of dynamic loader does not
# change from one invokation to another.
# Otherwise i'll need to convert 'set_thread_area_addr' program
# to something like mini-debugger - with breakpoint,
# registers/memory dumps, etc.
# It will be nice to get rid of gdb, but from other hand
# support for breakpoint on different platforms is not an easy task. 

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

# Debuggers command for dumping maps, registers and coredump to the files

# When hit this breakpoint real time loader will finish 
# mapping exe itself and all needed .so library 
# and do relocation.
# Also (depend on LD_BIND_NOW) symbols binding can be done too.
# Loader will stop on this breakpoint just before running .so _init function
break *($BREAKPOINT_START + $val_offset)
commands
	silent
	# Save mappings. I need it for start/stop addreses of the segments
	# debugers core-file has start address too, but it miss stop address
	my_separator maps
		info proc mapping
	my_separator_end

	# Save registers
	my_separator registers
		info registers
	my_separator_end

	# Save core dump - I need it to get maps permissions
	generate-core-file @CORE_FILE@

	# Here I'll run shell script, which got as input 
	# - @MAP_FILE@ file
	# and create as output file with dump command for gdb.
	# this dumps command should save all programms memory mappings.
	# show memory protection.
	shell @SPLIT_SH@ @LOG_FILE@                               || kill $PPID
	shell @DUMPS_SH@ @MAPS_FILE@ @WORK_DUMPS_DIR@ @DUMPS_GDB@ || kill $PPID

	# "Run" command for save memory a mappings
	# Note, I create @DUMPS_GDB@ shell before running gdb,
	# so if gdb for some reason failed create this file
	# previous one will kill gdb
	source @DUMPS_GDB@

	# This breakpoint should be last (in order of execution)
	# so there is NO continue command here
end

# Print stack pointer and loader's offset
my_separator misc.src
	printf "stack_pointer=0x%x\n", $sp
	printf "val_offset=0x%x\n", $val_offset
my_separator_end
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
