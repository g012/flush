import math

X_RES = 160 # X resolution
Y_RES = 248 # Y resolution
PT_SZ = 8   # Point size

# Table size X and Y
X_SIZ = 181 # Primes
Y_SIZ = 220

def generate_tables():
    # Adjusted resolutions
    xadj = X_RES - PT_SZ
    yadj = Y_RES - PT_SZ
    tcos = [int(xadj/2 * math.cos(2*math.pi*i / X_SIZ) + xadj/2) for i in range(X_SIZ)]
    tsin = [int(yadj/2 * math.sin(2*math.pi*i / Y_SIZ) + yadj/2) for i in range(Y_SIZ)]
    return tcos,tsin

def gnuplot():
    tcos, tsin = generate_tables();
    fn = 0
    def disp(xv, yv, fn):
        with open("f{}".format(fn), "w") as fd:
            for x,y in zip(xv, yv):
                fd.write("{}\t{}\n".format(x, y))
        fn+= 1

    xv = []
    yv = []
    for i in range(2):
        xv.append(tcos[i])
        yv.append(tsin[i])
    disp(xv, yv, fn)

    for i in range(2,4000):
        xv.append(tcos[i%len(tcos)])
        yv.append(tsin[i%len(tsin)])
        xv.pop(0)
        yv.pop(0)
        disp(xv, yv, fn)

    print("set xrange [0:160]")
    print("set yrange [0:248]")
    for i in range(4000):
        print("plot \"f{}\"".format(i))
        print("pause 0.04")

def print_tables():
    tcos, tsin = generate_tables()
    print("const unsigned char eyescos[] = {")
    print(", ".join([str(i) for i in tcos]))
    print("}")
    print("const unsigned char eyessin[] = {")
    print(", ".join([str(i) for i in tsin]))
    print("}")


if __name__ == "__main__":
    print_tables()
