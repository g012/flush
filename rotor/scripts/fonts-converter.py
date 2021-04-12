import sys

class Character(object):
    def __init__(self):
        self.data = [0]*8*8

    def set(self, x, y, val):
        self.data[8*y+x] = val

    def get(self, x, y):
        return self.data[8*y+x]

    def mirror_h(self):
        for y in xrange(8):
            for x in xrange(4):
                tmp = self.get(x, y)
                self.set(x, y, self.get(7-x, y))
                self.set(7-x, y, tmp)

    def rotate_l(self):
        for y in xrange(4):
            for x in xrange(4):
                tmp = self.get(x,y)
                self.set(x, y, self.get(7-y, x))
                self.set(7-y, x, self.get(7-x, 7-y))
                self.set(7-x, 7-y, self.get(y, 7-x))
                self.set(y, 7-x, tmp)
        
    def dump(self):
        for y in xrange(8):
            s = ""
            for x in xrange(8):
                s += "{}".format(self.get(x, y))
            print "    dc.b %{}".format(s)


        
fname = sys.argv[1]
with open(fname) as fd:

    fonts = {}
    
    data = fd.read()

    line_len = len(data) / 8  # 8 lines per character
    for j in xrange(0, len(data), 2):
        line = j / line_len
        col  = ((j % line_len) / 2)+1
        char = col / 16  # 8 bits char, 8 bits empty
        pix  = col % 16

        if pix < 8:
            if char not in fonts:
                fonts[char] = Character()
            d = 1 if ord(data[j+1]) else 0
            fonts[char].set(pix, line, d )

    for val in fonts.values():
        val.mirror_h()
        val.rotate_l()
        val.dump()
        print ""
            

