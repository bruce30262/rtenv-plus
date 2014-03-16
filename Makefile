SHELL = /bin/bash
TARGET = main
.DEFAULT_GOAL = all

QEMU_STM32 ?= ../qemu_stm32/arm-softmmu/qemu-system-arm
CROSS_COMPILE ?= arm-none-eabi-
CC := $(CROSS_COMPILE)gcc
CFLAGS = -fno-common -ffreestanding -O0 \
         -gdwarf-2 -g3 -Wall -Werror \
         -mcpu=cortex-m3 -mthumb \
         -Wl,-Tmain.ld -nostartfiles \
		 $(DEBUG_FLAGS) \
         -DUSER_NAME=\"$(USER)\"

ARCH = CM3
VENDOR = ST
PLAT = STM32F10x

LIBDIR = .
CMSIS_LIB=$(LIBDIR)/libraries/CMSIS/$(ARCH)
STM32_LIB=$(LIBDIR)/libraries/STM32F10x_StdPeriph_Driver

CMSIS_PLAT_SRC = $(CMSIS_LIB)/DeviceSupport/$(VENDOR)/$(PLAT)


OUTDIR = build
SRCDIR = src \
         $(CMSIS_LIB)/CoreSupport \
         $(STM32_LIB)/src \
         $(CMSIS_PLAT_SRC)
INCDIR = include \
         $(CMSIS_LIB)/CoreSupport \
         $(STM32_LIB)/inc \
         $(CMSIS_PLAT_SRC)
INCLUDES = $(addprefix -I,$(INCDIR))
DATDIR = data
TOOLDIR = tool

SRC = $(wildcard $(addsuffix /*.c,$(SRCDIR))) \
      $(wildcard $(addsuffix /*.s,$(SRCDIR))) \
      $(CMSIS_PLAT_SRC)/startup/gcc_ride7/startup_stm32f10x_md.s 
OBJ := $(addprefix $(OUTDIR)/,$(patsubst %.s,%.o,$(SRC:.c=.o)))
DEP = $(OBJ:.o=.o.d)
DAT =

MAKDIR = mk
MAK = $(wildcard $(MAKDIR)/*.mk)


include $(MAK)

all: $(OUTDIR)/$(TARGET).bin $(OUTDIR)/$(TARGET).lst

$(OUTDIR)/$(TARGET).bin: $(OUTDIR)/$(TARGET).elf
	@echo "    OBJCOPY "$@
	@$(CROSS_COMPILE)objcopy -Obinary $< $@

$(OUTDIR)/$(TARGET).lst: $(OUTDIR)/$(TARGET).elf
	@echo "    LIST    "$@
	@$(CROSS_COMPILE)objdump -S $< > $@

$(OUTDIR)/$(TARGET).elf: $(OBJ) $(DAT)
	@echo "    LD      "$@
	@echo "    MAP     "$(OUTDIR)/$(TARGET).map
	@$(CROSS_COMPILE)gcc $(CFLAGS) -Wl,-Map=$(OUTDIR)/$(TARGET).map -o $@ $^

$(OUTDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "    CC      "$@
	@$(CROSS_COMPILE)gcc $(CFLAGS) -MMD -MF $@.d -o $@ -c $(INCLUDES) $<

$(OUTDIR)/%.o: %.s
	@mkdir -p $(dir $@)
	@echo "    CC      "$@
	@$(CROSS_COMPILE)gcc $(CFLAGS) -MMD -MF $@.d -o $@ -c $(INCLUDES) $<

check: src/unit_test.c include/unit_test.h
	$(MAKE) $(OUTDIR)/main.bin DEBUG_FLAGS=-DDEBUG
	$(QEMU_STM32) -nographic -M stm32-p103 \
		-gdb tcp::3333 -S \
		-serial stdio \
		-kernel $(OUTDIR)/main.bin -monitor null >/dev/null &
	@echo
	$(CROSS_COMPILE)gdb -batch -x test/test-strlen.in
	@mv -f gdb.txt test/test-strlen.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x test/test-strcpy.in
	@mv -f gdb.txt test/test-strcpy.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x test/test-strcmp.in
	@mv -f gdb.txt test/test-strcmp.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x test/test-strncmp.in
	@mv -f gdb.txt test/test-strncmp.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x test/test-cmdtok.in
	@mv -f gdb.txt test/test-cmdtok.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x test/test-itoa.in
	@mv -f gdb.txt test/test-itoa.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x test/test-find_events.in
	@mv -f gdb.txt test/test-find_events.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x test/test-find_envvar.in
	@mv -f gdb.txt test/test-find_envvar.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x test/test-fill_arg.in
	@mv -f gdb.txt test/test-fill_arg.txt
	@echo
	$(CROSS_COMPILE)gdb -batch -x test/test-export_envvar.in
	@mv -f gdb.txt test/test-export_envvar.txt
	@echo
	@pkill -9 $(notdir $(QEMU_STM32))

clean:
	rm -rf $(OUTDIR) test/test-*.txt 

-include $(DEP)
