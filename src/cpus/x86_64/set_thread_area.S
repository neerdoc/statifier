# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This code is processor depended !!!
#
# RH9.0 used TLS - thread local storage.

MY_DATA SYSCALL_NUM
MY_DATA ENTRY_NUMBER
MY_DATA BASE
MY_DATA LIMIT
MY_DATA FLAGS

	GET_DATA_ADDR %rax

	push 	FLAGS(%rax)
	push 	LIMIT(%rax)
	push 	BASE(%rax)
	push 	ENTRY_NUMBER(%rax)
	mov 	SYSCALL_NUM(%rax), %rax
	mov 	%rsp,	%rbx
	syscall
	# Restore stack pointer now
	pop 	%rbx
	pop 	%rbx
	pop 	%rbx
	pop 	%rbx
