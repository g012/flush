#!/usr/bin/env python

import sys

r = {}
for l in sys.stdin.read():
    if l.isupper() or l.isdigit():
        #if l == '0': # We will replace '0' by 'O'
        #    continue
        if l not in r:
            r[l] = 0
        r[l]+= 1

print("# charaters: {}\n".format(len(r)))
couples = r.items()
couples.sort(key=lambda x:x[1], reverse=True)

print("Occurences:")
for letter,count in couples:
    flag = '*' if letter.isdigit() else ' '
    print("{}: {} {}".format(letter, count, flag))
print("")

print("Non occurences:")
# Numbers and Upper case characters
c = map(lambda x:chr(x+48), range(10)) \
  + map(lambda x:chr(x+65), range(26))
print filter(lambda x:x not in r, c)
