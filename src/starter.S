# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This code is processor depended !!!
#
# RH9.0 used TLS - thread local storage.
# It is why I got segfault
# when I try write to %gs - I have to fix it.
# 
# x[3]86 has 32 bits registers 

REG_SIZE = 4

# It was translated from the struct user_reg_struct
# (file /usr/include/sys/user.h)

EBX      =  0 * REG_SIZE
ECX      =  1 * REG_SIZE
EDX      =  2 * REG_SIZE
ESI      =  3 * REG_SIZE
EDI      =  4 * REG_SIZE
EBP      =  5 * REG_SIZE
EAX      =  6 * REG_SIZE
DS       =  7 * REG_SIZE
ES       =  8 * REG_SIZE
FS       =  9 * REG_SIZE
GS       = 10 * REG_SIZE
ORIG_EAX = 11 * REG_SIZE  # what is orig_eax good for ? 
EIP      = 12 * REG_SIZE
CS       = 13 * REG_SIZE
EFLAGS   = 14 * REG_SIZE
ESP      = 15 * REG_SIZE
SS       = 16 * REG_SIZE

	call	addr			# really this instruction 
					# push 'addr' to the stack
addr:
	popl	%eax			# now got it to the %eax
	addl	$(regs - addr), %eax	# now %eax point to the regs: -
					# it is begin of the area were 
					# registers values are stored

					# Let restore registers now
	movl	EBX(%eax),	%ebx	
	movl	ECX(%eax),	%ecx	
	movl	EDX(%eax),	%edx	
	movl	ESI(%eax),	%esi	
	movl	EDI(%eax),	%edi	
	movl	EBP(%eax),	%ebp	
					# %eax should be restored last
	movl	DS(%eax),	%ds	
	movl	ES(%eax),	%es	
	movl	FS(%eax),	%fs	
	
	# With RH9.0 (i.e with TLS I got segfault here)
	movl	GS(%eax),	%gs	
					# orig_eax - what is it ?
	pushl	EIP(%eax)		# It is impossible put value to the %eip
					# by the normal way (movl), so
					# I have to use pushl/ret

					# Because we somehow get here I hope
					# %cs is ok and do not restore it.

	pushl	EFLAGS(%eax)		# save it on the stack
					# before return to %eip I'll 'popf' it.
					# I think flags here pretty useless,
					# but let's be on the safe side...

					# %esp and %ss - stack pointer and stack
					# segment - our stack already set
					# somehow, live it as is

	movl	EAX(%eax),	%eax	# Only register left to resore 
	popf				# restore processor's flags

	ret				# make two things:
					# - restore %esp to the value which it
					#   has on the entry to the program
					# - transfer control to the 
					#   run-time loader shared library
					#   initialization.
					# And (I hope) do not change too mach
					# eflags
regs:
	# Here will be registers values
