CC ?= clang

.PHONY: vcsconv

program.bin: main.k65 common.k65 vcsconv
	./vcsconv update main.k65
	k65 @k65files.lst

vcsconv: vcsconv.c
	$(CC) -std=c99 -fno-strict-aliasing $< -lm -o $@

clean:
	rm -f program.bin program.lst program.sym vcsconv.exe vcsconv

run: program.bin
	stella program.bin

rund: program.bin
	stella -debug program.bin

vidrec: program.bin
	mame64 a2600p -nofilter -aviwrite demo.avi -cart program.bin

vidstretch:
	ffmpeg -y -i snap/demo.avi -strict -2 scale=iw*2:ih:flags=neighbor -crf 23 -preset veryslow -pix_fmt yuv420p demo.mp4
