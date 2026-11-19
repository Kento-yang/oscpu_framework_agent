// ============================================================================
// Module: idu_normal
// Role: 普通指令译码器。R/I/U/J/B 型算术、逻辑、移位、访存与分支指令的译码。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module idu_normal(
  input        [`INS_WIDTH-1:0]     i_ins         ,
  // 1. for reg:
  output logic [`REG_ADDRW-1:0]     o_rs1id       ,
  output logic [`REG_ADDRW-1:0]     o_rs2id       ,
  // 2. for exu:
  output logic [`CPU_WIDTH-1:0]     o_imm         ,
  output logic [`EXU_SEL_WIDTH-1:0] o_src_sel     ,
  output logic [`EXU_OPT_WIDTH-1:0] o_exopt       ,
  // 3. for lsu:
  output logic [2:0]                o_lsu_func3   , //for lsu.
  output logic                      o_lsu_lden    , //for lsu.
  output logic                      o_lsu_sten    , //for lsu.  
  // 4. for wbu:
  output logic [`REG_ADDRW-1:0]     o_rdid        , //for wbu.
  output logic                      o_rdwen       , //for wbu.
  // 5. for bru:
  output logic                      o_jal         , //for bru.
  output logic                      o_jalr        , //for bru.
  output logic                      o_brch        , //for bru.
  output logic [2:0]                o_bfun3         //for bru.
);

  // TODO(agent): implement idu_normal here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
