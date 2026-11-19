// ============================================================================
// Module: clint
// Role: CLINT 定时器。实现 mtime/mtimecmp 的 MMIO 读写并产生 MTIP 中断。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module clint (
  input logic                   i_clk         ,
  input logic                   i_rst_n       ,

  // from cpu lsu:
  input  logic                  i_clint_ren   ,
  input  logic [`ADR_WIDTH-1:0] i_clint_raddr ,
  output logic [`CPU_WIDTH-1:0] o_clint_rdata ,
  input  logic                  i_clint_wen   ,
  input  logic [`ADR_WIDTH-1:0] i_clint_waddr ,
  input  logic [`CPU_WIDTH-1:0] i_clint_wdata ,
  
  // to csr_file:
  output logic                  o_clint_mtip
);

  // TODO(agent): implement clint here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
