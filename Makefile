# these values filled in by    yorick -batch make.i
Y_MAKEDIR=/usr/local/libexec/yorick
Y_EXE=/usr/local/libexec/yorick/bin/yorick
Y_EXE_PKGS=
Y_EXE_HOME=/usr/local/libexec/yorick
Y_EXE_SITE=/usr/local/libexec/yorick
Y_HOME_PKG=

# ----------------------------------------------------- optimization flags

# options for make command line, e.g.-   make COPT=-g TGT=exe
COPT=$(COPT_DEFAULT)
TGT=$(DEFAULT_TGT)

# ------------------------------------------------ macros for this package

PKG_NAME=dlwrap
PKG_I=dlwrap.i

#OBJS=ydlload.o
OBJS=ydlload.o ydlcall.o

# change to give the executable a name other than yorick
PKG_EXENAME=yorick

RELEASE_FILES = AUTHORS LICENSE Makefile NEWS README TODO \
	$(PKG_I) ydlwrap.h ydlload.c ydlcall.c
RELEASE_NAME = y$(PKG_NAME)-$(RELEASE_VERSION).tar.bz2

# PKG_DEPLIBS=-Lsomedir -lsomelib   for dependencies of this package
#PKG_DEPLIBS=-lavcall
PKG_DEPLIBS=-lavcall -lltdl -ldl
#PKG_DEPLIBS=-lavcall -ldl
# set compiler (or rarely loader) flags specific to this package
#PKG_CFLAGS=-DHAVE_FFCALL
PKG_CFLAGS= -DHAVE_LIBTOOL -DHAVE_FFCALL
#PKG_CFLAGS= -DHAVE_DLOPEN -DHAVE_FFCALL
PKG_LDFLAGS=

# list of additional package names you want in PKG_EXENAME
# (typically Y_EXE_PKGS should be first here)
EXTRA_PKGS=$(Y_EXE_PKGS)

# list of additional files for clean
PKG_CLEAN=

# autoload file for this package, if any
PKG_I_START=
# non-pkg.i include files for this package, if any
PKG_I_EXTRA=

# -------------------------------- standard targets and rules (in Makepkg)

# set macros Makepkg uses in target and dependency names
# DLL_TARGETS, LIB_TARGETS, EXE_TARGETS
# are any additional targets (defined below) prerequisite to
# the plugin library, archive library, and executable, respectively
PKG_I_DEPS=$(PKG_I)
Y_DISTMAKE=distmake

include $(Y_MAKEDIR)/Make.cfg
include $(Y_MAKEDIR)/Makepkg
include $(Y_MAKEDIR)/Make$(TGT)

# override macros Makepkg sets for rules and other macros
# Y_HOME and Y_SITE in Make.cfg may not be correct (e.g.- relocatable)
Y_HOME=$(Y_EXE_HOME)
Y_SITE=$(Y_EXE_SITE)

# reduce chance of yorick-1.5 corrupting this Makefile
MAKE_TEMPLATE = protect-against-1.5

# ------------------------------------- targets and rules for this package

# simple example:
#myfunc.o: myapi.h
# more complex example (also consider using PKG_CFLAGS above):
#myfunc.o: myapi.h myfunc.c
#	$(CC) $(CPPFLAGS) $(CFLAGS) -DMY_SWITCH -o $@ -c myfunc.c
ydlcall.o: ydlcall.c ydlwrap.h
ydlload.o: ydlload.c ydlwrap.h

release: $(RELEASE_NAME)

$(RELEASE_NAME):
	@if test "x$(RELEASE_VERSION)" = "x"; then \
	  echo >&2 "set package version:  make RELEASE_VERSION=... archive"; \
	else \
          dir=`basename "$(RELEASE_NAME)" .tar.bz2`; \
	  if test "x$$dir" = "x" -o "x$$dir" = "x."; then \
	    echo >&2 "bad directory name for archive"; \
	  elif test -d "$$dir"; then \
	    echo >&2 "directory $$dir already exists"; \
	  else \
	    mkdir -p "$$dir"; \
	    cp -a $(RELEASE_FILES) "$$dir/."; \
	    echo "$(RELEASE_VERSION)" > "$$dir/VERSION"; \
	    tar jcf "$(RELEASE_NAME)" "$$dir"; \
	    rm -rf "$$dir"; \
	    echo "$(RELEASE_NAME) created"; \
	  fi; \
	fi;

.PHONY: clean release

# -------------------------------------------------------- end of Makefile
