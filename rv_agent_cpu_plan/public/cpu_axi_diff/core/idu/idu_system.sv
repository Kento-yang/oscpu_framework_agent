// ============================================================================
// Module: idu_system
// Role: 系统指令译码器。ecall/mret/csrrw/csrrs/csrrc 等 SYSTEM 指令的译码。
//
// 说明：本文件是公开骨架，模块名、参数与端口方向/位宽是固定契约，不得修改。
//       TODO(agent)：在 endmodule 之前实现该模块的逻辑。
//       可以新增内部信号、子模块和 .sv 文件；不要修改与 top.sv/SimTop.sv 的接口。
// ============================================================================
`include "defines.sv"
module idu_system(
  input        [`INS_WIDTH-1:0]     i_ins         ,
  // 1. for csr:
  output logic [`CSR_ADDRW-1:0]     o_csrsid      ,
  output logic                      o_csrsren     , // csr source read enable.
  // 2. for reg:
  output logic [`REG_ADDRW-1:0]     o_rs1id       ,
  // 3. for exu:
  output logic [`CPU_WIDTH-1:0]     o_imm         ,
  output logic [`CSR_OPT_WIDTH-1:0] o_excsropt    , //exu csr option.
  output logic                      o_excsrsrc    , //exu csr source.
  // 4. for wbu:
  output logic [`REG_ADDRW-1:0]     o_rdid        ,
  output logic                      o_rdwen       ,
  output logic [`CSR_ADDRW-1:0]     o_csrdid      ,
  output logic                      o_csrdwen       // csr dest write enable.
);

  // TODO(agent): implement idu_system here.
  // 端口契约见上方声明；实现时请遵守 defines.sv 中的宏定义与任务卡的 ISA/CSR 约定。

endmodule
