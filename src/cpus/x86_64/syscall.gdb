# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Syscalls defines forx86_64 
# syscall instruction is 'syscall'
# first byte
set $val_syscall_byte_1 = 0x0f
# second byte
set $val_syscall_byte_2 = 0x05
# bytes number
set $val_syscalls_bytes = 2
