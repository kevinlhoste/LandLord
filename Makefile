BASE:=/usr

GCCPATH:=$(BASE)
CPU:=1788
TARGETCPU:=LPC177x_8x

#TARGETNAME:=$(firstword $(basename $(wildcard *.c)))
TARGETNAME:=main
SYSINC:=common
U8GPATH:=u8g
FREERTOSPATH=FreeRTOS
FREERTOSINCPATH=FreeRTOS/include
FREERTOSPORTPATH=FreeRTOS/portable
LDSCRIPTDIR:=$(SYSINC)
SRC:=$(wildcard *.c)
MCPU:=cortex-m3


SYSSRC:=$(wildcard $(SYSINC)/*.c)
SYSCPUSRC:=$(wildcard $(SYSINC)/$(TARGETCPU)/*.c)
STARTUP:=$(SYSINC)/$(TARGETCPU)/gcc_startup_$(TARGETCPU).S
LDSCRIPT:=$(LDSCRIPTDIR)/$(TARGETCPU)/$(TARGETCPU).ld

#ifndef cpu
#	cpu=lpc1768
#endif

#================================================
# Main part of the Makefile starts here. Usually no changes are needed.

# U8G Source files
U8GSRC:=$(wildcard $(U8GPATH)/*.c)
# U8GSRC=$(subst /,/,$(U8GSRC))
FREERTOSSRC:=$(wildcard $(FREERTOSPATH)/*.c)
# FREERTOSSRC=$(subst /,/,$(FREERTOSSRC))
FREERTOSPORTSRC:=$(wildcard $(FREERTOSPORTPATH)/*.c)
# FREERTOSPORTSRC=$(subst /,/,$(FREERTOSPORTSRC))

# Internal Variable Names
ELFNAME:=$(TARGETNAME).elf
BINNAME:=$(TARGETNAME).bin
HEXNAME:=$(TARGETNAME).hex
DISNAME:=$(TARGETNAME).dis
MAPNAME:=$(TARGETNAME).map
OBJ:=$(SRC:.c=.o) $(SYSSRC:.c=.o) $(SYSCPUSRC:.c=.o) $(FREERTOSSRC:.c=.o) $(FREERTOSPORTSRC:.c=.o) $(U8GSRC:.c=.o) $(STARTUP:.S=.o)
OBJSMALL:=$(SRC:.c=.o) $(SYSSRC:.c=.o) $(STARTUP:.S=.o)

# Replace standard build tools by avr tools
CC:=arm-none-eabi-gcc
AR:=arm-none-eabi-ar
AS:=arm-none-eabi-gcc
OBJCOPY:=arm-none-eabi-objcopy
OBJDUMP:=arm-none-eabi-objdump
SIZE:=arm-none-eabi-size

# Common flags
COMMON_FLAGS = -mthumb -mcpu=$(MCPU)
COMMON_FLAGS += -g
COMMON_FLAGS += -Wall -Wno-unknown-pragmas
COMMON_FLAGS += -I. -I$(SYSINC) -I$(SYSINC)/$(TARGETCPU) -I$(U8GPATH) -I$(FREERTOSINCPATH) -I$(FREERTOSPATH) -I$(FREERTOSPORTPATH)
# default stack size is 0x0c00
COMMON_FLAGS += -D__STACK_SIZE=0x0a00 -DdebugPrintf -DLOWSTACKWARNING -D$(TARGETCPU)
COMMON_FLAGS += -Os -flto
COMMON_FLAGS += -ffunction-sections -fdata-sections
# Assembler flags
ASFLAGS:=$(COMMON_FLAGS) -D__STARTUP_CLEAR_BSS -D__START=main
# C flags
CFLAGS:=$(COMMON_FLAGS) -std=gnu99
# LD flags
GC:=-Wl,--gc-sections
MAP:=-Wl,-Map=$(MAPNAME)
LFLAGS:=$(COMMON_FLAGS) $(GC) $(MAP)
	#without debug
LDLIBS:=--specs=nano.specs -lc -lc -lnosys -L$(LDSCRIPTDIR) -T $(LDSCRIPT)
	#With debug stdout -> openocd
#LDLIBS:=--specs=rdimon.specs -lc -lrdimon -L$(LDSCRIPTDIR) -T $(LDSCRIPT)

RM = del


# Additional Suffixes
.SUFFIXES: .elf .hex .dis .bin

# Targets
.PHONY: all
all: $(DISNAME) $(HEXNAME) $(BINNAME)
	@echo -e "Output: $(DISNAME) $(HEXNAME) $(BINNAME)/e[1;36m"
	@echo
	@$(SIZE) --format=SysV -x $(ELFNAME)
	@$(SIZE) $(ELFNAME)
	@echo
	@echo -e "/e[0m"

test:
	@echo -e "This is a test... $@ cpu is $(TARGETCPU)"

.PHONY: help
help:
	@echo -e "This is (no) help..."

.PHONY: upload
upload: $(DISNAME) $(HEXNAME) $(ELFNAME)
#	$(FLASHTOOL) HEXFILE/($(HEXNAME),NOCHECKSUMS,FILL,PROTECTISP/) COM/(5,38400/) DEVICE/($(FLASHMAGICDEVICE),12.000,0/)
#	$(SIZE) $(ELFNAME)

.PHONY: clean
clean:
	@echo -e "/e[1;37mRemoving all files.../e[0m/e[1;37m"
	$(RM) $(subst /,\,$(OBJ)) $(HEXNAME) $(BINNAME) $(ELFNAME) $(DISNAME) $(MAPNAME)

cleansmall:
	@echo -e "/e[1;37mRemoving some files.../e[0m/e[1;37m"
	$(RM) $(OBJSMALL) $(HEXNAME) $(BINNAME) $(ELFNAME) $(DISNAME) $(MAPNAME)

# implicit rules
%.o: %.c
	@echo -e "/e[1;37mCC /e[0m$< > $@/e[1;33m"
	$(CC) $(CFLAGS) -c -o $@ $< 2>&1

.S.o:
	@echo -e "/e[1;37mASM /e[0m$< > $@/e[1;37m"
	@$(PREPROCESS.S) $(COMMON_FLAGS) $(patsubst %.s,%.S,$<) > tmp.s
	@$(COMPILE.s) -c -o $@ tmp.s
	@$(RM) tmp.s

.elf.hex:
	@$(OBJCOPY) -O ihex $< $@

.elf.bin:
	@$(OBJCOPY) -O binary $< $@

# explicit rules
$(ELFNAME): $(OBJ)
	@echo -e "/e[1;37mLINKING /e[0m*.o > $@/e[1;37m"
	$(LINK.o) $(LFLAGS) $(OBJ) $(LDLIBS) -o $@

$(DISNAME): $(ELFNAME)
	@$(OBJDUMP) -S $< > $@

