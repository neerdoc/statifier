# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

SUBDIRS  = src man rpm 

SOURCES =           \
   configure        \
   Makefile         \
   Makefile.common  \
   Makefile.include \
   Makefile.top     \
   VERSION          \
   RELEASE          \
   $(DOCS)          \
   $(CONFIGS)       \

DOCS =       \
   AUTHORS   \
   ChangeLog \
   INSTALL   \
   LICENSE   \
   NEWS      \
   README    \
   THANKS    \
   TODO      \

CONFIGS = $(addprefix configs/config.,$(SUPPORTED_CPU_LIST))

all: config

dist-list-for-tar: config

# It is simpler always re-make config and do not check dependencies.
# Configure care not change config's timestamp if content was not changed
.PHONY: config
config: configure
	/bin/sh ./configure

TOP_DIR := .
include Makefile.top
