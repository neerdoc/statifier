# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

TOP_DIR := ..

include $(TOP_DIR)/config 

Problem := yes
INSTALL_COMMON := make install-common
ifeq "$(ELF32)" "yes"
   ALL_LOCAL_32     := make all-local-32
   INSTALL_LOCAL_32 := $(INSTALL_COMMON) && make install-local-32
   INSTALL_COMMON   := :
   Problem := no
endif
ifeq "$(ELF64)" "yes"
   ALL_LOCAL_64     := make all-local-64
   INSTALL_LOCAL_64 := $(INSTALL_COMMON) && make install-local-64
   Problem := no
endif

ifeq "$(Problem)" "yes"
   ALL_LOCAL_32 := @echo "At least one of the ELF32 and ELF64 should be set to 'yes'" 1>&2; exit 1
   INSTALL_LOCAL_32 := $(ALL_LOCAL_32)
endif

FLAGS_ELF     := $(FLAGS_$(ELF_CLASS))
PROCESSOR_ELF := $(PROCESSOR_$(ELF_CLASS))
CPU_DIR       := cpus/$(PROCESSOR_ELF)

SOURCES =                                  \
   $(BUILD_FILES)                          \
   $(addsuffix .c,$(UTILS))                \
   $(ALL_PER_CPU_SOURCES)                  \
   $(INCLUDE_FILES)                        \
   $(SCRIPTS)                              \
   $(GDB_SCRIPTS)                          \
   $(INCLUDE_SCRIPTS)                      \
   $(RUNNERS)                              \

# Service files used to build 
BUILD_FILES =       \
   Makefile         \
   elf2at.make.sh   \
   regs2asm.make.sh \
   regs2awk.make.sh \

INCLUDE_FILES = \
   processor.h  \
   start.S      \
   end.S        \

# small C programs, used by statifier.
UTILS =                 \
   elfinfo              \
   loader_base_test     \
   phdrs                \
   set_thread_area_addr \
   strtoul              \
   tls_test             \

# Files which are built block for starter
FILES_TO_BE_EMBEDDED = \
   dl-var              \
   regs                \
   set_thread_area     \

# Scripts, used by statifier
SCRIPTS =             \
   $(HELPER_SCRIPTS)  \
   $(STATIFIER_PARTS) \

HELPER_SCRIPTS =      \
   dumps.sh           \
   regs.sh            \
   set_thread_area.sh \
   split.sh           \
   statifier.sh       \

# Scripts which are implement "main logic" of statifier
STATIFIER_PARTS =              \
   statifier_common.sh         \
   statifier_before_dump.sh    \
   statifier_dump.sh           \
   statifier_before_starter.sh \
   statifier_create_starter.sh \
   statifier_create_exe.sh     \
 
# Include files, used by statifier
INCLUDE_SCRIPTS =       \
   statifier_lib.src    \
   statifier_parser.src \

RUNNERS =    \
   statifier \

# files used as command files for gdb
GDB_SCRIPTS =          \
   dumps.gdb           \
   first.gdb           \
   map_reg_core.gdb    \

# ane as above, but with per-cpu difference
PER_CPU_GDB_SCRIPTS =  \
   set_thread_area.gdb \

PER_CPU_ASM_SOURCES = $(addsuffix .S,$(FILES_TO_BE_EMBEDDED))

PER_CPU_SOURCES =         \
   $(PER_CPU_ASM_SOURCES) \
   $(PER_CPU_GDB_SCRIPTS) \
   regs.list              \

ALL_PER_CPU_SOURCES = $(foreach cpu,$(SUPPORTED_CPU_LIST),$(addprefix cpus/$(cpu)/,$(PER_CPU_SOURCES)))

LINK_NAMES = $(addprefix ../,$(SCRIPTS) $(GDB_SCRIPTS) $(INCLUDE_SCRIPTS))
PER_CPU_LINK_NAMES = $(addprefix ../$(CPU_DIR)/,$(PER_CPU_GDB_SCRIPTS))

UTILS_WITH_ELF_CLASS = $(addprefix $(ELF_CLASS)/,$(UTILS))
FILES_TO_BE_EMBEDDED_WITH_ELF_CLASS = $(addprefix $(ELF_CLASS)/,$(FILES_TO_BE_EMBEDDED))

TARGETS :=                                \
   $(UTILS_WITH_ELF_CLASS)                \
   $(FILES_TO_BE_EMBEDDED_WITH_ELF_CLASS) \
   $(ELF_CLASS)/regs.awk                  \

all:

all-local: VERSION
	$(ALL_LOCAL_32)
	$(ALL_LOCAL_64)
	
