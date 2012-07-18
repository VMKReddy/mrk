#Copyright (C) 2011 by Sagar G V
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.
#
# Updates: 
#    Arthur Wolf & Adam Green in 2011 - Updated to work with mbed.
#    Dalton Banks in 2012 - Updated to work with Nano-RK.
###############################################################################
# USAGE:
# Variables that must be defined in including makefile.
#   PROJECT: Name to be given to the output binary for this project.
#   SRC: The root directory for the sources of your project.
#   GCC4MED_DIR: The root directory for where the gcc4mbed sources are located
#                in your project.  This should point to the parent directory
#                of the build directory which contains this gcc4mbed.mk file.
#   LIBS_PREFIX: List of library/object files to prepend to mbed.ar capi.ar libs.
#   LIBS_SUFFIX: List of library/object files to append to mbed.ar capi.ar libs.
#   GCC4MBED_DELAYED_STDIO_INIT: Set to non-zero value to have intialization of
#                                stdin/stdout/stderr delayed which will
#                                shrink the size of the resulting binary if
#                                APIs like printf(), scanf(), etc. aren't used.
# Example makefile:
#       PROJECT=HelloWorld
#       SRC=.
#       GCC4MBED_DIR=../..
#       LIBS_PREFIX=../agutil/agutil.ar
#       LIBS_SUFFIX=
#
#       include ../../build/gcc4mbed.mk
#      
###############################################################################

ifndef PROGRAMMING_PORT
    PROGRAMMING_PORT=/Volumes/MBED
endif

# Default project source to be located in current directory.
ifndef SRC
    SRC=.
endif

# Default the init of stdio/stdout/stderr to occur before global constructors.
ifndef GCC4MBED_DELAYED_STDIO_INIT
    GCC4MBED_DELAYED_STDIO_INIT=0
endif

# List of sources to be compiled/assembled
CSRCS += $(wildcard $(SRC)/*.c $(SRC)/*/*.c $(SRC)/*/*/*.c $(SRC)/*/*/*/*.c $(SRC)/*/*/*/*/*.c)
ASRCS =  $(wildcard $(SRC)/*.S $(SRC)/*/*.S $(SRC)/*/*/*.S $(SRC)/*/*/*/*.S $(SRC)/*/*/*/*/*.S)
CPPSRCS = $(wildcard $(SRC)/*.cpp $(SRC)/*/*.cpp $(SRC)/*/*/*.cpp $(SRC)/*/*/*/*.cpp $(SRC)/*/*/*/*/*.cpp)

# Add in the gcc4mbed shim sources that allow mbed code build under GCC
CSRCS += $(GCC4MBED_DIR)/src/gcc4mbed.c $(GCC4MBED_DIR)/src/syscalls.c

#> Nano-RK Node Addr # By default the NODE_ADDR is 0
ifndef NODE_ADDR 
NODE_ADDR = 0
endif

#> Nano-RK Radio
RADIO_TYPE = $(strip $(RADIO))

ifdef PLATFORM_FOUND

#> Nano-RK C Sources
CSRCS += $(NANORK_DIR)/src/radio/$(RADIO_TYPE)/source/hal_rf_set_channel.c
CSRCS += $(NANORK_DIR)/src/radio/$(RADIO_TYPE)/source/hal_rf_wait_for_crystal_oscillator.c
CSRCS += $(NANORK_DIR)/src/radio/$(RADIO_TYPE)/source/basic_rf.c 

CSRCS += $(NANORK_DIR)/src/platform/$(PLATFORM_TYPE)/source/ulib.c 
CSRCS += $(NANORK_DIR)/src/platform/$(PLATFORM_TYPE)/source/hal_wait.c
CSRCS += $(NANORK_DIR)/src/platform/$(PLATFORM_TYPE)/source/nrk_eeprom.c

