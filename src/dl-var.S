# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This code is processor depended !!!

# Adjust some _dl variables.

# It is file with AT_ includes generated from /usr/include/elf.h
#include "./AT.h"

MY_DATA BASE
MY_DATA DL_ARGC
MY_DATA DL_ARGV
MY_DATA ENVIRON
MY_DATA DL_AUXV
MY_DATA DL_PLATFORM
MY_DATA DL_PLATFORMLEN

	GET_DATA_ADDR	%edx

	movl	%esp,		%eax	# eax = &argc_on_the_stack
	movl	(%eax),		%ecx	# ecx = argc
	pushl	%ecx			# save argc

	addl	$REG_SIZE,	%eax	# eax = &argv_on_the_stack
	pushl	%eax			# save argv

	incl	%ecx			# ecx = argc + 1

	addl 	%ecx,		%eax	
	addl 	%ecx,		%eax	
	addl 	%ecx,		%eax	
	addl 	%ecx,		%eax	# eax = argv + (argc + 1) * REG_SIZE,
					# i.e, eax = &env

	pushl	%eax			# save _environ
	
	jmp	f_auxv_0
f_auxv:
	addl	$REG_SIZE,	%eax
f_auxv_0:
	cmpl	$0, (%eax)
	jne	o_auxv			# yet no found end of environment
o_auxv:
	addl	$REG_SIZE,	%eax    # found, skip NULL. now %eax = _dl_auxv
	movl	%eax,		%ecx	# ecx = eax = &_dl_auxv

	movl	BASE(%edx),	%eax	# eax - base address of elf-interpreter

	movl	DL_AUXV(%edx),	%ebx	# ebx = &_dl_auxv
	movl	%ecx,	(%ebx,%eax)	#

	movl	ENVIRON(%edx),	%ebx	# ebx = &_environ
	popl	(%ebx,%eax)
	movl	DL_ARGV(%edx),	%ebx	# ebx = &_dl_argv
	popl	(%ebx,%eax)
	movl	DL_ARGC(%edx), 	%ebx	# ebx = &_dl_args
	popl	(%ebx,%eax)

	# Now i am going process _dl_auxv.
	# I am looking for AT_BASE and AT_PLATFORM
	# Finish on AT_NULL
	jmp	auxv_0
auxv:
	addl	$(REG_SIZE + REG_SIZE),	%ecx	# next auxv entry
auxv_0:
	cmpl	$AT_BASE, (%ecx)
	je	auxv_base
	cmpl	$AT_PLATFORM, (%ecx)
	je	auxv_platform
	cmpl	$AT_NULL, (%ecx)
	je	auxv_end
	jmp	auxv
auxv_base:
	mov	%eax,	REG_SIZE(%ecx)
	jmp	auxv
auxv_platform:
	#movl	$0x0, 0
	movl	DL_PLATFORM(%edx),	%ebx	# ebx = &_environ
	pushl	REG_SIZE(%ecx)
	popl	(%ebx,%eax)
	cmpl	$0,	REG_SIZE(%ecx)		# Is it NULL ?
	je	auxv
	# Now find out _dl_platformlen
	pushl	%ecx
	movl	REG_SIZE(%ecx),	%ecx	# address of _dl_platform
	jmp	platform_len_0
platform_len:
	incl	%ecx
platform_len_0:
	cmpb	$0,	(%ecx)
	jne	platform_len
platform_len_end:	
	decl	%ecx
	movl	DL_PLATFORMLEN(%edx),	%ebx	# ebx = &_environ
	movl	%ecx,	(%ebx,%eax)
	popl	%ecx

	jmp	auxv
auxv_end:
#data:
#BASE:		.long 0x40000000
#DL_ARGC:	.long 0x00015ec4
#DL_ARGV:	.long 0x00015ec8
#ENVIRON:	.long 0x00015890
#DL_AUXV:	.long 0x12345678
#PLATFORM:	.long 0x12345678

