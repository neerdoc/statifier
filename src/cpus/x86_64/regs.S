# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This code is processor depended !!!
#

#include "regs.inc"

	GET_DATA_ADDR %rax
					# Let restore registers now
	mov 	RBX(%rax),	%rbx	
	mov 	RCX(%rax),	%rcx	
	mov 	RDX(%rax),	%rdx	
	mov 	RSI(%rax),	%rsi	
	mov 	RDI(%rax),	%rdi	
	mov 	RBP(%rax),	%rbp	
					# %rax should be restored last
	mov 	DS(%rax),	%ds	
	mov 	ES(%rax),	%es	
	mov 	FS(%rax),	%fs	
	
	# With RH9.0 (i.e with TLS) I got segfault here
	mov 	GS(%rax),	%gs	
					# orig_rax - what is it ?
	push 	RIP(%rax)		# It is impossible put value to the %rip
					# by the normal way (movl), so
					# I have to use push/ret

					# Because we somehow get here I hope
					# %cs is ok and do not restore it.

	push 	EFLAGS(%rax)		# save it on the stack
					# before return to %rip I will 'popf' it
					# I think flags here pretty useless,
					# but I want be on the safe side...

					# %rsp and %ss - stack pointer and stack
					# segment - our stack already set
					# somehow, leave it as is

	mov 	RAX(%rax),	%rax	# Only register left to resore 
	popf 				# restore processors flags

	ret				# make two things:
					# - restore %rsp to the value which it
					#   has on the entry to the program
					# - transfer control to the 
					#   run-time loader shared library
					#   initialization.
					# And (I hope) do not change too mach
					# eflags