all-local-32 all-local-64:
	ELF_CLASS=$(subst all-local-,,$@) && $(MKDIR) $$ELF_CLASS && make ELF_CLASS=$$ELF_CLASS all-local-internal

all-local-internal: $(TARGETS)
	cd $(ELF_CLASS) && $(LN) $(LINK_NAMES)         .
	cd $(ELF_CLASS) && $(LN) $(PER_CPU_LINK_NAMES) .

VERSION: $(TOP_DIR)/VERSION
	$(RM) $@
	echo "VERSION='$(VERSION)'" > $@ || { $(RM) $@; exit 1; }
 
$(UTILS_WITH_ELF_CLASS): $(ELF_CLASS)/%: %.c
	gcc $(FLAGS_ELF) -Wall -O2 -g $< -o $@

$(ELF_CLASS)/set_thread_area_addr: processor.h

$(ELF_CLASS)/dl-var.o: $(ELF_CLASS)/AT.h

$(ELF_CLASS)/AT.h: /usr/include/elf.h elf2at.make.sh
	$(RM) $@
	/bin/sh elf2at.make.sh $< $@ || { $(RM) $@; exit 1; }

$(ELF_CLASS)/regs.o: $(ELF_CLASS)/regs.inc
$(ELF_CLASS)/regs.inc: $(CPU_DIR)/regs.list regs2asm.make.sh
	$(RM) $@
	/bin/sh regs2asm.make.sh $< $@ || { $(RM) $@; exit 1; }

$(ELF_CLASS)/regs.awk: $(CPU_DIR)/regs.list regs2awk.make.sh
	$(RM) $@
	/bin/sh regs2awk.make.sh $< $@ || { $(RM) $@; exit 1; }

# I need embedded files as raw binary - no elf header, no link with libc,
# so I have to specify '-Wl,--oformat,binary' and -nostdlib
# Because linker give warning about _start function I specify
# pretty dummy '--entry=0x0'
$(FILES_TO_BE_EMBEDDED_WITH_ELF_CLASS): $(ELF_CLASS)/%: $(ELF_CLASS)/%.o
	gcc $(FLAGS_ELF) -o $@ $< -Wl,--oformat,binary,--entry=0x0 -nostdlib

OBJECTS_TO_BE_EMBEDDED_WITH_ELF_CLASS = $(addsuffix .o,$(FILES_TO_BE_EMBEDDED_WITH_ELF_CLASS))

# I need include start.S before and end.S after each .S file
# Sure, I don't want write this includes into each source, so i use gcc flags
# But, gcc have only -include flag, with means - "include before".
# My workaround - pretend I am build end.S with -include start.S and
# -include $<
# 
$(OBJECTS_TO_BE_EMBEDDED_WITH_ELF_CLASS): $(ELF_CLASS)/%.o: $(CPU_DIR)/%.S processor.h start.S end.S
	gcc $(FLAGS_ELF) -c -o $@ -nostdinc -I./$(ELF_CLASS) -include ./processor.h -include ./start.S -include ./$< end.S

LIB_DIR     = $(DESTDIR)/usr/lib/statifier
LIB_DIR_ELF = $(LIB_DIR)/$(ELF_CLASS)
BIN_DIR     = $(DESTDIR)/usr/bin

install-local:
	$(INSTALL_LOCAL_32)
	$(INSTALL_LOCAL_64)

install-common:
	$(MKDIR)                                                 $(LIB_DIR)
	$(INSTALL_RUN) $(SCRIPTS)                                $(LIB_DIR)
	$(INSTALL_RO)  VERSION $(GDB_SCRIPTS) $(INCLUDE_SCRIPTS) $(LIB_DIR)

	$(MKDIR)                  $(BIN_DIR)
	$(INSTALL_RUN) $(RUNNERS) $(BIN_DIR)

install-local-32 install-local-64:
	ELF_CLASS=$(subst install-local-,,$@) && make ELF_CLASS=$$ELF_CLASS install-local-internal

install-local-internal:
	                     $(MKDIR)                             $(LIB_DIR_ELF)
	                     $(INSTALL_RUN) $(TARGETS)            $(LIB_DIR_ELF)
	cd $(CPU_DIR)     && $(INSTALL_RO) $(PER_CPU_GDB_SCRIPTS) $(LIB_DIR_ELF)
	cd $(LIB_DIR_ELF) && $(LN)         $(LINK_NAMES)          .

clean-local: clean-local-32 clean-local-64
	$(RM) VERSION

clean-local-32 clean-local-64:
	$(RMDIR) $(subst clean-local-,,$@)

include $(TOP_DIR)/Makefile.common
