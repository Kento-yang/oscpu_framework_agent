// ============================================================================
// Module: data_ary
// Role: Cache 数据数组。两个 128x64 的 SRAM 拼接为 128 深度、128-bit 宽，支持 16 字节写掩码。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
module data_ary(
  input               i_clk  ,
  input               i_rst_n,
  input               i_ren  ,
  input               i_wen  ,
  input       [ 15:0] i_wstrb,
  input       [  6:0] i_addr , // 7 bit, 128 depth.
  input       [127:0] i_wdata,
  output      [127:0] o_rdata
);

  // TODO(agent): implement data_ary here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
