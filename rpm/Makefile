# Copyright (C) 2004 Valery Reznic
# This file is part of the Elf Statifier project
# 
# This project is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License.
# See LICENSE file in the doc directory.

TOP_DIR = ..
include $(TOP_DIR)/config

PACKAGE := statifier
Problem := yes
FILES_32 := :
FILES_64 := :
ifeq "$(ELF32)" "yes"
   FILES_32 = sed -e "s/@ELF_CLASS@/32/g" < $(PACKAGE).files.elf.in
   Problem  = no
endif
ifeq "$(ELF64)" "yes"
   FILES_64 = sed -e "s/@ELF_CLASS@/64/g" < $(PACKAGE).files.elf.in
   Problem  = no
endif

ifeq "$(Problem)" "yes"
   FILES_ERROR = @echo "At least one of the ELF32 and ELF64 should be set to 'yes'" 1>&2; exit 1
endif

SOURCES =                  \
   Makefile                \
   $(PACKAGE).files.common \
   $(PACKAGE).files.elf.in \
   $(PACKAGE).spec.in      \

EXTRA_DIST = $(PACKAGE).spec

all: 

define SpecFile
   {                                                         \
      echo "%define my_version $(VERSION)"                && \
      echo "%define my_release $(RELEASE)"                && \
      echo                                                && \
      cat  $(PACKAGE).spec.in                             && \
      echo && echo %files     && cat $(PACKAGE).files     && \
      echo && echo %changelog && cat $(TOP_DIR)/ChangeLog && \
      :                                                   ;  \
   }
endef

$(PACKAGE).spec: $(PACKAGE).spec.in $(PACKAGE).files $(TOP_DIR)/VERSION $(TOP_DIR)/RELEASE $(TOP_DIR)/ChangeLog
	$(RM) $@
	$(SpecFile) > $@ || { $(RM) $@; exit 1; }

define Files
   {                                 \
      cat $(PACKAGE).files.common && \
      $(FILES_32)                 && \
      $(FILES_64)                 && \
      :                           ;  \
   }
endef


$(PACKAGE).files: $(PACKAGE).files.common $(PACKAGE).files.elf.in $(TOP_DIR)/config
	@$(FILES_ERROR)
	$(RM) $@
	$(Files) > $@ || { $(RM) $@; exit 1; }

clean-local:
	$(RM) $(EXTRA_DIST) $(PACKAGE).files

include $(TOP_DIR)/Makefile.common
