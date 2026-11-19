// ============================================================================
// Module: wbu
// Role: 写回与提交单元。选择写回数据，产生提交信号与 difftest 提交包。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
module wbu (
  // 1. signal to pipe shake hands:
  input   logic                   i_clk         ,
  input   logic                   i_rst_n       ,
  input  logic                    i_flush       ,
  input   logic                   i_pre_valid   ,   // from pre-stage
  output  logic                   o_pre_ready   ,   //  to  pre-stage
  output  logic                   o_post_valid  ,   //  to  post-stage
  input   logic                   i_post_ready  ,   // from post-stage
  
  // 2. input comb signal from pre stage:
  input   logic [`CPU_WIDTH-1:0]  i_lsu_exres   ,
  input   logic [`CPU_WIDTH-1:0]  i_lsu_lsres   ,
  input   logic                   i_lsu_lden    ,
  input   logic [`REG_ADDRW-1:0]  i_lsu_rdid    ,
  input   logic                   i_lsu_rdwen   ,
  input   logic [`CSR_ADDRW-1:0]  i_lsu_csrdid  ,
  input   logic                   i_lsu_csrdwen ,
  input   logic [`CPU_WIDTH-1:0]  i_lsu_csrd    ,
  input   logic [`CPU_WIDTH-1:0]  i_lsu_pc      ,
  input  logic                    i_lsu_ecall   ,
  input  logic                    i_lsu_mret    ,
  input   logic                   i_lsu_nop     ,
  input   logic                   i_iru_intr    ,

  input   logic [`INS_WIDTH-1:0]  s_lsu_ins     ,
  input   logic                   s_lsu_lsclint ,

  // 3. output comb signal to post stage:
  output  logic [`REG_ADDRW-1:0]  o_wbu_rdid    ,
  output  logic                   o_wbu_rdwen   ,
  output  logic [`CPU_WIDTH-1:0]  o_wbu_rd      ,

  output  logic [`CSR_ADDRW-1:0]  o_wbu_csrdid  ,
  output  logic                   o_wbu_csrdwen ,
  output  logic [`CPU_WIDTH-1:0]  o_wbu_csrd    ,
  
  output  logic                   o_wbu_commit  ,
  output  logic [`CPU_WIDTH-1:0]  o_wbu_pc      ,
  output logic                    o_wbu_ecall   ,
  output logic                    o_wbu_mret    ,
  output  logic                   o_wbu_nop     ,

  // 4 for sim:
  output  logic [`INS_WIDTH-1:0]  s_wbu_ins     ,
  output  logic                   s_wbu_lsclint
);

  // TODO(agent): implement wbu here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
