// ============================================================================
// Module: csa_nbit
// Role: N 位进位保留加法器（carry-save adder），三输入两输出。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
module csa_nbit#(
  parameter N = 64
)(
  input  [N-1:0] i_a, 
  input  [N-1:0] i_b, 
  input  [N-1:0] i_c, 
  output [N-1:0] o_s, 
  output [N-1:0] o_c
);

  // TODO(agent): implement csa_nbit here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
