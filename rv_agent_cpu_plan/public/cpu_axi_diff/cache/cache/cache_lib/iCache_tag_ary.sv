// ============================================================================
// Module: iCache_tag_ary
// Role: iCache tag 数组。128 深度，存放 tag/valid，支持 invalid 清空。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
module iCache_tag_ary#(
  DATA_WIDTH = 64
)(
  input                         i_clk     ,
  input                         i_rst_n   ,
  input                         i_invalid ,
  input                         i_wen     ,
  input       [  6:0]           i_addr    , // 7 bit, 128 depth.
  input       [DATA_WIDTH-1:0]  i_din     ,
  output      [DATA_WIDTH-1:0]  o_dout
);

  // TODO(agent): implement iCache_tag_ary here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
