// Public-smoke stand-ins for the XiangShan difftest DPI modules.
//
// The real definitions live in
//   libraries/difftest/src/test/vsrc/common/difftest.v
// and call DPI-C functions that only exist in the framework's C++ harness.
// The public AXI testbenches do not need NEMU, so they compile this file
// instead.  Do NOT compile this file together with difftest.v: the module
// names would collide.
//
// The package below is only a small scoreboard for the public smoke tests.

`timescale 1ns/1ps

package public_difftest_pkg;
  int unsigned commit_count;
  int unsigned trap_count;
  int unsigned good_trap_count;
  int unsigned bad_trap_count;

  // When set, every commit is checked against the 64-ADDI smoke program:
  //   pc    = addi_base + 4*index
  //   rd    = (index % 31) + 1
  //   wdata = index + 1
  bit          check_addi64;
  logic [63:0] addi_base;

  bit          trace_en;

  logic [63:0] last_pc;
  logic [63:0] last_wdata;
  logic [31:0] last_instr;
  logic [7:0]  last_rd;
  logic        last_wen;

  logic [7:0]  last_trap_code;
  logic [63:0] last_trap_pc;
  int unsigned last_trap_cycle;
  int unsigned last_trap_instr;
endpackage

module DifftestInstrCommit(
  input        clock,
  input [ 7:0] coreid,
  input [ 7:0] index,
  input        valid,
  input [63:0] pc,
  input [31:0] instr,
  input        skip,
  input        isRVC,
  input        scFailed,
  input        wen,
  input [ 7:0] wdest,
  input [63:0] wdata
);
  import public_difftest_pkg::*;

  always @(posedge clock) begin
    if (valid) begin
      if (check_addi64 && commit_count < 64) begin
        if (pc !== (addi_base + (commit_count << 2)))
          $fatal(1, "PUBLIC_SMOKE commit %0d: pc=%h expected=%h",
                 commit_count, pc, addi_base + (commit_count << 2));
        if (wdest !== ((commit_count % 31) + 1))
          $fatal(1, "PUBLIC_SMOKE commit %0d: rd=%0d expected=%0d",
                 commit_count, wdest, (commit_count % 31) + 1);
        if (wdata !== (commit_count + 1))
          $fatal(1, "PUBLIC_SMOKE commit %0d: wdata=%h expected=%h",
                 commit_count, wdata, commit_count + 1);
        if (!wen)
          $fatal(1, "PUBLIC_SMOKE commit %0d: ADDI did not write a register",
                 commit_count);
      end

      commit_count = commit_count + 1;
      last_pc      = pc;
      last_instr   = instr;
      last_rd      = wdest;
      last_wdata   = wdata;
      last_wen     = wen;

      if (trace_en)
        $display("COMMIT index=%0d pc=%h insn=%h rd=%0d wen=%0d wdata=%h skip=%0d",
                 commit_count - 1, pc, instr, wdest, wen, wdata, skip);
    end
  end
endmodule

module DifftestTrapEvent(
  input        clock,
  input [ 7:0] coreid,
  input        valid,
  input [ 7:0] code,
  input [63:0] pc,
  input [63:0] cycleCnt,
  input [63:0] instrCnt
);
  import public_difftest_pkg::*;

  always @(posedge clock) begin
    if (valid) begin
      trap_count = trap_count + 1;
      if (code == 0)
        good_trap_count = good_trap_count + 1;
      else
        bad_trap_count = bad_trap_count + 1;

      last_trap_code  = code;
      last_trap_pc    = pc;
      last_trap_cycle = cycleCnt[31:0];
      last_trap_instr = instrCnt[31:0];

      if (trace_en)
        $display("TRAP code=%0d pc=%h cycle=%0d instr=%0d",
                 code, pc, cycleCnt, instrCnt);
    end
  end
endmodule

module DifftestArchEvent(
  input        clock,
  input [ 7:0] coreid,
  input [31:0] intrNO,
  input [31:0] cause,
  input [63:0] exceptionPC,
  input [31:0] exceptionInst
);
  // No scoreboard action needed for the public smoke tests.
endmodule

module DifftestCSRState(
  input        clock,
  input [ 7:0] coreid,
  input [ 1:0] priviledgeMode,
  input [63:0] mstatus,
  input [63:0] sstatus,
  input [63:0] mepc,
  input [63:0] sepc,
  input [63:0] mtval,
  input [63:0] stval,
  input [63:0] mtvec,
  input [63:0] stvec,
  input [63:0] mcause,
  input [63:0] scause,
  input [63:0] satp,
  input [63:0] mip,
  input [63:0] mie,
  input [63:0] mscratch,
  input [63:0] sscratch,
  input [63:0] mideleg,
  input [63:0] medeleg
);
  // No scoreboard action needed for the public smoke tests.
endmodule

module DifftestArchIntRegState(
  input        clock,
  input [ 7:0] coreid,
  input [63:0] gpr_0,
  input [63:0] gpr_1,
  input [63:0] gpr_2,
  input [63:0] gpr_3,
  input [63:0] gpr_4,
  input [63:0] gpr_5,
  input [63:0] gpr_6,
  input [63:0] gpr_7,
  input [63:0] gpr_8,
  input [63:0] gpr_9,
  input [63:0] gpr_10,
  input [63:0] gpr_11,
  input [63:0] gpr_12,
  input [63:0] gpr_13,
  input [63:0] gpr_14,
  input [63:0] gpr_15,
  input [63:0] gpr_16,
  input [63:0] gpr_17,
  input [63:0] gpr_18,
  input [63:0] gpr_19,
  input [63:0] gpr_20,
  input [63:0] gpr_21,
  input [63:0] gpr_22,
  input [63:0] gpr_23,
  input [63:0] gpr_24,
  input [63:0] gpr_25,
  input [63:0] gpr_26,
  input [63:0] gpr_27,
  input [63:0] gpr_28,
  input [63:0] gpr_29,
  input [63:0] gpr_30,
  input [63:0] gpr_31
);
  // No scoreboard action needed for the public smoke tests.
endmodule

module DifftestArchFpRegState(
  input        clock,
  input [ 7:0] coreid,
  input [63:0] fpr_0,
  input [63:0] fpr_1,
  input [63:0] fpr_2,
  input [63:0] fpr_3,
  input [63:0] fpr_4,
  input [63:0] fpr_5,
  input [63:0] fpr_6,
  input [63:0] fpr_7,
  input [63:0] fpr_8,
  input [63:0] fpr_9,
  input [63:0] fpr_10,
  input [63:0] fpr_11,
  input [63:0] fpr_12,
  input [63:0] fpr_13,
  input [63:0] fpr_14,
  input [63:0] fpr_15,
  input [63:0] fpr_16,
  input [63:0] fpr_17,
  input [63:0] fpr_18,
  input [63:0] fpr_19,
  input [63:0] fpr_20,
  input [63:0] fpr_21,
  input [63:0] fpr_22,
  input [63:0] fpr_23,
  input [63:0] fpr_24,
  input [63:0] fpr_25,
  input [63:0] fpr_26,
  input [63:0] fpr_27,
  input [63:0] fpr_28,
  input [63:0] fpr_29,
  input [63:0] fpr_30,
  input [63:0] fpr_31
);
  // No floating point in RVA-01.
endmodule
