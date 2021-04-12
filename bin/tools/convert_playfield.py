#!/usr/bin/env python
import sys

import matplotlib.image
import numpy

palette = {
    str(numpy.array([0.        , 0.        , 0.        ], dtype=numpy.float32)): 0x00,

    str(numpy.array([0.        , 0.06666667, 0.16470589], dtype=numpy.float32)): 0x10,
    str(numpy.array([0.        , 0.20392157, 0.30980393], dtype=numpy.float32)): 0xc0,
    str(numpy.array([0.        , 0.34901962, 0.45882353], dtype=numpy.float32)): 0xa2,
    str(numpy.array([0.01568628, 0.48627451, 0.60392159], dtype=numpy.float32)): 0xa6,
    str(numpy.array([0.        , 0.        , 0.41960785], dtype=numpy.float32)): 0xd0,
    str(numpy.array([0.03137255, 0.        , 0.55686277], dtype=numpy.float32)): 0xd0,
    str(numpy.array([0.17647059, 0.        , 0.73725492], dtype=numpy.float32)): 0xd0,
    str(numpy.array([0.30588236, 0.0627451 , 0.89411765], dtype=numpy.float32)): 0xd2,
    str(numpy.array([0.44313726, 0.18431373, 0.99607843], dtype=numpy.float32)): 0xd6,
    str(numpy.array([0.54509807, 0.5529412 , 0.99607843], dtype=numpy.float32)): 0xde,
    str(numpy.array([0.40000001, 0.40392157, 0.99607843], dtype=numpy.float32)): 0xda,

    str(numpy.array([0.56470591, 0.98823529, 0.78431374], dtype=numpy.float32)): 0x5e,
    str(numpy.array([0.10196079, 0.4627451 , 0.4627451 ], dtype=numpy.float32)): 0x72,
    str(numpy.array([0.50196081, 0.86274511, 0.86274511], dtype=numpy.float32)): 0x7c,
    str(numpy.array([0.40784314, 0.72941178, 0.86274511], dtype=numpy.float32)): 0x9a,
    str(numpy.array([0.34117648, 0.54509807, 0.78823531], dtype=numpy.float32)): 0xb8,
    str(numpy.array([0.28235295, 0.28235295, 0.76078433], dtype=numpy.float32)): 0xd6,
    str(numpy.array([0.36078432, 0.36078432, 0.82352942], dtype=numpy.float32)): 0xd8,
    str(numpy.array([0.9254902 , 0.9254902 , 0.9254902 ], dtype=numpy.float32)): 0xee,
}

def main():
    fname = sys.argv[1]
    im = matplotlib.image.imread(fname)

    # Creating 6 playfields
    colors = []
    pf = []
    for i in range(6):
        pf.append([])

    for ln in im:
        col = 0
        try: col = palette[str([e for e in ln if e[3] == 1.][0][:3])]
        except(IndexError): pass # Nothing to display, color is meaningless
        colors.append(col)

        # Retrieving bits
        bts = [int(p[3]) for p in ln]
        pf[0].append(bts[3] <<7 | bts[2] <<6 | bts[1] <<5 | bts[0] <<4)
        pf[1].append(bts[4] <<7 | bts[5] <<6 | bts[6] <<5 | bts[7] <<4 | bts[8] <<3 | bts[9] <<2 | bts[10]<<1 | bts[11])
        pf[2].append(bts[19]<<7 | bts[18]<<6 | bts[17]<<5 | bts[16]<<4 | bts[15]<<3 | bts[14]<<2 | bts[13]<<1 | bts[12])
        pf[3].append(bts[23]<<7 | bts[22]<<6 | bts[21]<<5 | bts[20]<<4)
        pf[4].append(bts[24]<<7 | bts[25]<<6 | bts[26]<<5 | bts[27]<<4 | bts[28]<<3 | bts[29]<<2 | bts[30]<<1 | bts[31])
        pf[5].append(bts[39]<<7 | bts[38]<<6 | bts[37]<<5 | bts[36]<<4 | bts[35]<<3 | bts[34]<<2 | bts[33]<<1 | bts[32])

    s = ', '.join(['$'+format(n, '02x') for n in colors])
    print('')
    print('.segment RODATA_SEGMENT')
    print('.align 256')
    print('col:')
    print('.byte {}'.format(s))
    for i in range(6):
        res = ['$'+format(n, '02x') for n in pf[i]]
        s = ', '.join(res)
        print('')
        print('.segment RODATA_SEGMENT')
        print('.align 256')
        print('pf{}:'.format(i))
        print('.byte {}'.format(s))

if __name__ == "__main__":
    main()
