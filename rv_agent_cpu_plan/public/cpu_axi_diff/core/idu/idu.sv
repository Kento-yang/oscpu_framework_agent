// ============================================================================
// Module: idu
// Role: 译码与流水控制单元。产生寄存器/CSR 读地址、执行控制、访存控制、写回控制、分支信息和流水握手。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
module idu (
  // 1. signal to pipe shake hands:
  input  logic                      i_clk         ,
  input  logic                      i_rst_n       ,
  input  logic                      i_flush       ,
  input  logic                      i_pre_nop     ,
  input  logic                      i_pre_stall   ,   // from data adventure
  input  logic                      i_pre_valid   ,   // from pre-stage
  output logic                      o_pre_ready   ,   //  to  pre-stage
  output logic                      o_post_valid  ,   //  to  post-stage
  input  logic                      i_post_ready  ,   // from post-stage

  // 2. input comb signal from pre stage:
  input  logic [`INS_WIDTH-1:0]     i_ifu_ins     ,
  input  logic [`CPU_WIDTH-1:0]     i_ifu_pc      ,

  // 3. output comb signal to post stage:

  // 3.1 for bypass to get reg value.
  output logic [`REG_ADDRW-1:0]     o_idu_rs1id   ,
  output logic [`REG_ADDRW-1:0]     o_idu_rs2id   ,
  output logic [`CSR_ADDRW-1:0]     o_idu_csrsid  ,
  output logic                      o_idu_csrsren , // csr source read enable.
  // 3.2 for exu:
  output logic                      o_idu_sysins  ,
  output logic [`CPU_WIDTH-1:0]     o_idu_imm     ,
  output logic [`EXU_SEL_WIDTH-1:0] o_idu_exsrc   ,
  output logic [`EXU_OPT_WIDTH-1:0] o_idu_exopt   ,
  output logic                      o_idu_excsrsrc,
  output logic [`CSR_OPT_WIDTH-1:0] o_idu_excsropt,
  // 3.3 for exu, dealy to use for lsu:
  output logic [2:0]                o_idu_lsfunc3 ,
  output logic                      o_idu_lden    ,
  output logic                      o_idu_sten    ,
  output logic                      o_idu_fencei  ,
  // 3.4 for exu, dealy to use for wbu:
  output logic [`REG_ADDRW-1:0]     o_idu_rdid    ,
  output logic                      o_idu_rdwen   ,
  output logic [`CSR_ADDRW-1:0]     o_idu_csrdid  ,
  output logic                      o_idu_csrdwen , // csr dest write enable.
  // 3.5 for bru:
  output logic                      o_idu_jal     ,
  output logic                      o_idu_jalr    ,
  output logic                      o_idu_brch    ,
  output logic [2:0]                o_idu_bfun3   ,
  // 3.6 for next stage to pipe:
  output logic [`CPU_WIDTH-1:0]     o_idu_pc      ,
  output logic                      o_idu_ecall   ,
  output logic                      o_idu_mret    ,
  output logic                      o_idu_nop     ,
  output logic [`INS_WIDTH-1:0]     s_idu_ins
);

  // TODO(agent): implement idu here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
