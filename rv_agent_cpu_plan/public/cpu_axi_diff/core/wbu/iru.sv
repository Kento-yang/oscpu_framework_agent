// ============================================================================
// Module: iru
// Role: 异常/中断单元。处理 ecall/mret 与中断，生成流水清空、mepc/mcause/mstatus 更新和跳转 PC。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
module iru (
  // wbu:
  input   logic                   i_wbu_valid   ,
  input   logic                   i_wbu_ready   ,
  input   logic [`CPU_WIDTH-1:0]  i_wbu_pc      ,
  input   logic                   i_wbu_ecall   ,
  input   logic                   i_wbu_mret    ,
  input   logic                   i_wbu_nop     ,

  // for bru:
  output  logic                   o_iru_excp   ,
  output  logic                   o_iru_intr   ,
  output  logic [`CPU_WIDTH-1:0]  o_iru_pc     ,

  // csr_file:
  input   logic [`CPU_WIDTH-1:0]  i_mie          ,
  input   logic [`CPU_WIDTH-1:0]  i_mip          ,
  input   logic [`CPU_WIDTH-1:0]  i_mtvec        ,  // ecall.
  input   logic [`CPU_WIDTH-1:0]  i_mepc         ,  // mret.
  input   logic [`CPU_WIDTH-1:0]  i_mstatus      ,  // ecall.
  output  logic                   o_mepc_wen     ,  // ecall.
  output  logic [`CPU_WIDTH-1:0]  o_mepc_wdata   ,  // ecall.
  output  logic                   o_mcause_wen   ,  // ecall.
  output  logic [`CPU_WIDTH-1:0]  o_mcause_wdata ,  // ecall.
  output  logic                   o_mstatus_wen  ,  // ecall.
  output  logic [`CPU_WIDTH-1:0]  o_mstatus_wdata   // ecall.
);

  // TODO(agent): implement iru here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
