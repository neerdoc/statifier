# Copyright (C) 2004, 2005 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Syscalls defines for i386
# syscall instruction is 'int 0x80'
# first byte
set $val_syscall_byte_1 = 0xcd
# second byte
set $val_syscall_byte_2 = 0x80
# bytes number
set $val_syscalls_bytes = 2
