// ============================================================================
// Module: iCache
// Role: 指令 Cache。4 路组相联、128 组、16 字节 cacheline；实现 tag/data array、命中判断、缺失填充，向上提供 32-bit 读接口。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module iCache (
  input                       i_clk     ,
  input                       i_rst_n   ,
  input                       i_invalid ,
  uni_if.Slave                iCacheIf_S,  //  32 bit width
  uni_if.Master               iMemIf_M     // 128 bit width
);

  // TODO(agent): implement iCache here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
