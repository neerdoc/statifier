# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Debuggers command for dumping maps, registers and coredump to the files

break @BREAKPOINT_START@

# Continue execution - real time loader will finish 
# mapping exe itself and all needed .so library 
# and do relocation.
# Also (depend on LD_BIND_NOW) symbols binding can be done too.
# Loader will stop on breakpoint just before running .so _init function
run_continue

# Save mappings. I need it for start/stop addreses of the segments
# debugers core-file has start address too, but it miss stop address
shell echo "STATIFIER_FILE_SEPARATOR maps"
	info proc mapping
shell echo "STATIFIER_FILE_SEPARATOR_END"

shell echo "STATIFIER_FILE_SEPARATOR registers"
	info registers
shell echo "STATIFIER_FILE_SEPARATOR_END"

# Save core dump - I need it to get maps permissions
generate-core-file @CORE_FILE@

# Here I'll run shell script, which got as input 
# - @MAP_FILE@ file
# and create as output file with dump command for gdb.
# this dumps command should save all programms memory mappings.
# show memory protection.
shell @SPLIT_SH@ @LOG_FILE@                               || kill $PPID
shell @DUMPS_SH@ @MAPS_FILE@ @WORK_DUMPS_DIR@ @DUMPS_GDB@ || kill $PPID

#quit
