# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Debuggers command for dumping maps, registers and coredump to the files

# I want all gdb messages going to log file, not to the terminal, so...
set logging overwrite on
set logging redirect  on
set logging file @LOG_FILE@
set logging on

# I don't want debugger prompt me to type enter, 
# so make gdb think a terminal is a very big.
set height 10000

# Specify file to run
file @EXECUTABLE_FILE@

# I need to set breakpoint on _dl_start_user (for linux) 
# But before I run program I can't got (from gdb) _dl_start_user address.
# So, trick is following:
#   1) set stop-on-solib-event
#   2) run program.
#      It will be run till shared library event.
#      Now, sure real-time loader is up, so I can get _dl_start_user's address.
#   3) set break point on _dl_start_user
#   4) unset stop on solib-events 
#   5) Continue.
#   6) Next stop - is _dl_start_user
set stop-on-solib-events 1
run
set stop-on-solib-events 0
break @BREAKPOINT@

# Continue execution - real time loader will finish 
# mapping exe itself and all needed .so library 
# and do relocation.
# Also (depend on LD_BIND_NOW) symbols binding can be done too.
# Loader will stop on breakpoint just before running .so _init function
continue

# Close our log file
set logging off

# I don't want accumulate information from different invokation
set logging overwrite on
# I don't want to see on the terminal what going to the file
set logging redirect  on

# Set logging file
set logging file @MAPS_FILE@
# Enable logging
set logging on
# Next command output will go to the file.
# Save mappings. I need it for start/stop addreses of the segments
# debugers core-file has start address too, but it miss stop address
info proc mapping
# Disable logging - just in case
set logging off

# Set logging file to save registers
# I know, registers may be found in the coredump,
# but I afraid it will be too kernel's version dependend
set logging file @REGISTERS_FILE@
# Enable logging 
set logging on
# Save registers values in the file
info registers
# Disable logging - I don't want additional output going here
set logging off

# Once again - redirect gdb messages to the file
# But now I want append to existing one
set logging overwrite off 
# As usual - I don't want see it on the terminal
set logging redirect  on
# Set file for logging
set logging file @LOG_FILE@
# Enable logging
set logging on

# Save core dump - I need it to get maps permissions
generate-core-file @CORE_FILE@

# Close log file
set logging off

# Here I'll run shell script, which got as input 
# - @MAP_FILE@ file
# and create as output file with dump command for gdb.
# this dumps command should save all programms memory mappings.
# show memory protection.
shell @DUMPS_SH@ @MAPS_FILE@ @WORK_DUMPS_DIR@ @DUMPS_GDB@ || kill $PPID
#quit
