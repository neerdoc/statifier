# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This gdb file (with help from gdb_runner) should
# stop dynamic linked executable on the first loader's instruction.
# When exec-shield or exec-shield+ranodomizing or similar techique
# is in use it's hard/impossible to predict vere loader itself
# will be loaded, and where breakpoints should be set. 
# The idea is following:
# Take control over gdb_runner, and execute it intsruction by instruction,
# looking for instruction 'syscall'
# When syscall found next 'si' will execute "program of interest",
# and loader will be stopped on it's first instruction.
# Address of this instruction minus entry point's address taken 
# from file will give us offset, which should be added
# to all loader's addresses found in the file.
# After that I can invoke statifier.gdb to do real work.

# Read in system depended const
source @SYSCALL_GDB@

# Read in system dependent variables
source @VAR_GDB@

# Read in (optional) setenv commands
source @ENV_GDB@

### Initialize some gdb variables ###

# I don't want debugger prompt me to type enter, 
# so make gdb think a terminal is a very big.
set height 10000

# Specify file to run
# Pay attention, gdb will not read symbols from it
exec-file @GDB_RUNNER@

# I have two differen problem with gdb messages:
# 1) For gdb >= 6.0 
#   messages like:
#   <line:> <file>: No such file or directory

# 2) For alpha and mips platform message
#    warning: Hit heuristic-fence-post without finding
#    warning: enclosing function for address 0xXXXXXXX     

# There are two way to eliminate first one:
# - 'silent' in the commands for breakpoint
# - set auto-solib-add off
# Second message can be eliminated only by 'set auto-solib-add one'
# (I.e on alpha I have to have symbols table for the loader)

# So,  anyway I put 'silent' in the command
# and I'll set auto-solib-add 'off' or 'on' depend on 
# the 'val_has_hit_msg' variable.
# It will work if always on, but I want it off when possible
# (for perfomance and simplicity reason)
if $val_has_hit_msg
	set auto-solib-add on
else
	set auto-solib-add off
end

# Some defines for find "syscall" instruction

# For system where "syscall" instruction is 4 bytes long
# test if current instruction is "syscall"
define is_it_syscall_4
	if (*($my_pc) == $val_syscall_byte_1)
		if (*($my_pc+1) == $val_syscall_byte_2)
			if (*($my_pc+2) == $val_syscall_byte_3)
				if (*($my_pc+3) == $val_syscall_byte_4)
					set $it_is_syscall = 1
				end
			end
		end
	end
end

# For system where "syscall" instruction is 2 bytes long
# test if current instruction is "syscall"
define is_it_syscall_2
	if (*($my_pc) == $val_syscall_byte_1)
		if (*($my_pc+1) == $val_syscall_byte_2)
			set $it_is_syscall = 1
		end
	end
end

# test if current instruction is "syscall"
define is_it_syscall
	if ($val_syscalls_bytes == 2)
		is_it_syscall_2
	else
		if ($val_syscalls_bytes == 4)
			is_it_syscall_4
		else
			shell echo "gdb: unsupported syscalls_bytes: should be 2 or 4" 1>&2
			quit 1
		end
	end
end

# Main part
# Catch sigquit signal (gdb_runner will send it to itself)
handle SIGQUIT stop nopass

# run gdb_runner with parameter "program to be statified"
run @EXECUTABLE_FILE@

# step instruction by instruction while "syscall" instruction found.
# gdb_runner written in the way, that first syscall instruction after
# gdb got signal is execve. So don't need to check register's value
# for syscall number 
set $my_continue = 1
set $it_is_syscall = 0
set $my_count = 0
set $my_count_limit = 100
# Keep stepping, while syscall found or max step limit reached.
while ( $my_continue == 1 )
	# Increment steps counter
	set $my_count = $my_count + 1
	# next instruction
	si	
	# Cast program counter to pointer to unsigned char
	# my_pc will be used later in the is_it_syscall_* define
	set $my_pc = (unsigned char *)$pc
	# Is it syscall ?
	is_it_syscall
	if ($it_is_syscall == 1)
		# syscall found, set flag to exit from the loop
		set $my_continue = 0
	end

	# When we did too much steps give error message and die
	if ($my_count > $my_count_limit)
		shell echo "gdb: can't find syscall execve." 1>&2 
		quit 1
	end
end

# Just for curious - how many steps was done before syscall found ?
echo my_count=
	output $my_count
echo \n

# Reset  sighandler to defaut.
handle SIGQUIT stop nopass
# Do execve !
si

# For some unknown reason when 'syscall' instruction failed
# process not stopped on the next instruction, but execute it too.
# (at least for x86).
# Generally I don't know ( and don't want to know !) what this instruction do
# so, test if execve succeeded or failed is a bit of problem.

# After successful execve stack will point to argc.
# in our case argc = 1. (no arguments)
# If execve failed sp (I hope) will point to something else.
if ( *(int *)$sp != 1)
	echo Exec problem\n
	# let's run to gdb_runner and print it's error message
	continue
	quit 1
end

# Save interpreter's entry real address
set $val_interpreter_entry = $pc

# Ok, it's not always loader's base address - if
# val_interpreter_file_entry != 0, val_interpreter_file_entry will be real
# loader's address and all file's addresses will be real too.
# In this case 'val_offset' will be 0
set $val_offset = $val_interpreter_entry - $val_interpreter_file_entry

# Ok, all theory above was nice, but...
# In the RHEL WS release 3 (Taroon Update 1)
# after successful execve gdb not stop any more on the first
# loader's instruction, but on the next one.
# On the RHEL AS release 3 (Taroon) it's still ok.
# There are following differences:
#            WS                     AS
#  kernel    2.4.21-9.ELsmp         2.4.21-4.ELsmp
#  glibc     2.3.2-95.6             2.3.2-95.3
#  gdb       6.0post-0.20031117.6rh 5.3.90-0.20030710.40rh
# I have no idea which one (or combination) change the gdb's behavour.
# Anyware, I have to deal with.
# Idea is following: let us hope the first instruction is not 'jump' or 'call'.
# So, progam counter will not changed significantly.
# Because val_offset is multiply of page_size, I can just round it down to the
# multiply of the page_size value.
# Next questions: what is page_size ?
# The smallest one that I saw is 4096 (0x1000)
# But to be on the safe side 
# (assuming first instruction is not 'jump' or 'call')
# we can use some smaller value.
# Let's say 128. (0x100) I have a hard time trying to imagine system
# with page of this size.
set $val_offset = (unsigned long)$val_offset & ~ (unsigned long)(0x100 - 1)  

# now, let us do a real work
# Here I am about to 'source @STATIFIER_GDB@'.
# This file define some commands, set some breakpoints and invoce 'continue'.
# But on alpha (at least) when  I try this 'continue' I got 
# 'Program received signal SIGTRAP, Trace/breakpoint trap.'
# To work around this problem I do   'si', and only after that
# source file.
# It's needed only for alpha but I don't want to insert conditions here,
# so lets do it on any computer.
si
# now, finally, let us do a real work
source @STATIFIER_GDB@
