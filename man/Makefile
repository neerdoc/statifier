SOURCES =   \
   Makefile \
   $(MAN_1) \
	
MAN_1 =        \
   statifier.1 \

MAN_DIR_DEFAULT := /usr/share/man
MAN_DIR_RPM     := $(shell rpm --eval %_mandir 2>/dev/null || : )

MAN_DIR := $(if $(MAN_DIR_RPM),$(MAN_DIR_RPM),$(MAN_DIR_DEFAULT))
MAN_DIR := $(DESTDIR)/$(MAN_DIR)


MAN_1_DIR := $(MAN_DIR)/man1

install-local:
	$(MKDIR)               $(MAN_1_DIR)
	$(INSTALL_RO) $(MAN_1) $(MAN_1_DIR)

include ../Makefile.include