CSRCS += $(NANORK_DIR)/src/kernel/source/nrk.c
CSRCS += $(NANORK_DIR)/src/kernel/source/nrk_stats.c
CSRCS += $(NANORK_DIR)/src/kernel/source/nrk_error.c
CSRCS += $(NANORK_DIR)/src/kernel/source/nrk_stack_check.c
CSRCS += $(NANORK_DIR)/src/kernel/source/nrk_events.c
CSRCS += $(NANORK_DIR)/src/kernel/source/nrk_task.c
CSRCS += $(NANORK_DIR)/src/kernel/source/nrk_time.c
CSRCS += $(NANORK_DIR)/src/kernel/source/nrk_idle_task.c
CSRCS += $(NANORK_DIR)/src/kernel/source/nrk_scheduler.c
CSRCS += $(NANORK_DIR)/src/kernel/source/nrk_driver.c
CSRCS += $(NANORK_DIR)/src/kernel/source/nrk_reserve.c
CSRCS += $(NANORK_DIR)/src/kernel/hal/$(MCU)/nrk_timer.c
CSRCS += $(NANORK_DIR)/src/kernel/hal/$(MCU)/nrk_status.c
CSRCS += $(NANORK_DIR)/src/kernel/hal/$(MCU)/nrk_watchdog.c
CSRCS += $(NANORK_DIR)/src/kernel/hal/$(MCU)/nrk_cpu.c

#> Nano-RK ASM Sources
ASRCS += $(NANORK_DIR)/src/kernel/hal/$(MCU)/LPC1768_hw_specific.S

else

PLATFORM_ERROR="ERROR Unknown platform:"
endif

# List of the objects files to be compiled/assembled
OBJECTS= $(CSRCS:.c=.o) $(ASRCS:.S=.o) $(CPPSRCS:.cpp=.o)
LSCRIPT=$(GCC4MBED_DIR)/build/mbed.ld

# Location of external library and header dependencies.
EXTERNAL_DIR = $(GCC4MBED_DIR)/external

# Include path which points to external library headers and to subdirectories of this project which contain headers.
SUBDIRS = $(wildcard $(SRC)/* $(SRC)/*/* $(SRC)/*/*/* $(SRC)/*/*/*/* $(SRC)/*/*/*/*/*)
PROJINCS = $(sort $(dir $(SUBDIRS)))
INCDIRS += $(PROJINCS) $(EXTERNAL_DIR)/mbed $(EXTERNAL_DIR)/mbed/LPC1768 $(EXTERNAL_DIR)/FATFileSystem

#> Nano-RK Extra Include Dirs
#> List any extra directories to look for include files here.
#> Each directory must be separated by a space.
ifdef EXTRAINCDIRS
INCDIRS += EXTRAINCDIRS
endif
INCDIRS += $(NANORK_DIR)/src/platform/include
INCDIRS += $(NANORK_DIR)/src/platform/$(PLATFORM_TYPE)/include
INCDIRS += $(NANORK_DIR)/src/radio/$(RADIO_TYPE)/include
INCDIRS += $(NANORK_DIR)/src/radio/$(RADIO_TYPE)/hal/$(MCU)
INCDIRS += $(NANORK_DIR)/src/radio/$(RADIO_TYPE)/platform/$(PLATFORM_TYPE)
INCDIRS += $(NANORK_DIR)/src/drivers/include
INCDIRS += $(NANORK_DIR)/src/drivers/platform/$(PLATFORM_TYPE)/include
INCDIRS += $(NANORK_DIR)/src/kernel/include
INCDIRS += $(NANORK_DIR)/src/kernel/hal/include

# DEFINEs to be used when building C/C++ code
DEFINES = -DTARGET_LPC1768 -DGCC4MBED_DELAYED_STDIO_INIT=$(GCC4MBED_DELAYED_STDIO_INIT)
#> Nano-RK DEFINEs
DEFINES += -DNANORK -DNODE_ADDR=$(NODE_ADDR)

