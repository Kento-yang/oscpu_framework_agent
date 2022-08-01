`include "defines.sv"
module csrfile (
  input logic                   i_clk   ,
  input logic                   i_rst_n ,

  // from idu, for csrrw/csrrs/csrrc:
  input  logic                  i_ren   , 
  input  logic [`CSR_ADDRW-1:0] i_raddr ,
  output logic [`CPU_WIDTH-1:0] o_rdata ,

  // from wbu, for csrrw/csrrs/csrrc:
  input  logic                  i_wen   ,
  input  logic [`CSR_ADDRW-1:0] i_waddr ,
  input  logic [`CPU_WIDTH-1:0] i_wdata ,

  // from intr:
  input  logic                  i_mepc_wen      ,   // ecall.
  input  logic [`CPU_WIDTH-1:0] i_mepc_wdata    ,   // ecall.
  input  logic                  i_mcause_wen    ,   // ecall.
  input  logic [`CPU_WIDTH-1:0] i_mcause_wdata  ,   // ecall.
  input  logic                  i_mstatus_wen   ,   // ecall.
  input  logic [`CPU_WIDTH-1:0] i_mstatus_wdata ,   // ecall.
  output logic [`CPU_WIDTH-1:0] o_mtvec         ,   // ecall.
  output logic [`CPU_WIDTH-1:0] o_mstatus       ,   // ecall.
  output logic [`CPU_WIDTH-1:0] o_mepc          ,   // mret.

  // for difftest:
  output logic [`CPU_WIDTH-1:0] s_mtvec         ,
  output logic [`CPU_WIDTH-1:0] s_mepc          ,
  output logic [`CPU_WIDTH-1:0] s_mstatus       ,
  output logic [`CPU_WIDTH-1:0] s_mcause        ,
  output logic [`CPU_WIDTH-1:0] s_mcycle
);

  // 1. csr reg file: //////////////////////////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0] mepc   ;
  logic [`CPU_WIDTH-1:0] mtvec  ;
  logic [`CPU_WIDTH-1:0] mcause ;
  logic [`CPU_WIDTH-1:0] mstatus;
  logic [`CPU_WIDTH-1:0] mcycle ;

  // 2. read csr  reg file: ////////////////////////////////////////////////////////////
  wire ren_mepc    = i_ren & (i_raddr == `ADDR_MEPC   );
  wire ren_mtvec   = i_ren & (i_raddr == `ADDR_MTVEC  );
  wire ren_mcause  = i_ren & (i_raddr == `ADDR_MCAUSE );
  wire ren_mstatus = i_ren & (i_raddr == `ADDR_MSTATUS);
  wire ren_mcycle  = i_ren & (i_raddr == `ADDR_MCYCLE );

  assign o_rdata =  ren_mepc    ? mepc    : 
                  ( ren_mtvec   ? mtvec   : 
                  ( ren_mcause  ? mcause  : 
                  ( ren_mstatus ? mstatus : 
                  ( ren_mcycle  ? mcycle  : `CPU_WIDTH'b0 ))));

  assign o_mtvec = mtvec    ;
  assign o_mepc  = mepc     ;
  assign o_mstatus = mstatus;

  // 3. write csr  reg file: ////////////////////////////////////////////////////////////
  wire wen_mepc    = (i_wen & (i_waddr == `ADDR_MEPC   )) | i_mepc_wen   ;
  wire wen_mcause  = (i_wen & (i_waddr == `ADDR_MCAUSE )) | i_mcause_wen ;
  wire wen_mtvec   = (i_wen & (i_waddr == `ADDR_MTVEC  ));
  wire wen_mstatus = (i_wen & (i_waddr == `ADDR_MSTATUS)) | i_mstatus_wen;

  wire [`CPU_WIDTH-1:0] wdata_mepc    = i_mepc_wen    ? i_mepc_wdata    : i_wdata;
  wire [`CPU_WIDTH-1:0] wdata_mcause  = i_mcause_wen  ? i_mcause_wdata  : i_wdata;
  wire [`CPU_WIDTH-1:0] wdata_mtvec   = i_wdata;
  wire [`CPU_WIDTH-1:0] wdata_mstatus = i_mstatus_wen ? i_mstatus_wdata : i_wdata;
  wire [`CPU_WIDTH-1:0] wdata_mcycle  =  (i_wen & (i_waddr == `ADDR_MCYCLE )) ? i_wdata : mcycle+1;

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mepc (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mepc     ),
    .i_din    (wdata_mepc   ),
    .o_dout   (mepc         )
  );

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mcause (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mcause   ),
    .i_din    (wdata_mcause ),
    .o_dout   (mcause       )
  );

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mtvec (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mtvec    ),
    .i_din    (wdata_mtvec  ),
    .o_dout   (mtvec        )
  );

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mstatus (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mstatus  ),
    .i_din    (wdata_mstatus),
    .o_dout   (mstatus      )
  );

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mcycle (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (1'b1         ),
    .i_din    (wdata_mcycle ),
    .o_dout   (mcycle       )
  );

  // use for difftest sim :/
  assign s_mepc   = wen_mepc    ? wdata_mepc   : mepc    ;
  assign s_mcause = wen_mcause  ? wdata_mcause : mcause  ;
  assign s_mtvec  = wen_mtvec   ? wdata_mtvec  : mtvec   ;
  assign s_mstatus= wen_mstatus ? wdata_mstatus: mstatus ;
  assign s_mcycle = wdata_mcycle;

endmodule
