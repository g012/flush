#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define WMAX 256
#define HMAX 256
#define RL32(arr, ofs) (arr[ofs] + (arr[ofs+1] << 8) + (arr[ofs+2] << 16) + (arr[ofs+3] << 24))

uint8_t header[54], image[HMAX][WMAX];
uint8_t palette[256][3] = { //stella_pal.pal
{0,0,0},{0,0,0},{43,43,43},{43,43,43},{82,82,82},{82,82,82},{118,118,118},{118,118,118},
{151,151,151},{151,151,151},{182,182,182},{182,182,182},{210,210,210},{210,210,210},{236,236,236},{236,236,236},
{0,0,0},{0,0,0},{43,43,43},{43,43,43},{82,82,82},{82,82,82},{118,118,118},{118,118,118},
{151,151,151},{151,151,151},{182,182,182},{182,182,182},{210,210,210},{210,210,210},{236,236,236},{236,236,236},
{128,88,0},{128,88,0},{150,113,26},{150,113,26},{171,135,50},{171,135,50},{190,156,72},{190,156,72},
{207,175,92},{207,175,92},{223,192,111},{223,192,111},{238,209,128},{238,209,128},{252,224,144},{252,224,144},
{68,92,0},{68,92,0},{94,121,26},{94,121,26},{118,147,50},{118,147,50},{140,172,72},{140,172,72},
{160,194,92},{160,194,92},{179,215,111},{179,215,111},{196,234,128},{196,234,128},{212,252,144},{212,252,144},
{112,52,0},{112,52,0},{137,81,26},{137,81,26},{160,107,50},{160,107,50},{182,132,72},{182,132,72},
{201,154,92},{201,154,92},{220,175,111},{220,175,111},{236,194,128},{236,194,128},{252,212,144},{252,212,144},
{0,100,20},{0,100,20},{26,128,53},{26,128,53},{50,152,82},{50,152,82},{72,176,110},{72,176,110},
{92,197,135},{92,197,135},{111,217,158},{111,217,158},{128,235,180},{128,235,180},{144,252,200},{144,252,200},
{112,0,20},{112,0,20},{137,26,53},{137,26,53},{160,50,82},{160,50,82},{182,72,110},{182,72,110},
{201,92,135},{201,92,135},{220,111,158},{220,111,158},{236,128,180},{236,128,180},{252,144,200},{252,144,200},
{0,92,92},{0,92,92},{26,118,118},{26,118,118},{50,142,142},{50,142,142},{72,164,164},{72,164,164},
{92,184,184},{92,184,184},{111,203,203},{111,203,203},{128,220,220},{128,220,220},{144,236,236},{144,236,236},
{112,0,92},{112,0,92},{132,26,116},{132,26,116},{150,50,137},{150,50,137},{168,72,158},{168,72,158},
{183,92,176},{183,92,176},{198,111,193},{198,111,193},{211,128,209},{211,128,209},{224,144,224},{224,144,224},
{0,60,112},{0,60,112},{25,90,137},{25,90,137},{47,117,160},{47,117,160},{68,142,182},{68,142,182},
{87,165,201},{87,165,201},{104,186,220},{104,186,220},{121,206,236},{121,206,236},{136,224,252},{136,224,252},
{88,0,112},{88,0,112},{110,26,137},{110,26,137},{131,50,160},{131,50,160},{150,72,182},{150,72,182},
{167,92,201},{167,92,201},{183,111,220},{183,111,220},{198,128,236},{198,128,236},{212,144,252},{212,144,252},
{0,32,112},{0,32,112},{25,63,137},{25,63,137},{47,90,160},{47,90,160},{68,116,182},{68,116,182},
{87,139,201},{87,139,201},{104,161,220},{104,161,220},{121,181,236},{121,181,236},{136,200,252},{136,200,252},
{52,0,128},{52,0,128},{74,26,150},{74,26,150},{95,50,171},{95,50,171},{114,72,190},{114,72,190},
{131,92,207},{131,92,207},{147,111,223},{147,111,223},{162,128,238},{162,128,238},{176,144,252},{176,144,252},
{0,0,136},{0,0,136},{26,26,157},{26,26,157},{50,50,176},{50,50,176},{72,72,194},{72,72,194},
{92,92,210},{92,92,210},{111,111,225},{111,111,225},{128,128,239},{128,128,239},{144,144,252},{144,144,252},
{0,0,0},{0,0,0},{43,43,43},{43,43,43},{82,82,82},{82,82,82},{118,118,118},{118,118,118},
{151,151,151},{151,151,151},{182,182,182},{182,182,182},{210,210,210},{210,210,210},{236,236,236},{236,236,236},
{0,0,0},{0,0,0},{43,43,43},{43,43,43},{82,82,82},{82,82,82},{118,118,118},{118,118,118},
{151,151,151},{151,151,151},{182,182,182},{182,182,182},{210,210,210},{210,210,210},{236,236,236},{236,236,236},
};
int disttab[256][256];
int x, y, w, h, bpp;
FILE *f;

