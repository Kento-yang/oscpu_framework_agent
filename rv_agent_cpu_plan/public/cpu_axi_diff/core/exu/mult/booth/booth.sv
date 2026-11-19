// ============================================================================
// Module: booth
// Role: Booth 编码器。把乘数按 3 bit 一组编码，输出部分积与进位。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
module booth #(parameter WIDTH=32) (
  input [WIDTH-1:0] x,
  input [2:0] s,
  output wire [WIDTH:0] p,
  output wire c
);

  // TODO(agent): implement booth here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
