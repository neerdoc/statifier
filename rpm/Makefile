PACKAGE := statifier

SOURCES :=            \
   Makefile           \
   $(PACKAGE).files   \
   $(PACKAGE).spec.in \

EXTRA_DIST = $(PACKAGE).spec

TOP_DIR = ..

all: 

define SpecFile
   VERSION=`cat $(TOP_DIR)/VERSION`                       && \
   RELEASE=`cat $(TOP_DIR)/RELEASE`                       && \
   {                                                         \
      echo "%define my_version $$VERSION"                 && \
      echo "%define my_release $$RELEASE"                 && \
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

clean-local:
	$(RM) $(EXTRA_DIST)

include ../Makefile.include
