# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Debuggers command for dumping arch_prctl parameters for x86_64
define set_thread_area
	# Here syscall's number
	info register rax
	# Here parameters for syscall
	# function number (edi)
	info register rdi
	# address
	info register rsi
end
