#!/usr/bin/env python
import sys

import matplotlib.image
import numpy
import json

def list2int(l):
    n = 0
    while l:
        n <<= 1
        n += l.pop(0)
    return n


def main():
    fname = sys.argv[1]
    im = matplotlib.image.imread(fname)

    data = [0]
    for raw in im:
        ln = [1 if c[:3].any() else 0 for c in raw]
        data.append(list2int(ln))

    data.reverse()
    result = [{
        "data": data,
        "name": "sprite"
    }]
    print json.dumps(result)


main()
