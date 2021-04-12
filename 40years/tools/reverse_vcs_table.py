#!/usr/bin/env python
import sys

# Example of table to reverse
#    dc.b $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $FF, $FF
#    dc.b $FF, $FF, $FF, $FF, $FF, $00, $00, $00

def parse(fd):
    data = []
    l = fd.readline()
    while l:
        toks = l.strip().split()
        assert toks[0].lower() == "dc.b"
        data.extend([d.strip().upper() for d in " ".join(toks[1:]).split(",")])
        l = fd.readline()
    return data

def dump(fd, data, n=16):
    for i in xrange(0, len(data), n):
        chunk = data[i:i+n]
        fd.write("    dc.b {}\n".format(", ".join(chunk)))

def main():
    data = parse(sys.stdin)
    data.reverse()
    print "**********"
    dump(sys.stdout, data, 8)

main()
