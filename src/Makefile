# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

TOP_DIR := ..

include $(TOP_DIR)/config 

Problem := yes
INSTALL_COMMON := $(MAKE) install-common
ifeq "$(ELF32)" "yes"
   ALL_LOCAL_32     := $(MAKE) all-local-32
   INSTALL_LOCAL_32 := $(INSTALL_COMMON) && $(MAKE) install-local-32
   INSTALL_COMMON   := :
   Problem := no
endif
ifeq "$(ELF64)" "yes"
   ALL_LOCAL_64     := $(MAKE) all-local-64
   INSTALL_LOCAL_64 := $(INSTALL_COMMON) && $(MAKE) install-local-64
   Problem := no
endif

ifeq "$(Problem)" "yes"
   ALL_LOCAL_32 := @echo "At least one of the ELF32 and ELF64 should be set to 'yes'" 1>&2; exit 1
   INSTALL_LOCAL_32 := $(ALL_LOCAL_32)
endif

FLAGS_ELF          := $(FLAGS_$(ELF_CLASS))
FLAGS_C_TO_ASM_ELF := $(FLAGS_C_TO_ASM_$(ELF_CLASS))
PROCESSOR_ELF      := $(PROCESSOR_$(ELF_CLASS))
CPU_DIR            := cpus/$(PROCESSOR_ELF)

SOURCES =                 \
   $(BUILD_FILES)         \
   $(UTILS_SOURCES)       \
   $(ALL_PER_CPU_SOURCES) \
   $(INCLUDE_FILES)       \
   $(SCRIPTS)             \
   $(GDB_SCRIPTS)         \
   $(INCLUDE_SCRIPTS)     \
   $(RUNNERS)             \
   $(AWK_FILES)           \
   dl-var.c               \
   dl-var.inc             \
   gdb_runner.c           \
   find_dl_main.inc.c     \
   my_lib.inc.c           \

# Service files used to build 
BUILD_FILES =       \
   Makefile         \
   regs2asm.make.sh \
   regs2awk.make.sh \

INCLUDE_FILES = \
   start.S      \
   end.S        \

# small C programs, used by statifier.
UTILS =                 \
   copy_ehdr            \
   elfinfo              \
   elf_data             \
   phdrs                \
   set_thread_area_addr \
   strtoul              \
   tls_test             \
   $(FIND_UTILS)        \

# Small C utilities used to find various addresses in the loader
FIND_UTILS =        \
   elf_find_pattern \
   find_dl_argc     \
   find_dl_argv     \
   find_dl_auxv     \
   find_dl_platform \
   find_environ     \

UTILS_SOURCES = $(addsuffix .c,$(UTILS))

AWK_FILES = \
   regs.awk \

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
   statifier_loader.sh         \
   statifier_dump.sh           \
   statifier_create_starter.sh \
   statifier_create_exe.sh     \
 
# Include files, used by statifier
INCLUDE_SCRIPTS =       \
   statifier_lib.src    \
   statifier_parser.src \

RUNNERS =    \
   statifier \

# files used as command files for gdb
GDB_SCRIPTS =     \
   gdb_runner.gdb \
   statifier.gdb  \

# one as above, but with per-cpu difference
PER_CPU_GDB_SCRIPTS =  \
   set_thread_area.gdb \
   syscall.gdb         \

PER_CPU_INCLUDE_SCRIPTS = \
   properties.src         \

PER_CPU_ASM_SOURCES = $(addsuffix .S,$(FILES_TO_BE_EMBEDDED))

PER_CPU_SOURCES =             \
   $(PER_CPU_ASM_SOURCES)     \
   $(PER_CPU_GDB_SCRIPTS)     \
   $(PER_CPU_INCLUDE_SCRIPTS) \
   processor.h                \
   regs.list                  \

ALL_PER_CPU_SOURCES = $(foreach cpu,$(SUPPORTED_CPU_LIST),$(addprefix cpus/$(cpu)/,$(PER_CPU_SOURCES)))

LINK_NAMES = $(addprefix ../,$(SCRIPTS) $(GDB_SCRIPTS) $(INCLUDE_SCRIPTS))
PER_CPU_LINK_NAMES = $(addprefix ../$(CPU_DIR)/,$(PER_CPU_GDB_SCRIPTS) $(PER_CPU_INCLUDE_SCRIPTS))

UTILS_WITH_ELF_CLASS = $(addprefix $(ELF_CLASS)/,$(UTILS))
FILES_TO_BE_EMBEDDED_WITH_ELF_CLASS = $(addprefix $(ELF_CLASS)/,$(FILES_TO_BE_EMBEDDED))

