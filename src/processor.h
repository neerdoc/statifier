/*
  Copyright (C) 2004 Valery Reznic
  This file is part of the Elf Statifier project
  
  This project is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License.
  See LICENSE file in the doc directory.
*/

/* This file define per-processor things */

#ifndef processor_h
#define processor_h

#undef REGISTER_SIZE
#ifdef __i386__
	#define REGISTER_SIZE 4
	#define SYSCALL_REG   (ORIG_EAX)
	#define PC_REG        (EIP)
	#define PC_OFFSET_AFTER_SYSCALL 2
#endif

#ifdef __x86_64__
	#define REGISTER_SIZE 8
	#define SYSCALL_REG   (ORIG_RAX)
	#define PC_REG        (RIP)
	#define PC_OFFSET_AFTER_SYSCALL 2
#endif

#ifndef REGISTER_SIZE
   #error This processor not supported (yet)
#endif

#define REG_SIZE REGISTER_SIZE

#endif /* processor_h */