//ROM to patch for .bin output
extern uint8_t rom[2048];

typedef struct {
    int pf[HMAX];
    int col1[HMAX], col2[HMAX];
    uint64_t grp[HMAX];
    int firstbadrow;
} picdata;

int compar(const void*a,const void*b) {
    const int *A = a;
    const int *B = b;
    return *B - *A;
}

static void usage(char **argv) {
    fprintf(stderr, "Usage: %s input.bmp [-p palette.pal] [-P prefix] [-k colubk] > output.asm\n", argv[0]);
    fprintf(stderr, "       %s input.bmp [-p palette.pal] [-P prefix] [-k colubk] -b output.bin\n", argv[0]);
    fprintf(stderr, "  -p filename\tUse specified palette file instead of hardcoded stella_pal.pal\n");
    fprintf(stderr, "  -b filename\tEnable binary output instead of generating asm. Useful for graphicians\n");
}

int main(int argc, char **argv) {
    const char *prefix = "";
    int fixedbk = -1;

    if (argc < 2) {
        usage(argv);
        return 1;
    }
    /* read 8-bit images as they are, RGB images as grayscale */
    if (!(f = fopen(argv[1], "rb"))) {
        fprintf(stderr, "failed to open %s\n" , argv[1]);
        return 1;
    }

    const char *palname = NULL;
    const char *binname = NULL;

    for (int o = 2; o < argc-1; o += 2) {
        if (!strcmp(argv[o], "-p")) {
            palname = argv[o+1];            
        } else if (!strcmp(argv[o], "-P")) {
            prefix = argv[o+1];
            fprintf(stderr, "changed prefix to \"%s\"\n", prefix);
        } else if (!strcmp(argv[o], "-k")) {
            fixedbk = atoi(argv[o+1]);
            fprintf(stderr, "fixed COLUBK = %i\n", fixedbk);
        } else if (!strcmp(argv[o], "-b")) {
            binname = argv[o+1];
        } else {
            usage(argv);
            return 1;
        }
    }

    //read palette
    if (palname) {
    FILE *p = fopen(palname, "r");
    if (!p) {
        fprintf(stderr, "Failed to open palette file %s\n", palname);
        return 1;
    }
    char temp[1000];
    fgets(temp, sizeof(temp), p);
    fgets(temp, sizeof(temp), p);
    fgets(temp, sizeof(temp), p);

    for (x = 0; x < 256; x++) {
        int r, g, b;
        fscanf(p, "%i %i %i", &r, &g, &b);
        palette[x][0] = r;
        palette[x][1] = g;
        palette[x][2] = b;
    }
    fclose(p);
    }

    //precompute color distances
    for (y = 0; y < 256; y++) {
        for (x = 0; x < 256; x++) {
            int dr = palette[x][0] - palette[y][0];
            int dg = palette[x][1] - palette[y][1];
            int db = palette[x][2] - palette[y][2];
            //round the numbers a bit so adding them up fits nicer into int
            disttab[y][x] = dr*dr + dg*dg + db*db;
            //fprintf(stderr, "%i ", disttab[y][x]);
        }
        //fprintf(stderr, "\n");
    }

    fread(header, 54, 1, f);

    w = RL32(header, 18);
    h = RL32(header, 22);
    bpp = header[28] + (header[29] << 8);
    fseek(f, RL32(header, 10), SEEK_SET);

    fprintf(stderr, "%ix%i %i bpp\n", w, h, bpp);

    if (w > WMAX || h > HMAX) {
        fprintf(stderr, "image too large\n");
        return -1;
    }

    for (y = h-1; y >= 0; y--) {
        switch(bpp) {
        case 8:
            fread(image[y], w, 1, f);
            break;
        case 24:
        case 32:
            for (x = 0; x < w; x++) {
                int temp = getc(f) + getc(f) + getc(f);
                if (bpp == 32) getc(f);
                image[y][x] = temp / 3;
            }
            break;
        default:
            fprintf(stderr, "can't handle %i-bit BMPs\n", bpp);
        }

        /* align */
        if (w*(bpp/8) & 3)
            fseek(f, 4 - (w*(bpp/8) & 3), SEEK_CUR);
    }

    fclose(f);

    //grab and sort histogram
    int hist[256][2];
    int hascolor[256] = {0};
    for (x = 0; x <256; x++) {
        hist[x][0] = 0;
        hist[x][1] = x;
    }
    int ncolors = 0;
    for (y = 0; y < h; y++) {
        for (x = 0; x < w; x++) {
            //conform color indices in case the artist didn't use only even ones
            image[y][x] &= 0xFE;

            //force grayscale to 0x00-0x0E
            if ((image[y][x] & 0xF0) == 0x10 ||
                (image[y][x] & 0xF0) == 0xE0 ||
                (image[y][x] & 0xF0) == 0xF0)
                image[y][x] &= 0x0F;

            hist[image[y][x]][0]++;
            if (!hascolor[image[y][x]]) {
                ncolors++;
            }
            hascolor[image[y][x]] = 1;
        }
    }
    qsort(hist, 256, sizeof(int)*2, compar);

    //brute force conversion
    //tries all possible combinations of background colors,
    //and foreground colors on a per-line basis
    //only tries to use colors which are actually in the image, to speed things up
    int bestpicscore = -1, bestbk;
    picdata bestpic;
    for (int histidx = 0; histidx < 256; histidx++) {
        int bk = fixedbk == -1 ? hist[histidx][1] : fixedbk;

        if (hist[histidx][0] == 0) {
            //only unused colors past this point
            break;
        }

        //given bk, build pic line by line
        picdata pic;
        pic.firstbadrow = -1;
        int totalpicscore = 0;
        for (y = 0; y < h; y++) {
            int bestrowscore = -1;
            for (int col1 = 0; col1 < 256; col1 += 2) {
                if (!hascolor[col1] || (col1 == bk && ncolors >= 3)) {
                    continue;
                }
                for (int col2 = col1 + 2; col2 < 256; col2 += 2) {
                    if (!hascolor[col2]  || (col2 == bk && ncolors >= 3)) {
                        continue;
                    }
                    int PF = 0;
                    uint64_t GRP = 0;

                    int totscore = 0;
                    //do one 4x1 block at a time
                    for (int block = 0; block < 10; block++) {
                        //for each block, pick whichever combination of pf and grp is closest
                        int best = -1, bestpf, bestgrp;
                        for (int pf = 0; pf < 2; pf++) {
                            int grp = 0, score = 0;
                            //we can do each bit independently
                            for (int bit = 0; bit < 4; bit++) {
                                //compare 1 to 0
                                int one = disttab[image[y][block*4 + bit]][bk];
                                int zero = disttab[image[y][block*4 + bit]][pf ? col2 : col1];
                                if (one < zero) {
                                    grp |= 1 << bit;
                                    score += one;
                                } else {
                                    score += zero;
                                }
                            }
                            if (best == -1 || score < best) {
                                best = score;
                                bestpf = pf;
                                bestgrp = grp;
                            }
                        }

                        totscore += best;
                        PF |= bestpf << block;
                        GRP |= (uint64_t)bestgrp << (block * 4);

                        //abort early if we can
                        if (bestrowscore != -1 && totscore > bestrowscore) {
                            break;
                        }
                    }

                    if (bestrowscore == -1 || totscore < bestrowscore) {
                        bestrowscore = totscore;
                        pic.pf[y] = PF;
                        pic.grp[y] = GRP;
                        pic.col1[y] = col1;
                        pic.col2[y] = col2;
                    }
                }
            }
            if (bestrowscore > 0 && pic.firstbadrow == -1) {
                pic.firstbadrow = y;
            }
            totalpicscore += bestrowscore;
            fprintf(stderr, ".");
            fflush(stderr);

            //here's another chance to abort early
            if (bestpicscore != -1 && totalpicscore > bestpicscore) {
                for (y++; y < h; y++) {
                    fprintf(stderr, " ");
                }
                break;
            }
        }
        if (bestpicscore == -1 || totalpicscore < bestpicscore) {
            bestpicscore = totalpicscore;
            bestpic = pic;
            bestbk = bk;
            if (bestpicscore == 0) {
                fprintf(stderr, " bk = %3i -> score = %i PERFECT\n", bk, bestpicscore);
                break;
            }
            fprintf(stderr, " bk = %3i -> score = %i BEST SO FAR\n", bk, bestpicscore);
            if (fixedbk != -1) {
                break;
            }
        } else {
            fprintf(stderr, " bk = %3i -> score = %i\n", bk, bestpicscore);
        }
    }

    if (bestpicscore > 0) {
        fprintf(stderr, "\n*** One or more lines are approximate, first one is y=%i ***\n\n", bestpic.firstbadrow);
    }

    if (binname) {
        //binary output
        //patch ROM, then write to binname
        for (y = h-1; y >= 0; y--) {
            //SPRITE0..4
            for (int col = 0; col < 5; col++) {
                int g = (bestpic.grp[y] >> (col*8)) & 0xFF;
                //flip bigs
                int f = 0;
                for (int b = 0; b < 8; b++) {
                    f |= ((g >> b) & 1) << (7-b);
                }
                rom[128*col + h-1-y] = f;
            }
            //ATTR0..1
            rom[0x280 + h-1-y] = (bestpic.pf[y] >> 3) & 0xF0;
            rom[0x300 + h-1-y] = (bestpic.pf[y] & 127) << 1;
            //COL2..1
            rom[0x380 + h-1-y] = bestpic.col2[y];
            rom[0x400 + h-1-y] = bestpic.col1[y];
        }
        //SPRITEBK
        rom[0x4b8] = rom[0x544] = rom[0x573] = bestbk;
        //SPRITEH
        rom[0x501] = (228-2*h)/2; //vertical centering
        rom[0x508] = h-1;

        FILE *bin = fopen(binname, "wb");
        if (!bin) {
            fprintf(stderr, "Couldn't open %s for writing\n", binname);
            return 1;
        }
        fprintf(stderr, "Writing ROM file %s\n", binname);
        fwrite(rom, sizeof(rom), 1, bin);
        fclose(bin);
    } else {
    fprintf(stderr, "Generating ASM data\n");
    //pixel data
    int col;
    for (col = 0; col < 5; col++) {
        printf("    MAC %sSPRITE%i\n", prefix, col);
        printf("%sSprite%i\n", prefix, col);
        for (y = h-1; y >= 0; y--) {
            int g = (bestpic.grp[y] >> (col*8)) & 0xFF;
            printf("    .byte %%%i%i%i%i%i%i%i%i\n",
                (g >> 0) & 1, (g >> 1) & 1, (g >> 2) & 1, (g >> 3) & 1,
                (g >> 4) & 1, (g >> 5) & 1, (g >> 6) & 1, (g >> 7) & 1
            );
        }
        printf("    ENDM\n");
    }

    //line colors
    printf("    MAC %sCOL1\n", prefix);
    printf("%sCol1\n", prefix);
    for (y = h-1; y >= 0; y--)
        printf("    .byte %i\n", bestpic.col1[y]);
    printf("    ENDM\n");

    printf("    MAC %sCOL2\n", prefix);
    printf("%sCol2\n", prefix);
    for (y = h-1; y >= 0; y--)
        printf("    .byte %i\n", bestpic.col2[y]);
    printf("    ENDM\n");

    //attributes
    //PF0 = 0..2
    printf("    MAC %sATTR0\n", prefix);
    printf("%sAttr0\n", prefix);
    for (y = h-1; y >= 0; y--) {
        printf("    .byte %i\n", (bestpic.pf[y] >> 3) & 0xF0);
    }
    printf("    ENDM\n");

    //PF2 = 1..7
    printf("    MAC %sATTR1\n", prefix);
    printf("%sAttr1\n", prefix);
    for (y = h-1; y >= 0; y--) {
        printf("    .byte %i\n", (bestpic.pf[y] & 127) << 1);
    }
    printf("    ENDM\n");

    printf("%sSPRITEH equ %i\n", prefix, h);
    printf("%sSPRITEBK equ %i\n", prefix, bestbk);
    }
    fprintf(stderr, "%s: done\n", argv[0]);

    return 0;
}

