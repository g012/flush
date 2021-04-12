#!/usr/bin/env python
import sys

import matplotlib.image
import numpy

palette = {
    str(numpy.array([0., 0.06666667, 0.16470589], dtype=numpy.float32)): 0x10,
    str(numpy.array([0., 0.20392157, 0.30980393], dtype=numpy.float32)): 0xc0,
    str(numpy.array([0., 0.34901962, 0.45882353], dtype=numpy.float32)): 0xa2,

    str(numpy.array([0., 0.1254902 , 0.43921569], dtype=numpy.float32)): 0xb0,
    str(numpy.array([0.20392157, 0., 0.50196081], dtype=numpy.float32)): 0xc0,
    str(numpy.array([0.34509805, 0., 0.43921569], dtype=numpy.float32)): 0xa0,
    str(numpy.array([0.51764709, 0.10196079, 0.45490196], dtype=numpy.float32)): 0x82,
    str(numpy.array([0.71372551, 0.28235295, 0.43137255], dtype=numpy.float32)): 0x66,

    str(numpy.array([0.43921569, 0.        , 0.07843138], dtype=numpy.float32)): 0x60,
    str(numpy.array([0.53725493, 0.10196079, 0.20784314], dtype=numpy.float32)): 0x62,
    str(numpy.array([0.627451  , 0.19607843, 0.32156864], dtype=numpy.float32)): 0x64,
    str(numpy.array([0.78823531, 0.36078432, 0.52941179], dtype=numpy.float32)): 0x68,
}

def main():
    fname = sys.argv[1]
    im = matplotlib.image.imread(fname)

    res = [palette[str(ln[0])] for ln in im]
    res = ['$'+format(n, '02x') for n in res]
    s = ', '.join(res)
    print('')
    print('.segment RODATA_SEGMENT')
    print('.align 256')
    print('bg:')
    print('.byte {}'.format(s))

if __name__ == "__main__":
    main()
