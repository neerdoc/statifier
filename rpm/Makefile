TOP_DIR = ..

SOURCES =             \
   Makefile           \
   $(PACKAGE).files   \
   $(PACKAGE).spec.in \

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

clean-local:
	$(RM) $(EXTRA_DIST)

include $(TOP_DIR)/Makefile.common
