# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Syscalls defines for alpha
# syscall instruction is 'callsys'
# first byte
set $val_syscall_byte_1 = 0x83
# second byte
set $val_syscall_byte_2 = 0x00
# third  byte
set $val_syscall_byte_3 = 0x00
# fourth byte
set $val_syscall_byte_4 = 0x00
# bytes number
set $val_syscalls_bytes = 4
