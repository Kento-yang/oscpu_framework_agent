#!/bin/bash

if [ $1 = "-b" ]; then
    #bash build.sh -e cpu_axi_diff -b -r "non-output/cpu-tests non-output/riscv-tests" -m "WITH_DRAMSIM3=1"
    bash build.sh -e cpu_axi_diff -b -r "non-output/riscv-tests" -m "WITH_DRAMSIM3=1"z
else
    bash build.sh -e cpu_axi_diff -d -s -a "-i non-output/cpu-tests/$1-cpu-tests.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
fi

#use batch model: bash run.sh -b
#use particular model: bash run.sh add 