TARGETS :=                                \
   $(UTILS_WITH_ELF_CLASS)                \
   $(FILES_TO_BE_EMBEDDED_WITH_ELF_CLASS) \
   $(ELF_CLASS)/regs.awk                  \
   $(ELF_CLASS)/gdb_runner                \

all:

all-local: VERSION
	$(ALL_LOCAL_32)
	$(ALL_LOCAL_64)
	
all-local-32 all-local-64:
	ELF_CLASS=$(subst all-local-,,$@) && $(MKDIR) $$ELF_CLASS && $(MAKE) ELF_CLASS=$$ELF_CLASS all-local-internal

all-local-internal: $(TARGETS)
	cd $(ELF_CLASS) && $(LN) $(LINK_NAMES)         .
	cd $(ELF_CLASS) && $(LN) $(PER_CPU_LINK_NAMES) .

VERSION: $(TOP_DIR)/VERSION
	$(RM) $@
	echo "VERSION='$(VERSION)'" > $@ || { $(RM) $@; exit 1; }
 
$(UTILS_WITH_ELF_CLASS): $(ELF_CLASS)/%: %.c
	gcc $(FLAGS_ELF) -I$(CPU_DIR) -Wall -O2 -g $< -o $@

# gdb_runner should be static, because I need avoid LD_PRELOAD influence
$(ELF_CLASS)/gdb_runner: gdb_runner.c
	gcc $(FLAGS_ELF) -static -Wall -O2 -g $< -o $@

$(ELF_CLASS)/dl-var.s: dl-var.c dl-var.inc
	gcc $(FLAGS_ELF) $(FLAGS_C_TO_ASM_ELF) -Wall -O2 -S $< -o $@


# Dependencies should be in correct order
$(ELF_CLASS)/regs.inc: regs2asm.make.sh $(CPU_DIR)/regs.list
$(ELF_CLASS)/regs.awk: regs2awk.make.sh $(CPU_DIR)/regs.list regs.awk
$(ELF_CLASS)/regs.inc $(ELF_CLASS)/regs.awk:
	$(RM) $@
	/bin/sh $^ $@ || { $(RM) $@; exit 1; }


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
# My workaround - pretend I am build end.S 
# with -include processor.h, start.S and $<
# 
$(OBJECTS_TO_BE_EMBEDDED_WITH_ELF_CLASS): $(ELF_CLASS)/%.o: $(CPU_DIR)/%.S $(CPU_DIR)/processor.h ./start.S ./end.S
	gcc $(FLAGS_ELF) -c -o $@ -nostdinc -I$(CURDIR) -I$(CURDIR)/$(ELF_CLASS) -include $(CPU_DIR)/processor.h -include ./start.S -include $< ./end.S

# Additional dependencies:
$(ELF_CLASS)/regs.o: $(ELF_CLASS)/regs.inc
$(ELF_CLASS)/dl-var.o: $(ELF_CLASS)/dl-var.s dl-var.inc
$(ELF_CLASS)/set_thread_area_addr: $(CPU_DIR)/processor.h
$(ELF_CLASS)/find_dl_argc    : find_dl_main.inc.c
$(ELF_CLASS)/find_dl_argv    : find_dl_main.inc.c
$(ELF_CLASS)/find_dl_auxv    : find_dl_main.inc.c
$(ELF_CLASS)/find_dl_platform: find_dl_main.inc.c
$(ELF_CLASS)/find_environ    : find_dl_main.inc.c

$(ELF_CLASS)/elf_find_pattern: my_lib.inc.c
$(ELF_CLASS)/phdrs           : my_lib.inc.c
# End of additional dependencies

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
	ELF_CLASS=$(subst install-local-,,$@) && $(MAKE) ELF_CLASS=$$ELF_CLASS install-local-internal

install-local-internal:
	                     $(MKDIR)                             $(LIB_DIR_ELF)
	                     $(INSTALL_RUN) $(TARGETS)            $(LIB_DIR_ELF)
	cd $(CPU_DIR)     && $(INSTALL_RO) $(PER_CPU_GDB_SCRIPTS) $(LIB_DIR_ELF)
	cd $(CPU_DIR)     && $(INSTALL_RO) $(PER_CPU_INCLUDE_SCRIPTS) $(LIB_DIR_ELF)
	cd $(LIB_DIR_ELF) && $(LN)         $(LINK_NAMES)          .

clean-local: clean-local-32 clean-local-64
	$(RM) VERSION

clean-local-32 clean-local-64:
	$(RMDIR) $(subst clean-local-,,$@)

include $(TOP_DIR)/Makefile.common
