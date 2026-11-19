// ============================================================================
// Module: exu
// Role: 执行单元。完成整数 ALU、移位、比较、乘除法与 CSR 操作数选择，向后续流水级输出结果与控制信息。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module exu (
  // 1. signal to pipe shake hands:
  input  logic                       i_clk         ,
  input  logic                       i_rst_n       ,
  input  logic                       i_flush       ,
  input  logic                       i_pre_nop     ,
  input  logic                       i_pre_valid   ,   // from pre-stage
  output logic                       o_pre_ready   ,   //  to  pre-stage
  output logic                       o_post_valid  ,   //  to  post-stage
  input  logic                       i_post_ready  ,   // from post-stage

  // 2. input comb signal from pre stage:
  input  logic                       i_idu_sysins  ,
  // 2.1 use in exu.
  input  logic  [`CPU_WIDTH-1:0]     i_idu_imm     ,
  input  logic  [`CPU_WIDTH-1:0]     i_idu_csrs    ,
  input  logic  [`CPU_WIDTH-1:0]     i_idu_rs1     ,
  input  logic  [`CPU_WIDTH-1:0]     i_idu_rs2     ,
  input  logic  [`EXU_SEL_WIDTH-1:0] i_idu_exsrc   ,
  input  logic  [`EXU_OPT_WIDTH-1:0] i_idu_exopt   ,
  input  logic                       i_idu_excsrsrc,
  input  logic  [`CSR_OPT_WIDTH-1:0] i_idu_excsropt,
  // 2.2 dealy for lsu:
  input  logic  [2:0]                i_idu_lsfunc3 ,
  input  logic                       i_idu_lden    ,
  input  logic                       i_idu_sten    ,
  input  logic                       i_idu_fencei  ,
  // 2.3 dealy for wbu:
  input  logic  [`REG_ADDRW-1:0]     i_idu_rdid    ,
  input  logic                       i_idu_rdwen   ,
  input  logic  [`CSR_ADDRW-1:0]     i_idu_csrdid  ,
  input  logic                       i_idu_csrdwen , // csr dest write enable.
  // 2.4 dealy for bru/wbu:
  input  logic  [`CPU_WIDTH-1:0]     i_idu_pc      ,
  input  logic                       i_idu_ecall   ,
  input  logic                       i_idu_mret    ,
  input  logic                       i_idu_nop     ,
  input  logic  [`INS_WIDTH-1:0]     s_idu_ins     ,

  // 3. output comb signal to post stage:
  // 3.1 for lsu: 
  output logic  [`CPU_WIDTH-1:0]     o_exu_rs2     ,
  output logic  [2:0]                o_exu_lsfunc3 ,
  output logic                       o_exu_lden    ,
  output logic                       o_exu_sten    ,
  output logic                       o_exu_fencei  ,
  // 3.2 for lsu, dealy to use for wbu:
  output logic  [`REG_ADDRW-1:0]     o_exu_rdid    ,
  output logic                       o_exu_rdwen   ,
  output logic  [`CPU_WIDTH-1:0]     o_exu_res     ,
  output logic  [`CSR_ADDRW-1:0]     o_exu_csrdid  ,
  output logic                       o_exu_csrdwen , // csr dest write enable.
  output logic  [`CPU_WIDTH-1:0]     o_exu_csrd    ,
  output logic  [`CPU_WIDTH-1:0]     o_exu_pc      ,
  output logic                       o_exu_ecall   ,
  output logic                       o_exu_mret    ,
  output logic                       o_exu_nop     ,
  output logic  [`INS_WIDTH-1:0]     s_exu_ins
);

  // TODO(agent): implement exu here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
