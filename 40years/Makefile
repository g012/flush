CC ?= clang
ASMS=$(shell ls visy_anim/*.bmp | sed -e 's/bmp/asm/')

main.bin: main.asm fx.asm *.asm *.h multicolor_40xN_sprite/build/bmpconv bushnell.asm ${ASMS} candle.asm
	dasm main.asm -f3 -omain.bin -lmain.lst -smain.sym -d

multicolor_40xN_sprite/build/bmpconv: multicolor_40xN_sprite/bmpconv.c
	make -C multicolor_40xN_sprite build/bmpconv

visy_anim/%.asm: visy_anim/%.bmp multicolor_40xN_sprite/build/bmpconv
	# Fixed COLUBK = 0
	multicolor_40xN_sprite/build/bmpconv $< -P $(shell echo "$<" | sed -e 's|.*/||;s|\..*||') -k 0 > $@

bushnell.asm: gfx/bushnell3.bmp multicolor_40xN_sprite/build/bmpconv
	multicolor_40xN_sprite/build/bmpconv $< -P bushnell > $@

candle.asm: gfx/candle_NEW2.bmp multicolor_40xN_sprite/build/bmpconv
	multicolor_40xN_sprite/build/bmpconv $< -P candles -k 152 > $@

vcsconv: tools/vcsconv.c
	$(CC) -std=c99 -fno-strict-aliasing $< -lm -o $@

run: main.bin
	stella main.bin

rund: main.bin
	stella -debug main.bin

clean:
	rm -f main.bin main.lst main.sym vcsconv.exe vcsconv bushnell.asm visy_anim/*.asm candle.asm

