# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

# This file define per-processor things

#ifndef processor_h
#define processor_h

#ifdef __i386__
   # x[345]86 has 32 bits registers 
   #define REG_SIZE 4
#endif

#ifdef __x86_64__
   #define REG_SIZE 8
#endif

#ifndef REG_SIZE
   #error This processor not supported (yet)
#endif

#endif /* processor_h */

