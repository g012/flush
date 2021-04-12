#!/usr/bin/env python3
import json
import sys

def main():
    data = json.load(sys.stdin)

    for t in data:
        print("{}:".format(t['name']))
        tmp = None
        for i,d in enumerate(t['data']):
            if i%8 == 0:
                if tmp:
                    print("    dc.b {}".format(", ".join(["${:02x}".format(i) for i in tmp])))
                tmp = []
            tmp.append(d)
        if tmp:
            print("    dc.b {}".format(", ".join(["${:02x}".format(i) for i in tmp])))

main()
