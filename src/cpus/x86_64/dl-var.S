# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This code is processor depended !!!

# Adjust some _dl variables.

# It is file with AT_ includes generated from /usr/include/elf.h
#include <AT.h>

MY_DATA BASE
MY_DATA DL_ARGC
MY_DATA DL_ARGV
MY_DATA ENVIRON
MY_DATA DL_AUXV
MY_DATA DL_PLATFORM      /* May be 0 */
MY_DATA DL_PLATFORMLEN   /* May be 0 */

	GET_DATA_ADDR	%rdx

	mov 	%rsp,		%rax	# rax = &argc_on_the_stack
	mov 	(%rax),		%rcx	# rcx = argc
	push 	%rcx			# save argc

	add 	$REG_SIZE,	%rax	# rax = &argv_on_the_stack
	push 	%rax			# save argv

	inc 	%rcx			# rcx = argc + 1

	add  	%rcx,		%rax	
	add  	%rcx,		%rax	
	add  	%rcx,		%rax	
	add  	%rcx,		%rax	
	add  	%rcx,		%rax	
	add  	%rcx,		%rax	
	add  	%rcx,		%rax	
	add  	%rcx,		%rax	# rax = argv + (argc + 1) * REG_SIZE,
					# i.e, rax = &env

	push 	%rax			# save _environ
	
	jmp	f_auxv_0
f_auxv:
	add 	$REG_SIZE,	%rax
f_auxv_0:
	cmp 	$0, (%rax)
	jne	o_auxv			# yet no found end of environment
o_auxv:
	add 	$REG_SIZE,	%rax    # found, skip NULL. now %rax = _dl_auxv
	mov 	%rax,		%rcx	# rcx = rax = &_dl_auxv

	mov 	BASE(%rdx),	%rax	# rax - base address of elf-interpreter

	mov 	DL_AUXV(%rdx),	%rbx	# rbx = &_dl_auxv
	mov 	%rcx,	(%rbx,%rax)	#

	mov 	ENVIRON(%rdx),	%rbx	# rbx = &_environ
	pop 	(%rbx,%rax)
	mov 	DL_ARGV(%rdx),	%rbx	# rbx = &_dl_argv
	pop 	(%rbx,%rax)
	mov 	DL_ARGC(%rdx), 	%rbx	# rbx = &_dl_args
	pop 	(%rbx,%rax)

	# Now i am going process _dl_auxv.
	# I am looking for AT_BASE and AT_PLATFORM
	# Finish on AT_NULL
	jmp	auxv_0
auxv:
	add 	$(REG_SIZE + REG_SIZE),	%rcx	# next auxv entry
auxv_0:
	cmp 	$AT_BASE, (%rcx)
	je	auxv_base
	cmp 	$AT_PLATFORM, (%rcx)
	je	auxv_platform
	cmp 	$AT_NULL, (%rcx)
	je	auxv_end
	jmp	auxv
auxv_base:
	mov	%rax,	REG_SIZE(%rcx)
	jmp	auxv
auxv_platform:
	mov 	DL_PLATFORM(%rdx),	%rbx	# rbx = &_environ
	cmp 	$0,	%rbx			# have i platform addr ?
	je	plat_len			# no
	push 	REG_SIZE(%rcx)
	pop 	(%rbx,%rax)
	cmp 	$0,	REG_SIZE(%rcx)		# Is it NULL ?
	je	auxv
	# Now find out _dl_platformlen
plat_len:
	mov 	REG_SIZE(%rcx),	%rsi	# address of _dl_platform
	jmp	platform_len_0
platform_len:
	inc 	%rsi
platform_len_0:
	cmpb	$0,	(%rsi)
	jne	platform_len
platform_len_end:	
	dec 	%rsi
	mov 	DL_PLATFORMLEN(%rdx),	%rbx	# rbx = &_environ
	cmp 	$0,	%rbx			# have i platformlen addr ?
	je	auxv				# no
	mov 	%rsi,	(%rbx,%rax)

	jmp	auxv
auxv_end:
#data:
#BASE:		.long 0x40000000
#DL_ARGC:	.long 0x00015ec4
#DL_ARGV:	.long 0x00015ec8
#ENVIRON:	.long 0x00015890
#DL_AUXV:	.long 0x12345678
#PLATFORM:	.long 0x12345678
