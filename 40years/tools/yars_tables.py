#!/usr/bin/env python3
import json
import math

DECIMAL_BITS = 6
LOG_BITS = 8

def opposite_8bits(n):
    return (n^0xff) + 1

class Multiplier:

    def __init__(self):
        self.expstep = 0.5**DECIMAL_BITS # Step (i.e min interval) in exponential (i.e normal) space
        self.logstep = math.log(self.expstep) / (2**(LOG_BITS-1) - 1) # Step in logarithm space
        self.__init_e2l_table()
        self.__init_l2e_table()

    def __init_e2l_table(self):
        self.e2l_table = [127]  # Dummy t[0] value cause log(0) is undefined
        for n in range(1, 2**DECIMAL_BITS + 1):
            fv = self.__exp_floatv(n)
            lv = math.log(fv)
            self.e2l_table.append(self.__log_intv(lv))

    def __init_l2e_table(self):
        self.l2e_table = []
        for n in range(0, 2**LOG_BITS - 1):
            lv = self.__log_floatv(n)
            fv = math.exp(lv)
            self.l2e_table.append(self.__exp_intv(fv))

    def __exp_floatv(self, n):
        if n & 0x80:
            n = -opposite_8bits(n)
        return n * self.expstep

    def __exp_intv(self, f):
        return round(f / self.expstep) & 0xff

    def __log_floatv(self, n):
        return n * self.logstep

    def __log_intv(self, f):
        return round(f / self.logstep)

    def __raw_multiply(self, a, b):
        la = self.e2l_table[a]
        lb = self.e2l_table[b]
        lr = la + lb
        return  self.l2e_table[lr]

    def __multiply(self, a, b):
        """
        Code that will run on the VCS.
        Given two 8 bits fixed point values, compute the product.
        """
        a &= 0xff # Have values on 8 bits
        b &= 0xff

        sign = a&0x80 ^ b&0x80
        if a&0x80:
            a = opposite_8bits(a)
        if b&0x80:
            b = opposite_8bits(b)
        if a == 0 or b == 0:
            return 0
        r = self.__raw_multiply(a, b)
        return opposite_8bits(r) if sign else r

    def __call__(self, x, y):
        a = self.__exp_intv(x)
        b = self.__exp_intv(y)
        c = self.__multiply(a, b)
        return self.__exp_floatv(c)

    def evaluate(self):
        space = range(1, 2**DECIMAL_BITS+1)
        errs = []
        for a in space:
            for b in space:
                r = self.__raw_multiply(a, b)
                x = self.__exp_floatv(a)
                y = self.__exp_floatv(b)
                errs.append(x*y - self.__exp_floatv(r))
        return errs

    def scale_table(self, res):
        space = range(2**8)
        tbl = []
        for a in space:
            a = (a+192)%(2**8)
            f = self.__exp_floatv(a)
            tbl.append(min(int(res * (f+1) / 2), res-1))
        return tbl[:129]

    def sin_table(self, res):
        t = []
        for i in range(res):
            f = 2*i*math.pi / res
            n = self.__exp_intv(math.sin(f))
            t.append(n)
        return t


def main():
    mul = Multiplier()
    print("Exp to Log Table")
    print(mul.e2l_table)
    print("\nLog to Exp Table")
    print(mul.l2e_table)

    errs = [abs(e) for e in mul.evaluate()]
    avg = sum(errs) / len(errs)
    worst = max(errs)
    # We target a 32x30 pixels area, for fixed point values in [-1, 1]
    # since the sign is handled 'manually', we can consider 4 independant 16*15 quadrants
    grid_precision = 1.0 / 16
    glitches = [x for x in errs if x >= grid_precision/2]
    print("")
    print("Average error: {:.4f}".format(avg))
    print("Worst error: {:.4f}".format(worst))
    print("Fixed point step: {:.4f}".format(mul.expstep))
    print("Grid precision: {:.4f}".format(grid_precision))
    print("Ratio of visible glitches: {:.4f}".format(float(len(glitches))/len(errs)))

    print("\nTesting edge cases (-1.0, -0.9, .., 0.0, .., 0.9, 1.0)")
    space = [x/10. for x in range(-10, 11)]
    errs = []
    for x in space:
        for y in space:
            errs.append(abs(x*y - mul(x,y)))
    avg = sum(errs) / len(errs)
    worst = max(errs)
    print("Average error: {:.4f}".format(avg))
    print("Worst error: {:.4f}".format(worst))

    # Building data structures to dump
    
    with open("yars_tables.json", "w") as fd:
        json.dump([
            {
                "name": "exp2log_table",
                "data": mul.e2l_table,
            },
            {
                "name": "log2exp_table",
                "data": mul.l2e_table,
            },
            {
                "name": "scalex_table",
                "data": mul.scale_table(32),
            },
            {
                "name": "scaley_table",
                "data": mul.scale_table(24),
            },
            {
                "name": "sin_table",
                "data": mul.sin_table(128),
            },
        ], fd)
main()
