#
# Global Makefile for GEM
#
include $(XDAQ_ROOT)/config/mfAutoconf.rules
include $(XDAQ_ROOT)/config/mfDefs.$(XDAQ_OS)
include $(XDAQ_ROOT)/config/Makefile.rules
include $(XDAQ_ROOT)/config/mfRPM.rules

SUBPACKAGES := \
        gemutils \
        gembase \
        gemhardware \
        gemsupervisor \
        gemHwMonitor \

#OS:=linux
#ARCH:=x86_64
#LIBDIR:=lib/$(OS)/$(ARCH)
#LIBDIR:=lib/$(XDAQ_OS)/$(XDAQ_PLATFORM)

SUBPACKAGES.INSTALL := $(patsubst %,%.install, ${SUBPACKAGES})
SUBPACKAGES.RPM := $(patsubst %,%.rpm, ${SUBPACKAGES})
SUBPACKAGES.CLEAN := $(patsubst %,%.clean, ${SUBPACKAGES})

all: $(SUBPACKAGES)

install: $(LIBDIR) $(SUBPACKAGES) $(SUBPACKAGES.INSTALL)

rpm: $(SUBPACKAGES) $(SUBPACKAGES.RPM)

clean: $(SUBPACKAGES.CLEAN)

$(LIBDIR):
	mkdir -p $(LIBDIR)

$(SUBPACKAGES):
	$(MAKE) -C $@

$(SUBPACKAGES.RPM):
	$(MAKE) -C $(patsubst %.rpm,%, $@) rpm

$(SUBPACKAGES.INSTALL):
	-find  $(patsubst %.install,%, $@)/lib -name *.so -print -exec cp {} ${LIBDIR} \;

$(SUBPACKAGES.CLEAN):
	$(MAKE) -C $(patsubst %.clean,%, $@) clean

.PHONY: $(SUBPACKAGES) $(SUBPACKAGES.INSTALL) $(SUBPACKAGES.CLEAN)


gemHwMonitor: gembase gemhardware

gemhardware: gemutils gembase

gembase: gemutils

gemsupervisor: gemhardware gembase

gemutils: 

print-env:
	@echo BUILD_HOME $(BUILD_HOME)
	@echo XDAQ_ROOT  $(XDAQ_ROOT)
	@echo XDAQ_OS    $(XDAQ_OS)
	@echo XDAQ_OS    $(XDAQ_PLATFORM)
	@echo ROOTCFLAGS $(ROOTCFLAGS)
	@echo ROOTLIBS   $(ROOTLIBS)
	@echo ROOTGLIBS  $(ROOTGLIBS)

