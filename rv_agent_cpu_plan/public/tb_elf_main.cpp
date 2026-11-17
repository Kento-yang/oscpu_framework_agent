// Verilator 4.204 C++ harness for public/tb_cpu_elf.sv.
// Drives clock/reset; the SV testbench performs all checks and calls $finish.

#include <cstdio>
#include "verilated.h"
#include "Vtb_rva01_elf.h"

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  Vtb_rva01_elf* dut = new Vtb_rva01_elf;
  dut->clock = 0;
  dut->reset = 1;

  // Hold reset for five cycles, then release.
  for (int i = 0; i < 5; ++i) {
    dut->clock = 0;
    dut->eval();
    dut->clock = 1;
    dut->eval();
  }
  dut->reset = 0;

  long cycles = 0;
  while (!Verilated::gotFinish() && cycles < 10000000L) {
    dut->clock = 0;
    dut->eval();
    dut->clock = 1;
    dut->eval();
    ++cycles;
  }

  if (!Verilated::gotFinish()) {
    std::printf("VERILATOR_TIMEOUT after %ld cycles\n", cycles);
    dut->final();
    delete dut;
    return 1;
  }

  dut->final();
  delete dut;
  return 0;
}
