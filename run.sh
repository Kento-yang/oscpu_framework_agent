#!/bin/bash

#if [ $2 = "clean" ]; then
#    rm -rf /home/dingyawei/oscpu-framework/projects/cpu_axi_diff/build
#fi

if [ $1 = "fencei" ]; then
    #bash build.sh -e cpu_axi_diff -d -s -a "-i non-output/cpu-tests-fencei/matrix-mulw-riscv64-npc.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
    bash build.sh -e cpu_axi_diff -b -r "non-output/cpu-tests-fencei" -m "WITH_DRAMSIM3=1"
elif [ $1 = "-b" ]; then
    bash build.sh -e cpu_axi_diff -b -r "non-output/riscv-tests non-output/cpu-tests-ysyx4 non-output/cpu-tests-fencei" -m "WITH_DRAMSIM3=1"
elif [ $1 = "hello" ]; then
    bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/hello/amtest-hello.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -b  #-w for open vcd
elif [ $1 = "time" ]; then
    #bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/time-test/amtest-time-test.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
    bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/time-test/amtest-time-test.bin -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
elif [ $1 = "yield" ]; then
    #bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/yield-test/amtest-yield-test.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
    bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/yield-test/amtest-yield-test.bin -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
elif [ $1 = "interrupt" ]; then
    #bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/interrupt-test/amtest-interrupt-test.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
    bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/interrupt-test/amtest-interrupt-test.bin -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -b
elif [ $1 = "rt-thread" ]; then
    bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/rt-thread/rtthread.bin" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
    #bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/rt-thread/rtthread --dump-wave -b 1210000" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
elif [ $1 = "coremark" ]; then
    bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/benchmark/coremark/coremark.bin" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -b
elif [ $1 = "dhrystone" ]; then
    bash build.sh -e cpu_axi_diff -d -s -a "-i non-output/dhrystone/dhrystone.bin" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -b
elif [ $1 = "clean" ]; then
    rm -rf /home/dingyawei/oscpu-framework/projects/cpu_axi_diff/build
else
    #bash build.sh -e cpu_axi_diff -d -s -a "-i non-output/cpu-tests/$1-cpu-tests.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
    bash build.sh -e cpu_axi_diff -d -s -a "-i non-output/riscv-tests/$1-riscv-tests.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
    #bash build.sh -e cpu_axi_diff -d -s -a "-i non-output/cpu-tests-ysyx4/$1-cpu-tests.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -w -b
fi

#use batch model: bash run.sh -b
#use particular model: bash run.sh add 
