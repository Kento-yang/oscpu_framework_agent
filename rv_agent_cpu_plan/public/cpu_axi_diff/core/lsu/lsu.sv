// ============================================================================
// Module: lsu
// Role: 访存单元。通过 dCacheIf_M 完成 load/store，处理 CLINT MMIO、fence.i 以及异常/中断引起的清空。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
module lsu (
  input  logic                    i_clk         ,
  input  logic                    i_rst_n       ,
  input  logic                    i_flush       ,

  // 1. axi interface to get data from mem:
  uni_if.Master                   dCacheIf_M    ,

  // 2. signal to pipe shake hands:
  input  logic                    i_pre_valid   ,   // from pre-stage
  output logic                    o_pre_ready   ,   //  to  pre-stage
  output logic                    o_post_valid  ,   //  to  post-stage
  input  logic                    i_post_ready  ,   // from post-stage

  // 3. input comb signal from pre stage:
  input  logic  [`CPU_WIDTH-1:0]  i_exu_exres   ,
  input  logic  [`CPU_WIDTH-1:0]  i_exu_rs2     ,
  input  logic  [2:0]             i_exu_lsfunc3 ,
  input  logic                    i_exu_lden    ,
  input  logic                    i_exu_sten    ,
  input  logic                    i_exu_fencei  ,
  input  logic  [`REG_ADDRW-1:0]  i_exu_rdid    ,
  input  logic                    i_exu_rdwen   ,
  input  logic  [`CSR_ADDRW-1:0]  i_exu_csrdid  ,
  input  logic                    i_exu_csrdwen , // csr dest write enable.
  input  logic  [`CPU_WIDTH-1:0]  i_exu_csrd    ,
  input  logic  [`CPU_WIDTH-1:0]  i_exu_pc      ,
  input  logic                    i_exu_ecall   ,
  input  logic                    i_exu_mret    ,
  input  logic                    i_exu_nop     ,
  input  logic  [`INS_WIDTH-1:0]  s_exu_ins     ,

  // 4. iru signals:
  input  logic                    i_iru_excp    ,
  input  logic                    i_iru_intr    ,

  // 4. clint signals:
  output  logic                   o_clint_ren   ,
  output  logic [`ADR_WIDTH-1:0]  o_clint_raddr ,
  input   logic [`CPU_WIDTH-1:0]  i_clint_rdata ,
  output  logic                   o_clint_wen   ,
  output  logic [`ADR_WIDTH-1:0]  o_clint_waddr ,
  output  logic [`CPU_WIDTH-1:0]  o_clint_wdata ,

  // 5. output comb signal to post stage:
  output logic  [`CPU_WIDTH-1:0]  o_lsu_lsres   ,
  output logic  [`CPU_WIDTH-1:0]  o_lsu_exres   ,
  output logic                    o_lsu_lden    ,
  output logic                    o_lsu_fencei  ,
  output logic  [`REG_ADDRW-1:0]  o_lsu_rdid    ,
  output logic                    o_lsu_rdwen   ,
  output logic  [`CSR_ADDRW-1:0]  o_lsu_csrdid  ,
  output logic                    o_lsu_csrdwen , // csr dest write enable.
  output logic  [`CPU_WIDTH-1:0]  o_lsu_csrd    ,
  output logic  [`CPU_WIDTH-1:0]  o_lsu_pc      ,
  output logic                    o_lsu_ecall   ,
  output logic                    o_lsu_mret    ,
  output logic                    o_lsu_nop     ,

  // 6. for sim:
  output logic  [`INS_WIDTH-1:0]  s_lsu_ins     ,
  output logic                    s_lsu_lsclint
);

  // TODO(agent): implement lsu here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
