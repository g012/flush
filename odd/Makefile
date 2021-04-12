DIRNAME := $(shell basename $(CURDIR))
PRGNAME := demo
PROGRAM := $(PRGNAME).bin
TYPE := 4k
SOURCES := src
INCLUDES := src
LIBS :=
OBJDIR := build
DEBUGDIR := #$(OBJDIR)/

LINKCFG := atari2600_$(TYPE).ld
ASFLAGS := --cpu 6502x
LDFLAGS	= -C$(LINKCFG) \
          -m $(DEBUGDIR)$(notdir $(basename $@)).map \
          -Ln $(DEBUGDIR)$(notdir $(basename $@)).labels -vm

EMULATORFLAGS := -type $(TYPE) -format pal
#EMULATORFLAGS := #-type $(TYPE) -format ntsc

################################################################################

CC            := cc65
LD            := ld65
AS            := ca65
AR            := ar65
OD            := od65
EMULATOR      := stella
DASM          := dasm

MKDIR         := mkdir
RM            := rm -f
RMDIR         := rm -rf

################################################################################

ofiles :=
sfiles := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
asmfiles := $(foreach dir,$(SOURCES),$(wildcard $(dir)/*.asm))
hfiles := $(foreach dir,$(SOURCES),$(wildcard $(dir)/*.h))
incfiles := $(foreach dir,$(INCLUDES),$(wildcard $(dir)/*.inc))
extra_includes := $(foreach i, $(INCLUDES), -I $i)

define depend
  my_obj := $$(addprefix $$(OBJDIR)/, $$(addsuffix .o65, $$(notdir $$(basename $(1)))))
  ofiles += $$(my_obj)

  $$(my_obj): $(1) $(incfiles) Makefile
	$$(AS) -g -o $$@ $$(ASFLAGS) $(extra_includes) $$<
endef

################################################################################

.SUFFIXES:
.PHONY: all clean run rundebug k65
#all: $(PROGRAM)
#defaults to DASM for the sound player
all: dasm
dasm: maind.bin
k65: program.bin
ca65: $(PROGRAM)

$(foreach file,$(sfiles),$(eval $(call depend,$(SOURCES)/$(file))))

$(OBJDIR):
	[ -d $@ ] || mkdir -p $@

$(PROGRAM): $(OBJDIR) $(ofiles)
	$(LD) -o $@ $(LDFLAGS) $(ofiles) $(LIBS)

maind.bin: $(SOURCES)/main.asm $(asmfiles) $(hfiles)
	$(DASM) $< -f3 -I$(INCLUDES) -o$@ -lmaind.lst -smaind.sym

program.bin:
	k65 @${SOURCES}/files.lst

run: $(PROGRAM)
	$(EMULATOR) $(EMULATORFLAGS) $(PROGRAM)

rundebug: $(PROGRAM)
	$(EMULATOR) -debug $(EMULATORFLAGS) $(PROGRAM)

rund: maind.bin
	$(EMULATOR) $(EMULATORFLAGS) maind.bin

rundebugd: maind.bin
	$(EMULATOR) -debug $(EMULATORFLAGS) maind.bin

clean:
	$(RM) $(ofiles) $(PROGRAM)
	$(RMDIR) $(OBJDIR)

stat: $(PROGRAM)
	$(OD) -S $(ofiles)|grep -v -e ' 0$$' -e 'Segment sizes:'|tee $(DEBUGDIR)stat.txt

zip: $(PROGRAM)
	$(RMDIR) $(OBJDIR);cd ..;rm -f $(PRGNAME).7z;7z a -mx=9 $(PRGNAME).zip $(PRGNAME)

7z: clean
	$(RMDIR) $(OBJDIR);cd ..;rm -f $(PRGNAME).zip;7z a -mx=9 -ms=on $(PRGNAME).7z $(PRGNAME)

hd: $(PROGRAM)
	hd $<

