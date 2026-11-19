// ============================================================================
// Module: core_top
// Role: CPU 核顶层。连接 IFU/IDU/EXU/LSU/WBU 五级流水线，以及 REGFILE/BYPASS/CSR/CLINT/IRU/BRU；对外提供 iCache/dCache 的 uni_if Master 端口、cache 维护信号和 UART/difftest 观察信号。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module core_top(
  input                 i_clk         ,
  input                 i_rst_n       ,
  uni_if.Master         iCacheIf_M    ,
  uni_if.Master         dCacheIf_M    ,
  output                o_invalidIChe ,
  output                o_cleanDChe   ,
  output                s_uart_out_valid,
  output [7:0]          s_uart_out_char
);

  // TODO(agent): implement core_top here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
