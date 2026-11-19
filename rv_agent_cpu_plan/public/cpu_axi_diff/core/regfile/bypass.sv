// ============================================================================
// Module: bypass
// Role: 旁路与冒险处理。根据 EXU/LSU/WBU 的写回信息选择 rs1/rs2，产生 stall/nop 控制。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module bypass (
  input                            i_clk         ,
  input                            i_rst_n       ,

  // 1. from exu/lsu/wbu to generate rs1/rs2 for idu:
  // from idu:
  input         [`REG_ADDRW-1:0]   i_idu_rs1id   ,
  input         [`REG_ADDRW-1:0]   i_idu_rs2id   ,
  // from exu:
  input                            i_exu_lden    ,
  input                            i_exu_rdwen   ,
  input         [`REG_ADDRW-1:0]   i_exu_rdid    ,
  input         [`CPU_WIDTH-1:0]   i_exu_exres   ,
  // from lsu:
  input                            i_lsu_lden    ,
  input                            i_lsu_rdwen   ,
  input         [`REG_ADDRW-1:0]   i_lsu_rdid    ,
  input         [`CPU_WIDTH-1:0]   i_lsu_exres   ,
  input         [`CPU_WIDTH-1:0]   i_lsu_lsres   ,
  // from wbu:
  input                            i_wbu_rdwen   ,
  input         [`REG_ADDRW-1:0]   i_wbu_rdid    ,
  input         [`CPU_WIDTH-1:0]   i_wbu_rd      ,
  // to id/ex:
  output logic  [`CPU_WIDTH-1:0]   o_idu_rs1     ,
  output logic  [`CPU_WIDTH-1:0]   o_idu_rs2     ,
  // to pc if/id id/ex:
  output                           o_idex_nop    ,
  output                           o_ifid_stall  ,

  // 2. for sim,difftest.:
  output        [`CPU_WIDTH-1:0]   s_regs [`REG_COUNT-1:0]    // use for difftest.
);

  // TODO(agent): implement bypass here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
