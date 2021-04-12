#!/usr/bin/env python3
import matplotlib.image

DISPLAY_SIZE = 40 # 40 playfields pixels
MIN_TEXTURE = 6
STEP = 2

IMAGE = [
    [0,0,0,1,1,1,1,1,1,0,1,1,0,0,0,0,0,1,1,0,0,1,1,0,1,1,1,1,1,1,0,1,1,0,0,1,1,0,0,0],
    [0,0,0,1,1,0,0,0,0,0,1,1,0,0,0,0,0,1,1,0,0,1,1,0,1,1,0,0,0,0,0,1,1,0,0,1,1,0,0,0],
    [0,0,0,1,1,1,1,1,1,0,1,1,0,0,0,0,0,1,1,0,0,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,1,0,0,0,0,0,1,1,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0,1,1,0,1,1,0,0,1,1,0,0,0],
    [0,0,0,1,1,0,0,0,0,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,0,0,1,1,0,0,0],
]


def stretch(display_size, texture_size, sample):
    """Return the index of color of the display's sample, fetched from the
    texture once stretced.

    """
    return int(float(sample) / display_size * texture_size)


def stretch_table(texture_size):
    tex_offset = int((DISPLAY_SIZE - texture_size)/2)
    m = []
    for s in range(DISPLAY_SIZE):
        idx = stretch(DISPLAY_SIZE, texture_size, s)
        m.append(idx + tex_offset)
    return m


def get_pfs(ln):
    pf=[]
    pf.append(ln[3] <<7 | ln[2] <<6 | ln[1] <<5 | ln[0] <<4)
    pf.append(ln[4] <<7 | ln[5] <<6 | ln[6] <<5 | ln[7] <<4 | ln[8] <<3 | ln[9] <<2 | ln[10]<<1 | ln[11])
    pf.append(ln[19]<<7 | ln[18]<<6 | ln[17]<<5 | ln[16]<<4 | ln[15]<<3 | ln[14]<<2 | ln[13]<<1 | ln[12])
    pf.append(ln[23]<<7 | ln[22]<<6 | ln[21]<<5 | ln[20]<<4)
    pf.append(ln[24]<<7 | ln[25]<<6 | ln[26]<<5 | ln[27]<<4 | ln[28]<<3 | ln[29]<<2 | ln[30]<<1 | ln[31])
    pf.append(ln[39]<<7 | ln[38]<<6 | ln[37]<<5 | ln[36]<<4 | ln[35]<<3 | ln[34]<<2 | ln[33]<<1 | ln[32])
    return pf


def dump_data(data, name):
    s = ', '.join(['$'+format(n, '02x') for n in data])
    print('')
    print('{}:'.format(name))
    print('.byte {}'.format(s))


def main():
    pfs = [[] for i in range(6)]
    for texture_size in range(MIN_TEXTURE, DISPLAY_SIZE, STEP):
        table = stretch_table(texture_size)
        for ln in IMAGE:
            stretched_ln = [ln[i] for i in table]
            pf_line = get_pfs(stretched_ln)
            for i,v in enumerate(pf_line):
                pfs[i].append(v)
    for i,pf in enumerate(pfs):
        dump_data(pf, "stretch_pf{}".format(i))

main()
