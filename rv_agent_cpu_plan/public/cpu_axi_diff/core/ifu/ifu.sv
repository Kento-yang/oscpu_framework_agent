// ============================================================================
// Module: ifu
// Role: 取指单元。维护 PC，通过 iCacheIf_M 取指，处理 flush 与分支重定向，输出取指 PC 和指令。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
module ifu (
  input                           i_clk       ,
  input                           i_rst_n     ,

  // 1. cache interface to get data from cache/ddr:
  uni_if.Master                   iCacheIf_M  ,

  // 2. signal to pipe shake hands:
  input                           i_flush     ,   //fence or ecxp/intr
  output                          o_post_valid,   //  to  post-stage
  input                           i_post_ready,   // from post-stage

  // 3. input signal from pre stage(bru give the next_pc):
  input         [`CPU_WIDTH-1:0]  i_next_pc   , 

  // 4. output signal to post stage:
  output logic  [`CPU_WIDTH-1:0]  o_ifu_pc    ,
  output logic  [`INS_WIDTH-1:0]  o_ifu_ins
);

  // TODO(agent): implement ifu here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
