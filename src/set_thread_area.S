# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This code is processor depended !!!
#
# RH9.0 used TLS - thread local storage.

REG_SIZE = 4
EAX          = 0 * REG_SIZE
ENTRY_NUMBER = 1 * REG_SIZE
BASE         = 2 * REG_SIZE
LIMIT        = 3 * REG_SIZE
FLAGS        = 4 * REG_SIZE
NEXT_CODE    = 5 * REG_SIZE  # Should be last !!!

	call	addr
addr:
	popl	%eax
	addl	$(data - addr), %eax
	pushl	FLAGS(%eax)
	pushl	LIMIT(%eax)
	pushl	BASE(%eax)
	pushl	ENTRY_NUMBER(%eax)
	movl	EAX(%eax), %eax
	movl	%esp,	%ebx
	int	$0x80
	# Restore stack pointer now
	popl	%ebx
	popl	%ebx
	popl	%ebx
	popl	%ebx
	jmp	data + NEXT_CODE

data:
	# Here will be arguments for set_thread_area
