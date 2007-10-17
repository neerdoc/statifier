# Copyright (C) 2005-2007 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Debuggers command for clear trace bit in the processor's status for x86_64

# Explanation, why need 'si 10' see in the ../i386/clear_trace_bit.gdb

# gdb6.6 won't work without cast to (unsigned int)
define clear_trace_bit
	si 10
	set $eflags = (unsigned int)($eflags & ~ 0x100)
end
