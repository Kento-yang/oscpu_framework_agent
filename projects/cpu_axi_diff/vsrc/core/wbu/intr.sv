`define M_MODE 2'b11
`define MIE    3
`define MPIE   7
`define MPP    12:11

module intr (
  input   logic                   i_clk         ,
  input   logic                   i_rst_n       ,
  // wbu:
  input   logic                   i_wbu_commit  ,
  input   logic [`INS_WIDTH-1:0]  i_wbu_ins     ,
  input   logic [`CPU_WIDTH-1:0]  i_wbu_pc      ,
  // for bru:
  output  logic                   o_wbu_intr    ,
  output  logic [`CPU_WIDTH-1:0]  o_wbu_intrpc  ,
  // csr_file:
  input   logic [`CPU_WIDTH-1:0]  i_mtvec        ,  // ecall.
  input   logic [`CPU_WIDTH-1:0]  i_mepc         ,  // mret.
  input   logic [`CPU_WIDTH-1:0]  i_mstatus      ,  // ecall.
  output  logic                   o_mepc_wen     ,  // ecall.
  output  logic [`CPU_WIDTH-1:0]  o_mepc_wdata   ,  // ecall.
  output  logic                   o_mcause_wen   ,  // ecall.
  output  logic [`CPU_WIDTH-1:0]  o_mcause_wdata ,  // ecall.
  output  logic                   o_mstatus_wen  ,  // ecall.
  output  logic [`CPU_WIDTH-1:0]  o_mstatus_wdata   // ecall.
);

  wire ecall = (i_wbu_ins == `INS_WIDTH'h00000073);
  wire mret  = (i_wbu_ins == `INS_WIDTH'h30200073);

  assign o_wbu_intr = ecall | mret;
  assign o_wbu_intrpc = ecall ? i_mtvec : (mret ? i_mepc : `CPU_WIDTH'b0);

  assign o_mepc_wen = i_wbu_commit & ecall;
  assign o_mepc_wdata = i_wbu_pc;

  assign o_mcause_wen = i_wbu_commit & ecall;
  assign o_mcause_wdata = ecall ? `CPU_WIDTH'd11 : `CPU_WIDTH'b0;

  assign o_mstatus_wen = i_wbu_commit & (ecall | mret);

  logic [`CPU_WIDTH-1:0] ecall_mstatus_wdata;
  assign ecall_mstatus_wdata[63:13] = i_mstatus[63:13];
  assign ecall_mstatus_wdata[`MPP]  = `M_MODE; 
  assign ecall_mstatus_wdata[10:8]  = i_mstatus[10:8];
  assign ecall_mstatus_wdata[`MPIE] = i_mstatus[`MIE]; 
  assign ecall_mstatus_wdata[6:0]   = i_mstatus[6:0]; 

  logic [`CPU_WIDTH-1:0] mret_mstatus_wdata;
  assign mret_mstatus_wdata[63:13] = i_mstatus[63:13];
  assign mret_mstatus_wdata[`MPP]  = 3'b0; 
  assign mret_mstatus_wdata[10:8]  = i_mstatus[10:8];
  assign mret_mstatus_wdata[`MPIE] = 1'b1; 
  assign mret_mstatus_wdata[6:4]   = i_mstatus[6:4]; 
  assign mret_mstatus_wdata[`MIE]  = i_mstatus[`MPIE];
  assign mret_mstatus_wdata[2:0]   = i_mstatus[2:0]; 

  assign o_mstatus_wdata = ecall ? ecall_mstatus_wdata :
                          (mret ? mret_mstatus_wdata : `CPU_WIDTH'b0);

endmodule
