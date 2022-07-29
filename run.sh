#!/bin/bash

if [ $1 = "-b" ]; then
    bash build.sh -e cpu_axi_diff -b -r "-i non-output/cpu-tests" -m "EMU_TRACE=1 WITH_DRAMSIM3=1"                   
else
    bash build.sh -e cpu_axi_diff -b -d -s -a "-i non-output/cpu-tests/$1-cpu-tests.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w
fi

#use batch model: bash run.sh -b
#use particular model: bash run.sh add 
