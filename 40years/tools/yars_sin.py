#!/usr/bin/env python3

import json
import math

RESOLUTION = 64
MAXVAL = 32
OFFSET = 28

res = []
for i in range(RESOLUTION):
    x = 2*math.pi*i / RESOLUTION # sin
    x = 0.5*math.sin(x)+0.5      # normalized in [0 1]
    x = x*MAXVAL + OFFSET
    res.append(x)

data = [{
    "name": "yars_sin",
    "data": [min(MAXVAL+OFFSET-1, int(x)) for x in res]
}]

print(json.dumps(data))
