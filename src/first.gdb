# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# It's first command file for gdb.
# Here I do some common settings

# For gdb >= 6.0 
# Prevent messages like:
# <line:> <file>: No such file or directory
set auto-solib-add off

# Specify file to run
exec-file @EXECUTABLE_FILE@

# I don't want debugger prompt me to type enter, 
# so make gdb think a terminal is a very big.
set height 10000

# Here I am going to define command which on first invokation = "run"
# on the following = "continue"
# All following files instead of using "run" or "continue" have use
# "run_continue"
set $run_continue_flag=1

define run_continue
   if $run_continue_flag
      set $run_continue_flag=0
      run
   else
      continue
   end
end
