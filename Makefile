PACKAGE = statifier
VERSION := $(shell cat VERSION)
SUBDIRS  = src man rpm 
SOURCES =           \
   Makefile         \
   Makefile.include \
   Makefile.top     \
   VERSION          \
   RELEASE          \
   $(DOCS)          \

DOCS =       \
   AUTHORS   \
   ChangeLog \
   INSTALL   \
   LICENSE   \
   NEWS      \
   README    \
   TODO      \

all:

include Makefile.top
