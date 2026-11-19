// ============================================================================
// Module: csrfile
// Role: CSR 寄存器堆。实现 Zicsr 读写与 mstatus/mie/mip/mtvec/mepc/mcause/mcycle 等 CSR，输出 difftest 影子 CSR。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module csrfile (
  input logic                   i_clk   ,
  input logic                   i_rst_n ,

  // from idu, for csrrw/csrrs/csrrc:
  input  logic                  i_ren   , 
  input  logic [`CSR_ADDRW-1:0] i_raddr ,
  output logic [`CPU_WIDTH-1:0] o_rdata ,

  // from wbu, for csrrw/csrrs/csrrc:
  input  logic                  i_wen   ,
  input  logic [`CSR_ADDRW-1:0] i_waddr ,
  input  logic [`CPU_WIDTH-1:0] i_wdata ,

  // connect excp/intr:
  input  logic                  i_mepc_wen      ,   // ecall / iru.
  input  logic [`CPU_WIDTH-1:0] i_mepc_wdata    ,   // ecall / iru.
  input  logic                  i_mcause_wen    ,   // ecall / iru.
  input  logic [`CPU_WIDTH-1:0] i_mcause_wdata  ,   // ecall / iru.
  input  logic                  i_mstatus_wen   ,   // ecall / iru.
  input  logic [`CPU_WIDTH-1:0] i_mstatus_wdata ,   // ecall / iru.
  output logic [`CPU_WIDTH-1:0] o_mtvec         ,   // ecall / iru.
  output logic [`CPU_WIDTH-1:0] o_mstatus       ,   // ecall / iru.
  output logic [`CPU_WIDTH-1:0] o_mepc          ,   // mret.
  output logic [`CPU_WIDTH-1:0] o_mip           ,
  output logic [`CPU_WIDTH-1:0] o_mie           ,

  // connect clint:
  input  logic                  i_clint_mtip    ,

  // for difftest:
  output logic [`CPU_WIDTH-1:0] s_mtvec         ,
  output logic [`CPU_WIDTH-1:0] s_mepc          ,
  output logic [`CPU_WIDTH-1:0] s_mstatus       ,
  output logic [`CPU_WIDTH-1:0] s_mcause        ,
  output logic [`CPU_WIDTH-1:0] s_mcycle        ,
  output logic [`CPU_WIDTH-1:0] s_mie           ,
  output logic [`CPU_WIDTH-1:0] s_mip           ,
  output logic [`CPU_WIDTH-1:0] s_mscratch      ,
  output logic [`CPU_WIDTH-1:0] s_sstatus
);

  // TODO(agent): implement csrfile here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
