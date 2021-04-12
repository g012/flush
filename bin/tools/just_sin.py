from math import *
import sys

PERIOD = 128

def main():
    top = int(sys.argv[1])

    def f(x):
        return (sin(x*2*pi/PERIOD)+1)/2 * top

    d = [min(f(x),top-1) for x in range(PERIOD)]

    print("const unsigned char rotation[] = {")
    print(", ".join([str(int(floor(i))) for i in d]))
    print("};")


main()
