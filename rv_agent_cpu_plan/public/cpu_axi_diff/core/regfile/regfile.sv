// ============================================================================
// Module: regfile
// Role: 通用寄存器堆。32 个 64 位寄存器，双读单写，并向 difftest 输出全部寄存器。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module regfile (
  input                         i_clk   ,
  input                         i_rst_n ,

  // from wbu:
  input                         i_wen   ,
  input        [`REG_ADDRW-1:0] i_waddr ,
  input        [`CPU_WIDTH-1:0] i_wdata ,

  // from idu:
  input        [`REG_ADDRW-1:0] i_raddr1,
  input        [`REG_ADDRW-1:0] i_raddr2,
  output logic [`CPU_WIDTH-1:0] o_rdata1,
  output logic [`CPU_WIDTH-1:0] o_rdata2,
  
  // difftest sim signals:
  output       [`CPU_WIDTH-1:0] s_regs [`REG_COUNT-1:0]
);

  // TODO(agent): implement regfile here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
