BINNAME=Blank
AUTHOR=Tjoppen
DISTNAME=${BINNAME}_by_${AUTHOR}
DISTFILES=
SRCFILES=Makefile main.asm utils.asm
BINARY=build/pal.bin

#dasm build/main.asm -f3 -DPAL=0 -DFPS=60 -obuild/ntsc.bin -sbuild/ntsc.sym
#dasm build/main.asm -f3 -DPAL=1 -DFPS=60 -obuild/pal60.bin -sbuild/pal60.sym
all: build/bmpconv build/main.asm build/40x96.asm
	mkdir -p build && dasm build/main.asm -f3 -DPAL=1 -DFPS=50 -obuild/pal.bin -sbuild/pal.sym

build/bmpconv: bmpconv.c
	mkdir -p build
	gcc -std=c99 -O3 bmpconv.c -o build/bmpconv

# 32-bit Windows bmpconv.exe
# Requires mingw-w64, which can be handily installed on Debian-like systems with:
#
#  sudo apt-get install mingw-w64
#
build/bmpconv.exe: bmpconv.c
	mkdir -p build
	i686-w64-mingw32-gcc -O3 bmpconv.c -o build/bmpconv.exe

build/40x96.asm: 40x96.bmp build/bmpconv
	build/bmpconv 40x96.bmp > build/40x96.asm

build/main.asm: filter.py main.asm
	./filter.py < main.asm > build/main.asm

clean:
	rm -rf build ${DISTNAME} ${DISTNAME}.zip

run: all
	stella -grabmouse 0 ${BINARY}

jascpals: jascpalgen.c
	mkdir -p build
	gcc jascpalgen.c -o build/jascpalgen
	build/jascpalgen 0 > stella_pal.pal
	build/jascpalgen 1 > stella_ntsc.pal
	build/jascpalgen 2 > z26_pal.pal
	build/jascpalgen 3 > z26_ntsc.pal

dist: all
	rm -rf ${DISTNAME} ${DISTNAME}.zip
	mkdir -p ${DISTNAME}
	mkdir -p ${DISTNAME}/src
	if [ -n "${DISTFILES}" ] ; then cp ${DISTFILES} ${DISTNAME} ; fi
	cp ${SRCFILES} ${DISTNAME}/src
	cp build/ntsc.bin ${DISTNAME}/${BINNAME}\ \(NTSC\).bin
	cp build/pal.bin ${DISTNAME}/${BINNAME}\ \(PAL\).bin
	cp build/pal60.bin ${DISTNAME}/${BINNAME}\ \(PAL60\).bin

	zip -r ${DISTNAME}.zip ${DISTNAME}

	cp vcs.h macro.h ${DISTNAME}/src
	cd ${DISTNAME}/src && make

download: all
	stty -F /dev/ttyUSB0 115200
	harmonycart ${BINARY}

playmic:
	pacat -r --latency-msec=1 -d alsa_input.pci-0000_00_1b.0.analog-stereo | pacat -p --latency-msec=1 -d alsa_output.pci-0000_00_1b.0.analog-stereo
