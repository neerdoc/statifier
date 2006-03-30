# Copyright (C) 2005, 2006 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# Debuggers command for clear trace bit in the processor's status for i386

# gdb-6.4 has strange behavour:
# when trying assign values to registers/processor status word
# in the very beginning of the program,
# it give message:
# 'value being assign to is no longer active.'
# It's looks like this got something with missing frame.
# In order to work around this problem,
# before cleaning trace bit i have do some steps in the program
# Disassembled /lib/ld-linux.so.2
#009eb7a0 <_start>:
#  9eb7a0:       89 e0                   mov    %esp,%eax
#  9eb7a2:       e8 f9 32 00 00          call   9eeaa0 <_dl_start>
#  ...
#009eeaa0 <_dl_start>:
#  9eeaa0:       55                      push   %ebp
#  9eeaa1:       89 e5                   mov    %esp,%ebp
#  9eeaa3:       57                      push   %edi
#
# After 'push %edi' intsruction it's OK to clean trace bit.
# So, 'si 5' enough here, but just to be sure 
# (and for other probably different ld-linux.so) I'll use 'si 10'

define clear_trace_bit
	si 10
	set $eflags = $eflags & ~ 0x100
end
