#!/usr/bin/python
# Preprocess stdin, executing shebang/EOF wrapped scripts and putting their output on stdout too
# The purpose of this is to simplify generating tables, since it would enable putting table generation code inside .asm files, like:
#
# $ cat bitmasktab.asm:
# Bitmask
# #!/usr/bin/python
# for x in range(0,8):
#     print ' .byte', 1<<x
# EOF
import sys
import subprocess

scriptmode = False

for line in sys.stdin.readlines():
    if line[0:2] == '#!':
        scriptmode = True
        interpreter = line[2:-1]
        file = open('build/tempscript', 'w')
        file.write(line)
    elif scriptmode and line == 'EOF\n':
        scriptmode = False
        file.close()
        sys.stdout.write(subprocess.check_output([interpreter, 'build/tempscript']))
    elif scriptmode:
        file.write(line)
    else:
        sys.stdout.write(line)
