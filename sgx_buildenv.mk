CP    := /bin/cp -f
MKDIR := mkdir -p
STRIP := strip
OBJCOPY := objcopy

# clean the content of 'INCLUDE' - this variable will be set by vcvars32.bat
# thus it will cause build error when this variable is used by our Makefile,
# when compiling the code under Cygwin tainted by MSVC environment settings.
INCLUDE :=

# turn on stack protector for SDK
COMMON_FLAGS += -fstack-protector -flto

ifdef DEBUG
    COMMON_FLAGS += -O0 -g -DDEBUG -UNDEBUG
else
    COMMON_FLAGS += -O2 -D_FORTIFY_SOURCE=2 -UDEBUG -DNDEBUG
endif

# turn on compiler warnings as much as possible
COMMON_FLAGS += -Wall -Wextra -Winit-self -Wpointer-arith -Wreturn-type \
		-Waddress -Wsequence-point -Wformat-security \
		-Wmissing-include-dirs -Wfloat-equal -Wundef -Wshadow \
		-Wcast-align -Wconversion -Wredundant-decls

CFLAGS += -Wjump-misses-init -Wstrict-prototypes -Wunsuffixed-float-constants
CXXFLAGS += -Wnon-virtual-dtor
CXXFLAGS += -std=c++0x

.DEFAULT_GOAL := all
% : RCS/%,v
% : RCS/%
% : %,v
% : s.%
% : SCCS/s.%

.DELETE_ON_ERROR:

HOST_FILE_PROGRAM := file

UNAME := $(shell uname -m)
ifneq (,$(findstring 86,$(UNAME)))
    HOST_ARCH := x86
    ifneq (,$(shell $(HOST_FILE_PROGRAM) -L $(SHELL) | grep 'x86[_-]64'))
        HOST_ARCH := x86_64
    endif
else
    $(info Unknown host CPU arhitecture $(UNAME))
    $(error Aborting)
endif


ifeq "$(findstring __INTEL_COMPILER, $(shell $(CC) -E -dM -xc /dev/null))" "__INTEL_COMPILER"
  ifeq ($(shell test -f /usr/bin/dpkg; echo $$?), 0)
    ADDED_INC := -I /usr/include/$(shell dpkg-architecture -qDEB_BUILD_MULTIARCH)
  endif
endif

ARCH := $(HOST_ARCH)
ifeq "$(findstring -m32, $(CXXFLAGS))" "-m32"
  ARCH := x86
endif

ifeq ($(ARCH), x86)
COMMON_FLAGS += -DITT_ARCH_IA32
else
COMMON_FLAGS += -DITT_ARCH_IA64
endif

CFLAGS   += $(COMMON_FLAGS)
CXXFLAGS += $(COMMON_FLAGS)

COMMON_LDFLAGS := -Wl,-z,relro,-z,now,-z,noexecstack

# mitigation options
MITIGATION_INDIRECT ?= 0
MITIGATION_RET ?= 0
MITIGATION_C ?= 0
MITIGATION_ASM ?= 0
MITIGATION_AFTERLOAD ?= 0
MITIGATION_LIB_PATH :=

ifeq ($(MITIGATION-CVE-2020-0551), LOAD)
    MITIGATION_C := 1
    MITIGATION_ASM := 1
    MITIGATION_INDIRECT := 1
    MITIGATION_RET := 1
    MITIGATION_AFTERLOAD := 1
    MITIGATION_LIB_PATH := cve_2020_0551_load
else ifeq ($(MITIGATION-CVE-2020-0551), CF)
    MITIGATION_C := 1
    MITIGATION_ASM := 1
    MITIGATION_INDIRECT := 1
    MITIGATION_RET := 1
    MITIGATION_AFTERLOAD := 0
    MITIGATION_LIB_PATH := cve_2020_0551_cf
endif

MITIGATION_CFLAGS :=
MITIGATION_ASFLAGS :=
ifeq ($(MITIGATION_C), 1)
ifeq ($(MITIGATION_INDIRECT), 1)
    MITIGATION_CFLAGS += -mindirect-branch-register
endif
ifeq ($(MITIGATION_RET), 1)
    MITIGATION_CFLAGS += -mfunction-return=thunk-extern
endif
endif

ifeq ($(MITIGATION_ASM), 1)
    MITIGATION_ASFLAGS += -fno-plt
ifeq ($(MITIGATION_AFTERLOAD), 1)
    MITIGATION_ASFLAGS += -Wa,-mlfence-after-load=yes
else
    MITIGATION_ASFLAGS += -Wa,-mlfence-before-indirect-branch=register
endif
ifeq ($(MITIGATION_RET), 1)
    MITIGATION_ASFLAGS += -Wa,-mlfence-before-ret=not
endif
endif

MITIGATION_CFLAGS += $(MITIGATION_ASFLAGS)

ENCLAVE_CFLAGS   = -ffreestanding -nostdinc -fvisibility=hidden -fpie -fno-strict-overflow -fno-delete-null-pointer-checks
ENCLAVE_CXXFLAGS = $(ENCLAVE_CFLAGS) -nostdinc++
ENCLAVE_LDFLAGS  = $(COMMON_LDFLAGS) -Wl,-Bstatic -Wl,-Bsymbolic -Wl,--no-undefined \
                   -Wl,-pie,-eenclave_entry -Wl,--export-dynamic  \
                   -Wl,--gc-sections \
                   -Wl,--defsym,__ImageBase=0

ENCLAVE_CFLAGS += $(MITIGATION_CFLAGS)
ENCLAVE_ASFLAGS = $(MITIGATION_ASFLAGS)