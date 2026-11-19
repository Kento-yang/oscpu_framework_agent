// ============================================================================
// Module: dCache_wrapper
// Role: dCache 包装器。按地址 bit31（或 i_clean）区分 cacheable 与 uncacheable/clean 通路；cacheable 走 dCache，否则直连 dMemIf_M。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module dCache_wrapper (
  input                       i_clk     ,
  input                       i_rst_n   ,
  input                       i_clean   ,
  uni_if.Slave                dCacheIf_S,  //  64 bit width
  uni_if.Master               dMemIf_M     // 128 bit width
);

  // TODO(agent): implement dCache_wrapper here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
