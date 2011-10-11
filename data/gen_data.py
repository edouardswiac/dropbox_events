## pseudo random data generator
import sys, string, os, time

## get the number of lines to generate, defaults to 50k
if len(sys.argv) == 2:
    lines = int(sys.argv[1])
else:
    lines = 50000

## filename is to be created in test/
fname = ('%s/gen_data.txt') % (os.path.dirname(__file__))
f = open(fname, "w")

## generates this alternance of events : add then delete
## a folder and the file inside
sample = [
    "ADD %(t1)d /test -",
    "ADD %(t1)d /test/1.txt f2fa762f",
    "DEL %(t2)d /test -",
    "DEL %(t2)d /test/1.txt f2fa762f"
]
sample = string.join(sample, '\n')
f.write(str(lines))

## counter & pseudo generated timestamp
i = 1
t1 = int(time.time())
t2 = t1 + 1
while i <= (lines / 4):
    f.write(('\n%s') % ( sample  % {"t1" : t1, "t2": t2}))
    t1 += 1
    t2 += 1
    i += 1

f.close()