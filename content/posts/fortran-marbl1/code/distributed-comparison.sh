#!/bin/bash
set -e
set -x

make distributedComparison.exe

outfile=distributedComparison.csv

echo "Version,N,Time (s)" > $outfile

for n in 100 200 400 800 1000; do
  #Sequential run
  ./distributedComparison.exe --numLocales=1 --dataParTasksPerLocale=1 --n=$n >> $outfile
  #Threaded run
  ./distributedComparison.exe --numLocales=1 --dataParTasksPerLocale=16 --n=$n >> $outfile
  #Distributed runs
  for l in 2 4 8; do
    ./distributedComparison.exe --numLocales=$l --dataParTasksPerLocale=16 --n=$n >> $outfile
  done
done

python3 distributedComparison.py $outfile