# Libraries to be linked into final binary
LIBS = $(LIBS_PREFIX) $(EXTERNAL_DIR)/mbed/LPC1768/mbed.ar $(EXTERNAL_DIR)/mbed/LPC1768/capi.ar $(EXTERNAL_DIR)/FATFileSystem/LPC1768/FATFileSystem.ar $(LIBS_SUFFIX)

# Optimization level
OPTIMIZATION = 2

#  Compiler Options
GPFLAGS = -O$(OPTIMIZATION) -gdwarf-2 -mcpu=cortex-m3 -mthumb -mthumb-interwork -fshort-wchar -ffunction-sections -fdata-sections -fpromote-loop-indices -Wall -Wextra -Wimplicit -Wcast-align -Wpointer-arith -Wredundant-decls -Wshadow -Wcast-qual -Wcast-align -fno-exceptions
GPFLAGS += $(patsubst %,-I%,$(INCDIRS))
GPFLAGS += $(DEFINES)
GPFLAGS += -MD

LDFLAGS = -mcpu=cortex-m3 -mthumb -O$(OPTIMIZATION) -Wl,-Map=$(PROJECT).map,--cref,--gc-sections,--no-wchar-size-warning -T$(LSCRIPT) -L $(EXTERNAL_DIR)/gcc/LPC1768

ASFLAGS = $(LISTING) -mcpu=cortex-m3 -mthumb -x assembler-with-cpp
ASFLAGS += $(patsubst %,-I%,$(INCDIRS))

#  Compiler/Assembler/Linker Paths
GPP = arm-none-eabi-g++
AS = arm-none-eabi-gcc
LD = arm-none-eabi-g++
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE = arm-none-eabi-size
REMOVE = rm

# Switch to cs-rm on Windows and make sure that cmd.exe is used as shell.
ifeq "$(MAKE)" "cs-make"
REMOVE = cs-rm
SHELL=cmd.exe
endif

#########################################################################

all:: $(PROJECT).hex $(PROJECT).bin $(PROJECT).disasm

$(PROJECT).bin: $(PROJECT).elf
	$(OBJCOPY) -O binary $(PROJECT).elf $(PROJECT).bin

$(PROJECT).hex: $(PROJECT).elf
	$(OBJCOPY) -R .stack -O ihex $(PROJECT).elf $(PROJECT).hex
	
$(PROJECT).disasm: $(PROJECT).elf
	$(OBJDUMP) -d $(PROJECT).elf >$(PROJECT).disasm
	
$(PROJECT).elf: $(LSCRIPT) $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) $(LIBS) -o $(PROJECT).elf
	$(SIZE) $(PROJECT).elf

clean:
	$(REMOVE) -f $(OBJECTS)
	$(REMOVE) -f $(PROJECT).hex
	$(REMOVE) -f $(PROJECT).elf
	$(REMOVE) -f $(PROJECT).map
	$(REMOVE) -f $(PROJECT).bin
	$(REMOVE) -f $(PROJECT).disasm

program: $(PROJECT).bin
	cp $(PROJECT).bin $(PROGRAMMING_PORT)

ifdef LPC_DEPLOY
DEPLOY_COMMAND = $(subst PROJECT,$(PROJECT),$(LPC_DEPLOY))
deploy:
	$(DEPLOY_COMMAND)
endif

#########################################################################
#  Default rules to compile .c and .cpp file to .o
#  and assemble .s files to .o

.c.o :
	@echo
	@echo "Compiling: " $<
	$(GPP) $(GPFLAGS) -c $< -o $(<:.c=.o)

.cpp.o :
	@echo
	@echo "Compiling: " $<
	$(GPP) $(GPFLAGS) -c $< -o $(<:.cpp=.o)

.S.o :
	@echo
	@echo "Assembling: " $<
	$(AS) $(ASFLAGS) -c $< -o $(<:.S=.o)

#########################################################################
