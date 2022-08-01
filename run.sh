#!/bin/bash

#rm -rf /home/dingyawei/oscpu-framework/projects/cpu_axi_diff/build
if [ $1 = "-b" ]; then
    bash build.sh -e cpu_axi_diff -b -r "non-output/riscv-tests non-output/cpu-tests" -m "WITH_DRAMSIM3=1"
elif [ $1 = "hello" ]; then
    bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/hello/amtest-hello.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
elif [ $1 = "time" ]; then
    bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/time-test/amtest-time-test.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
elif [ $1 = "yield" ]; then
    bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/yield-test/amtest-yield-test.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
else
    bash build.sh -e cpu_axi_diff -d -s -a "-i non-output/cpu-tests/$1-cpu-tests.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
fi

#use batch model: bash run.sh -b
#use particular model: bash run.sh add 
