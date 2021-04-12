#!/usr/bin/env python

from math import *

OUTSIDE = 0
LOGOTOP = 1
LBOTTOM = 2

LOGO_OFFSET = 3
LOGO_HEIGHT = 38
DISP_HEIGHT = 64

N_STEPS = 32

# Logo normalized dimensions:
logoA = {'x': 0., 'y': -1.}
logoB = {'x': 1., 'y': -1.}
logoC = {'x': 1., 'y': 1.}
logoD = {'x': 0., 'y': 1.}

def logo_rotation(t):
    """Rotation of angle t"""
    A,B,C,D = logoA,logoB,logoC,logoD
    RAy = sin(t)*A['x'] + cos(t)*A['y']
    RBy = sin(t)*B['x'] + cos(t)*B['y']
    RCy = sin(t)*C['x'] + cos(t)*C['y']
    RDy = sin(t)*D['x'] + cos(t)*D['y']
    return (RAy, RBy, RCy, RDy)


class RayTracer(object):

    def __init__(self, teta):
        RAy,RBy,RCy,RDy = logo_rotation(teta)
        self.__teta = teta
        self.__RAy = RAy
        self.__RBy = RBy
        self.__RCy = RCy
        self.__RDy = RDy


    def transformed_logo(self, yn):
        """Compute the coordinate relative to the logo referentiel.
        yn is the normalized coordinate projected on the rotated logo.
        """
        rv = (yn - sin(self.__teta)*logoB['x']) / cos(self.__teta)
        return rv


    def logo_pixel(self, yn):
        y = self.transformed_logo(yn)
        # Denormalize by mapping [-1, 1] -> {3, .., 41}
        y = -y # Texture (logo) goes 0 -> LOGO_HEIGHT: up -> down
        return min(int(floor((y+1.)/2 * LOGO_HEIGHT)),
                   LOGO_HEIGHT-1) + LOGO_OFFSET


    def ray_normalized(self, yn):
        """yn is a normalized y coordinate of the ray"""

        if (self.__RDy < self.__RCy): # Upwards rotation - ignoring RDy
            if yn > self.__RCy:
                return OUTSIDE
            if yn > self.__RBy:
                return self.logo_pixel(yn)
            if yn > self.__RAy:
                return LBOTTOM
            return OUTSIDE

        else: # Downward rotation - ignoring RAy
            if yn > self.__RDy:
                return OUTSIDE
            if yn > self.__RCy:
                return LOGOTOP
            if yn > self.__RBy:
                return self.logo_pixel(yn)
            return OUTSIDE


    def ray(self, y):
        """y is not normalized.
        y is between 0 and DISP_HEIGHT.
        yn should be between
        """
        r = float(DISP_HEIGHT) / LOGO_HEIGHT
        yn = ((float(y)/(DISP_HEIGHT-1))*2 - 1)*r
        return self.ray_normalized(yn)


def dump_data(d):
    res = ['$'+format(n, '02x') for n in d]
    s = ', '.join(res)
    print('.byte {}'.format(s))

def main():
    print('')
    print('transfo:')
    bg_shift = []
    for teta in [x/(N_STEPS-1.)*pi/2 - pi/4 for x in range(N_STEPS)]:
        rt = RayTracer(teta)
        rv = [rt.ray(y) for y in range(DISP_HEIGHT)]
        dump_data(reversed(rv))
        bg_shift.append(int(floor(sin(pi+teta)*LOGO_HEIGHT/4.)))

    print('')
    print("const char bg_shift[] = {")
    print(", ".join([str(i) for i in bg_shift]))
    print("};")

main()
