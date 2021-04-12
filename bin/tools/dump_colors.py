#!/usr/bin/env python
import sys

import matplotlib.image
import numpy

def main():
    fname = sys.argv[1]
    im = matplotlib.image.imread(fname)

    for l in im:
        for e in l:
            if not numpy.array_equal(e, numpy.array([0., 0., 0.], dtype=numpy.float32)):
                print(e)
                break

main()