uint8_t rom[2048] = {
0xff,0xff,0xfc,0xf0,0xe0,0xc0,0x80,0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0x80,0xc0,0xe0,0xf0,0xfc,0xff,0xff,0xff,0xff,0xff,0xfe,0xf0,0xe0,0x00,0x00,0x00,
0x38,0x88,0x86,0x83,0xc0,0xc0,0xfc,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x97,0xc3,0xf1,0xf0,0xd0,0xd1,0xe1,0xf9,0xf9,0xfc,0xe4,0xf8,0xfe,0xf9,0xfe,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0x07,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x07,0xff,0xff,0xff,0xff,0xfe,0x0f,0x01,0x00,0x00,0x00,0x03,
0x04,0x00,0x00,0xc0,0x00,0x00,0x00,0xe0,0xe0,0xf0,0xf0,0xf0,0xf0,0xf8,0xf8,0x7c,0x3c,0x3e,0x9f,0x9f,0x1f,0x1f,0x2f,0x2f,0xaf,0x93,0x48,0x22,0x1c,0x81,0xe3,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xe0,0xc0,0xc0,0xc0,0xc0,0xc0,0xe0,0xff,0x7f,0x3f,0x1f,0x0f,0x0f,0x07,0x07,0x07,0x07,0x07,0x07,0x07,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xf8,0xf8,0xf8,0xf8,0xf8,0x78,0x38,0x3c,0x1c,0x1e,0x1f,0x1f,0x1f,0x1f,0x1f,0x3f,0x3f,0x7f,0xff,0xff,0xff,0xff,0xff,0xff,0x80,0x00,0x00,0x80,0x01,0x06,0x38,0xe0,
0x00,0x00,0x00,0x0c,0x30,0xe0,0x60,0x00,0x00,0x10,0x10,0x10,0x88,0x88,0x48,0x2c,0x24,0x26,0x10,0x00,0x00,0x0e,0x15,0x28,0xa4,0xbf,0x80,0x60,0xf0,0xfc,0xf2,0xf8,
0xfe,0xfe,0xfe,0xfc,0xf8,0xf8,0xfa,0xfa,0xf8,0xf8,0xf8,0xfd,0xff,0x7f,0x7f,0x7f,0x7f,0x7f,0xff,0xff,0xff,0xff,0xff,0xfe,0xfe,0xfe,0xfe,0xfe,0xfe,0xfe,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0xe0,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x0e,0x03,0x00,0x00,0xff,0x00,0x00,0x00,
0x10,0x1e,0x01,0x00,0x00,0x00,0x01,0x0f,0x07,0x8f,0x8f,0x8f,0x8f,0xcf,0x4f,0x47,0x27,0x27,0x17,0x03,0x03,0x01,0x01,0x81,0x81,0x03,0x03,0x03,0x00,0x01,0x02,0x00,
0x06,0x09,0x02,0x04,0x00,0x08,0x08,0x10,0x80,0x80,0x80,0xc0,0xf0,0xff,0xff,0xff,0xff,0xf8,0xe0,0xc0,0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x03,0x07,0x0f,0x3f,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x0f,0x03,0x01,0x00,0x80,0x60,0x00,0x00,
0x00,0x00,0xff,0x01,0x03,0x1f,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x7f,0xbf,0x1f,0x2f,
0x1f,0x6f,0x9f,0x87,0x07,0x07,0x0b,0x03,0x07,0x0f,0x1f,0x0f,0x3f,0xff,0xff,0xff,0xff,0x0f,0x03,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0x70,0x70,0x70,0x70,0x70,0x70,0x70,0x70,0x70,0x70,0x70,0x30,0x30,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x00,0x00,0x10,0x10,0x10,0x10,0x30,0x30,0x30,0x30,
0x20,0x00,0x10,0x10,0x10,0x40,0x40,0x40,0x40,0x00,0x00,0x00,0x30,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0x80,0x80,0x80,0x3e,0x3e,0x3e,0x3e,0x3e,0x1e,0x1c,0x1c,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x60,0x70,0x58,0x58,0x50,0x50,0x50,0x50,0x50,0x70,0xf0,0xf0,0xf0,0xe0,0xe0,0xe0,0xe0,0x0c,0x0c,0xe0,0xa0,0xe0,0x80,0x80,0x80,0x80,0x80,
0x80,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0x40,0x40,0x40,0x40,0x18,0x10,0x38,0x10,0x38,0x28,0x18,0x06,0x0e,0x0e,0x0e,0x0e,0x0e,0x1e,0x1e,0x1e,0x1e,0x1e,0x1e,0x1e,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0x86,0x86,0x86,0x86,0x86,0x86,0x86,0x86,0x86,0x86,0x86,0x86,0x86,0x6a,0x6a,0x6a,0x6a,0x6a,0x6a,0x6a,0x6a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,0x2a,
0x2a,0x2a,0x2a,0x2a,0x2a,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xd6,0xc6,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,
0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0xbe,0x60,0x8e,0x60,0x8e,0x60,0x60,0x60,0xb4,0xb4,0xb4,0xb4,0xb4,0xb4,0xb4,0xb4,0xb4,0xb4,0xb4,0xb4,0xb4,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0x0e,0x0e,0x6a,0x6a,0x6a,0x6a,0x6a,0x6a,0x6a,0x6a,0x6a,0x6a,0x6a,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,
0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0x0e,0xba,0xba,0xba,0xba,0xba,0xba,0xba,0xba,0x48,0x2a,0x36,0x56,0x76,0x96,0xb6,0xbe,0xbe,0xa6,0x86,0x66,0x48,0x4e,0x3c,0x58,0x8e,
0x8e,0x8e,0x8e,0x2c,0x2e,0x4e,0x4c,0x4a,0x4c,0x6c,0x66,0x62,0x0e,0x60,0x0e,0x60,0x0e,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0x18,0x85,0x02,0xe9,0x0f,0xb0,0xfc,0x49,0x07,0x0a,0x0a,0x0a,0x0a,0x95,0x20,0x95,0x10,0x60,0xa9,0x38,0xa2,0x00,0x20,0x80,0x1c,0xa9,0x40,0xe8,0x20,0x80,0x1c,0xa9,
0x11,0xe8,0x20,0x80,0x1c,0xa9,0x61,0xe8,0x20,0x80,0x1c,0xa9,0x33,0x85,0x04,0x85,0x05,0x85,0x26,0x85,0x1d,0x85,0x1e,0xa9,0xd2,0x85,0x06,0x85,0x07,0xa2,0x65,0xbd,
0x16,0x1d,0x95,0x86,0xca,0x10,0xf8,0x60,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xa2,0x12,0x85,0x02,0xca,0xd0,0xfb,0xa0,0x5f,0x20,0xfe,0x1f,0x20,0xfe,0x1f,0x20,0xfe,0x1f,0x68,0x48,0xa1,0x80,0xb9,0x80,0x1a,0x85,0x0d,0xb9,0x00,0x1b,0x85,0x0f,
0xb9,0x80,0x18,0x85,0x1c,0xb9,0x00,0x18,0x85,0x1b,0xb9,0x80,0x19,0x85,0x1c,0xbe,0x00,0x1a,0xb9,0x80,0x1b,0x85,0x08,0xb9,0x00,0x1c,0x85,0x09,0xb9,0x00,0x19,0x85,
0x1b,0x86,0x1b,0xa9,0xd2,0x8d,0x09,0x00,0x85,0x08,0x20,0xfe,0x1f,0xea,0xea,0xb9,0x80,0x18,0x85,0x1c,0xb9,0x00,0x18,0x85,0x1b,0xb9,0x80,0x19,0x85,0x1c,0xbe,0x00,
0x1a,0xb9,0x80,0x1b,0x85,0x08,0xb9,0x00,0x1c,0x85,0x09,0xb9,0x00,0x19,0x85,0x1b,0x86,0x1b,0xa9,0xd2,0x88,0x85,0x09,0x85,0x08,0x10,0x9b,0x60,0x78,0xd8,0xa2,0x00,
0x8a,0xa8,0xca,0x9a,0x48,0xd0,0xfb,0xa9,0x0e,0x85,0x02,0x85,0x00,0x4a,0xd0,0xf9,0xa9,0x27,0x8d,0x96,0x02,0xe6,0x80,0x20,0x92,0x1c,0x20,0xbb,0x1d,0xa9,0x13,0x8d,
0x97,0x02,0xa9,0x00,0x85,0x02,0x85,0x2a,0x85,0x01,0x20,0x00,0x1d,0x20,0xbb,0x1d,0xa9,0x16,0x8d,0x96,0x02,0x20,0xbb,0x1d,0x4c,0x87,0x1d,0xad,0x85,0x02,0xf0,0xfb,
0x60,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x7c,0x1d,0xea,0x60,
};
