# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

SOURCES =                                  \
   Makefile                                \
   $(addsuffix .c,$(UTILS))                \
   $(addsuffix .S,$(FILES_TO_BE_EMBEDDED)) \
   $(SCRIPTS)                              \
   $(GDB_SCRIPTS)                          \
   $(RUNNERS)                              \

UTILS =                 \
   phdrs                \
   set_thread_area_addr \
   strtoul              \

FILES_TO_BE_EMBEDDED = \
   set_thread_area     \
   starter             \

SCRIPTS =       \
   dumps.sh     \
   regs.sh      \
   split.sh     \
   statifier.sh \
 
RUNNERS =    \
   statifier \

GDB_SCRIPTS =          \
   dumps.gdb           \
   first.gdb           \
   map_reg_core.gdb    \
   set_thread_area.gdb \

TARGETS := $(UTILS) $(FILES_TO_BE_EMBEDDED)

all: 
all-local: $(TARGETS)

$(UTILS): %: %.c
	gcc -Wall -O2 -g $< -o $@

# I need starter as raw binary - no elf header, no link with libc,
# so I have to specify '-Wl,--oformat,binary' and -nostdlib
# Because linker give warning about _start function I specify
# pretty dummy '--entry=0x0'
$(FILES_TO_BE_EMBEDDED): %: %.S
	gcc $< -o $@ -Wl,--oformat,binary,--entry=0x0 -nostdlib

LIB_DIR = $(DESTDIR)/usr/lib/statifier
BIN_DIR = $(DESTDIR)/usr/bin
install-local:
	$(MKDIR)                             $(LIB_DIR)
	$(INSTALL_RUN) $(TARGETS) $(SCRIPTS) $(LIB_DIR)
	$(INSTALL_RO)  $(GDB_SCRIPTS)        $(LIB_DIR)

	$(MKDIR)                  $(BIN_DIR)
	$(INSTALL_RUN) $(RUNNERS) $(BIN_DIR)

clean-local:
	rm -f $(TARGETS)

include ../Makefile.include
