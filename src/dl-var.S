# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This code is processor depended !!!

# Adjust some _dl variables.

MY_DATA BASE
MY_DATA DL_ARGC
MY_DATA DL_ARGV
MY_DATA ENVIRON

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
	
	movl	BASE(%edx),	%eax	# eax - base address of elf-interpreter

	movl	ENVIRON(%edx),	%ebx	# addr _environ
	popl	(%ebx,%eax)
	movl	DL_ARGV(%edx),	%ebx	# ebx = &_dl_argv
	popl	(%ebx,%eax)
	movl	DL_ARGC(%edx), 	%ebx	# ebx = &_dl_args
	popl	(%ebx,%eax)

#data:
#BASE:		.long 0x40000000
#DL_ARGC:	.long 0x00015ec4
#DL_ARGV:	.long 0x00015ec8
#ENVIRON:	.long 0x00015890
#DL_AUXV:	.long 0x12345678
#PLATFORM:	.long 0x12345678

