# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Debuggers command for dumping set_thread_area parameters for x86_64
define set_thread_area
	# Here syscall's number
	info register rax
	# Here parameters for syscall
	set $register_size = 8
	x $rbx + ($register_size * 0)
	x $rbx + ($register_size * 1)
	x $rbx + ($register_size * 2)
	x $rbx + ($register_size * 3)
end
