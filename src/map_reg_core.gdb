# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Debuggers command for dumping maps, registers and coredump to the files

# Specify file to run
file @EXECUTABLE_FILE@

# I don't want debugger prompt me to type enter, 
# so make gdb think a terminal is a very big.
set height 10000

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

# Save mappings. I need it for start/stop addreses of the segments
# debugers core-file has start address too, but it miss stop address
shell echo "STATIFIER_FILE_SEPARATOR"
info proc mapping

shell echo "STATIFIER_FILE_SEPARATOR"
info registers
shell echo "STATIFIER_FILE_SEPARATOR"

# Save core dump - I need it to get maps permissions
generate-core-file @CORE_FILE@

# Here I'll run shell script, which got as input 
# - @MAP_FILE@ file
# and create as output file with dump command for gdb.
# this dumps command should save all programms memory mappings.
# show memory protection.
shell @SPLIT_SH@ @LOG_FILE@ @MAPS_FILE@ @REGISTERS_FILE@ || kill $PPID
shell @DUMPS_SH@ @MAPS_FILE@ @WORK_DUMPS_DIR@ @DUMPS_GDB@ || kill $PPID
#quit
