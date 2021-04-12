#!/usr/bin/env python
import sys

import matplotlib.image
import numpy
import json

palette = {
    (0x00, 0x00, 0x00): 0x00,
    (0x28, 0x28, 0x28): 0x02,
    (0x50, 0x50, 0x50): 0x04,
    (0x74, 0x74, 0x74): 0x06,
    (0x94, 0x94, 0x94): 0x08,
    (0xb4, 0xb4, 0xb4): 0x0a,
    (0xd0, 0xd0, 0xd0): 0x0c,
    (0xec, 0xec, 0xec): 0x0e,

    (0x80, 0x50, 0x00): 0x20,
    (0x94, 0x70, 0x20): 0x22,
    (0xa8, 0x84, 0x3c): 0x24,
    (0xbc, 0x9c, 0x58): 0x26,
    (0xcc, 0xac, 0x70): 0x28,
    (0xdc, 0xc0, 0x84): 0x2a,
    (0xec, 0xd0, 0x9c): 0x2c,
    (0xfc, 0xe0, 0xb0): 0x2e,

    (0x44, 0x5c, 0x00): 0x30,
    (0x5c, 0x78, 0x20): 0x32,
    (0x74, 0x90, 0x3c): 0x34,
    (0x8c, 0xac, 0x48): 0x36,
    (0xa0, 0xc0, 0x70): 0x38,
    (0xb0, 0xd4, 0x84): 0x3a,
    (0xc4, 0xe8, 0x9c): 0x3c,
    (0xd4, 0xfc, 0xb0): 0x3e,

    (0x70, 0x34, 0x00): 0x40,
    (0x88, 0x50, 0x20): 0x42,
    (0xa0, 0x68, 0x3c): 0x44,
    (0xb4, 0x84, 0x58): 0x46,
    (0xc8, 0x98, 0x70): 0x48,
    (0xdc, 0xac, 0x84): 0x4a,
    (0xec, 0xc0, 0x9c): 0x4c,
    (0xfc, 0xd4, 0xb0): 0x4e,

    (0x00, 0x64, 0x14): 0x50,
    (0x20, 0x80, 0x34): 0x52,
    (0x3c, 0x98, 0x50): 0x54,
    (0x58, 0xb0, 0x6c): 0x56,
    (0x70, 0xc4, 0x84): 0x58,
    (0x84, 0xd8, 0x9c): 0x5a,
    (0x9c, 0xe8, 0xb4): 0x5c,
    (0xb0, 0xfc, 0xc8): 0x5e,

    (0x70, 0x00, 0x14): 0x60,
    (0x88, 0x20, 0x34): 0x62,
    (0xa0, 0x3c, 0x50): 0x64,
    (0xb4, 0x58, 0x6c): 0x66,
    (0xc8, 0x70, 0x84): 0x68,
    (0xdc, 0x84, 0x9c): 0x6a,
    (0xec, 0x9c, 0xb4): 0x6c,
    (0xfc, 0xb0, 0xc8): 0x6e,

    (0x00, 0x5c, 0x5c): 0x70,
    (0x20, 0x74, 0x74): 0x72,
    (0x3c, 0x8c, 0x8c): 0x74,
    (0x58, 0xa4, 0xa4): 0x76,
    (0x70, 0xb8, 0xb8): 0x78,
    (0x84, 0xc8, 0xc8): 0x7a,
    (0x9c, 0xdc, 0xdc): 0x7c,
    (0xb0, 0xec, 0xec): 0x7e,

    (0x70, 0x00, 0x5c): 0x80,
    (0x84, 0x20, 0x74): 0x82,
    (0x94, 0x3c, 0x88): 0x84,
    (0xa8, 0x58, 0x9c): 0x86,
    (0xb4, 0x70, 0xb0): 0x88,
    (0xc4, 0x84, 0xc0): 0x8a,
    (0xd0, 0x9c, 0xd0): 0x8c,
    (0xe0, 0xb0, 0xe0): 0x8e,

    (0x00, 0x3c, 0x70): 0x90,
    (0x1c, 0x58, 0x88): 0x92,
    (0x38, 0x74, 0xa0): 0x94,
    (0x50, 0x8c, 0xb4): 0x96,
    (0x68, 0xa4, 0xc8): 0x98,
    (0x7c, 0xb8, 0xdc): 0x9a,
    (0x90, 0xcc, 0xec): 0x9c,
    (0xa4, 0xe0, 0xfc): 0x9e,

    (0x58, 0x00, 0x70): 0xa0,
    (0x6c, 0x20, 0x88): 0xa2,
    (0x80, 0x3c, 0xa0): 0xa4,
    (0x94, 0x58, 0xb4): 0xa6,
    (0xa4, 0x70, 0xc8): 0xa8,
    (0xb4, 0x84, 0xdc): 0xaa,
    (0xc4, 0x9c, 0xec): 0xac,
    (0xd4, 0xb0, 0xfc): 0xae,

    (0x00, 0x20, 0x70): 0xb0,
    (0x1c, 0x3c, 0x88): 0xb2,
    (0x38, 0x58, 0xa0): 0xb4,
    (0x50, 0x74, 0xb4): 0xb6,
    (0x68, 0x88, 0xc8): 0xb8,
    (0x7c, 0xa0, 0xdc): 0xba,
    (0x90, 0xb4, 0xec): 0xbc,
    (0xa4, 0xc8, 0xfc): 0xbe,

    (0x3c, 0x00, 0x80): 0xc0,
    (0x54, 0x20, 0x94): 0xc2,
    (0x6c, 0x3c, 0xa8): 0xc4,
    (0x80, 0x58, 0xbc): 0xc6,
    (0x94, 0x70, 0xcc): 0xc8,
    (0xa8, 0x84, 0xdc): 0xca,
    (0xb8, 0x9c, 0xec): 0xcc,
    (0xc8, 0xb0, 0xfc): 0xce,

    (0x00, 0x00, 0x88): 0xd0,
    (0x20, 0x20, 0x9c): 0xd2,
    (0x3c, 0x3c, 0xb0): 0xd4,
    (0x58, 0x58, 0xc0): 0xd6,
    (0x70, 0x70, 0xd0): 0xd8,
    (0x84, 0x84, 0xe0): 0xda,
    (0x9c, 0x9c, 0xec): 0xdc,
    (0xb0, 0xb0, 0xfc): 0xde,
}



def best_palette_match(col):
    m_key = None
    m_col = None
    m_nor = None
    for k in palette.keys():
        c = numpy.array(k) / 256.
        n = numpy.linalg.norm(c - col)
        if (m_nor is None or n < m_nor):
            m_key = k
            m_col = c
            m_nor = n
    # Debug stuff
    # print col, m_key, m_col, m_nor
    return palette[m_key]


def main():
    fname = sys.argv[1]

    # Parses colors from the playfield graphic
    im = matplotlib.image.imread(fname)
    cols = []
    for ln in im:
        # Filter out [0., 0., 0.] elements
        h_cols = {
            str(elt) : elt
            for elt in ln if elt.any()
        }
        # Raise an exception if we have more than 1 color in one line
        assert len(h_cols) < 2
        cols.append(h_cols.values()[0] if h_cols else numpy.array([0., 0., 0.]))

    # Find best palette match for each color
    vcs_cols = [best_palette_match(c) for c in cols]
    print json.dumps([{
        "name": "pix_pfcol",
        "data": vcs_cols
    }])


if __name__ == "__main__":
    main()
