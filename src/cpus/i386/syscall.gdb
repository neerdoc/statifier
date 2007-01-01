# Copyright (C) 2004-2007 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Syscalls defines for i386
define is_it_syscall
	# syscall instruction is 'int 0x80'
	is_it_syscall_2 0xcd 0x80

	# Additional syscall instruction is 'sysenter'
	# There are boxes, where this instrucion used in VDSO
	is_it_syscall_2 0x0f 0x34
end
