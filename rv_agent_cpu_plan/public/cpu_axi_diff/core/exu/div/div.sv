// ============================================================================
// Module: div
// Role: 多周期有符号/无符号除法器。i_start 启动，o_busy / o_end_valid 握手，输出商与余数；支持 32/64 位。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
module div#(
  parameter WIDTH = 64
)(
  input                     i_clk         ,
  input                     i_rst_n       ,
  input                     i_flush       ,
  input                     i_divw        ,
  input                     i_start       ,
  output                    o_busy        ,
  output logic              o_end_valid   ,
  input                     i_end_ready   ,
  input                     i_signed      ,
  input  logic [WIDTH-1:0]  i_dividend    ,
  input  logic [WIDTH-1:0]  i_divisor     ,
  output logic [WIDTH-1:0]  o_quotient    ,
  output logic [WIDTH-1:0]  o_remainder
);

  // TODO(agent): implement div here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
