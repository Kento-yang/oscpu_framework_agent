// ============================================================================
// Module: bru
// Role: 分支处理单元。解析 jal/jalr/条件分支，计算下一 PC 并产生 if/id 级 nop 控制。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module bru (
  input                         i_clk         ,
  input                         i_rst_n       ,
  input                         i_idu_valid   , // use for jalr, to fix bug with: jalr x[n],x[n],imm
  input     [`REG_ADDRW-1:0]    i_idu_rs1id   , // use for jalr, to fix bug with: jalr x[n],x[n],imm
  input     [`REG_ADDRW-1:0]    i_exu_rdid    , // use for jalr, to fix bug with: jalr x[n],x[n],imm
  input                         i_jal         ,
  input                         i_jalr        ,
  input                         i_brch        ,
  input     [2:0]               i_bfun3       ,
  input     [`CPU_WIDTH-1:0]    i_rs1         ,
  input     [`CPU_WIDTH-1:0]    i_rs2         ,
  input     [`CPU_WIDTH-1:0]    i_imm         ,
  input     [`CPU_WIDTH-1:0]    i_ifupc       ,
  input     [`CPU_WIDTH-1:0]    i_idupc       ,
  input                         i_iru_jump    ,
  input     [`CPU_WIDTH-1:0]    i_iru_pc      ,
  input                         i_fence_jump  ,
  input     [`CPU_WIDTH-1:0]    i_fence_pc    , //if fence ,fence_pc = lsu_pc+4
  output    [`CPU_WIDTH-1:0]    o_next_pc     ,
  output                        o_ifid_nop
);

  // TODO(agent): implement bru here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
