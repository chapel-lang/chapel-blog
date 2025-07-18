#!/bin/bash
set -x
set -e

make sequentialTimed.exe
make threadedTimed.exe

outfile="timing.csv"
echo "Version,N,Time (s)" > $outfile
for n in 100 200 400 800 1600 3200 6400 12800 25600; do
  ./sequentialTimed.exe --n=$n >> $outfile
  ./threadedTimed.exe --dataParTasksPerLocale=8 --n=$n >> $outfile
done

python3 compare-times.py $outfile