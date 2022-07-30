module wbu (
  // 1. signal to pipe shake hands:
  input   logic                   i_clk         ,
  input   logic                   i_rst_n       ,
  input   logic                   i_pre_valid   ,   // from pre-stage
  output  logic                   o_pre_ready   ,   //  to  pre-stage

  // 2. input comb signal from pre stage:
  input   logic [`CPU_WIDTH-1:0]  i_lsu_exres   ,
  input   logic [`CPU_WIDTH-1:0]  i_lsu_lsres   ,
  input   logic [`REG_ADDRW-1:0]  i_lsu_rdid    ,
  input   logic                   i_lsu_rdwen   ,
  input   logic                   i_lsu_lden    ,
  input   logic [`CPU_WIDTH-1:0]  s_lsu_pc      ,
  input   logic [`INS_WIDTH-1:0]  s_lsu_ins     ,
  input   logic                   s_lsu_nop     ,

  // 3. output comb signal to post stage:
  output  logic                   o_wbu_rdwen   ,
  output  logic [`CPU_WIDTH-1:0]  o_wbu_rd      ,
  output  logic [`REG_ADDRW-1:0]  o_wbu_rdid    ,
  // 4 for sim:
  output  logic [`CPU_WIDTH-1:0]  s_wbu_pc      ,
  output  logic [`INS_WIDTH-1:0]  s_wbu_ins     ,
  output  logic                   s_wbu_cmt     ,
  output  logic                   s_wbu_nop
);

  // 1. shake hands to reg pre stage signals:///////////////////////////////////////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  wire o_post_valid, i_post_ready;
  assign o_pre_ready = o_post_valid & i_post_ready | !o_post_valid;

  wire pre_sh, commit;
  assign pre_sh = i_pre_valid & o_pre_ready;
  assign commit = o_post_valid & i_post_ready;

  logic [`CPU_WIDTH-1:0]  lsu_exres_r  ;
  logic [`CPU_WIDTH-1:0]  lsu_lsres_r  ;
  logic [`REG_ADDRW-1:0]  lsu_rdid_r   ;
  logic                   lsu_rdwen_r  ;
  logic                   lsu_lden_r   ;
  logic [`CPU_WIDTH-1:0]  lsu_pc_r     ;
  logic [`INS_WIDTH-1:0]  lsu_ins_r    ;

  stl_reg #(
    .WIDTH      (3*`CPU_WIDTH+`REG_ADDRW+2+`INS_WIDTH+1),
    .RESET_VAL  (0       )
  ) regs(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (pre_sh ),
    .i_din      ({i_lsu_exres, i_lsu_lsres, i_lsu_rdid, i_lsu_rdwen, i_lsu_lden, s_lsu_pc, s_lsu_ins, s_lsu_nop} ),
    .o_dout     ({lsu_exres_r, lsu_lsres_r, lsu_rdid_r, lsu_rdwen_r, lsu_lden_r, lsu_pc_r, lsu_ins_r, s_wbu_nop} )
  );

  // 2. generate valid signals for post stage://////////////////////////////////////////////////////////////////

  stl_reg #(
    .WIDTH      (1            ), 
    .RESET_VAL  (0            )
  ) postvalid (
  	.i_clk      (i_clk        ), 
    .i_rst_n    (i_rst_n      ), 
    .i_wen      (o_pre_ready  ), 
    .i_din      (i_pre_valid  ), 
    .o_dout     (o_post_valid )
  );

  assign i_post_ready = 1;  // post stage(regfile) always be ready to receive data.

  // 3. use pre stage signals to generate comb logic for post stage://////////////////////////////////////////
  
  assign o_wbu_rdwen  = commit & lsu_rdwen_r;
  assign o_wbu_rd     = lsu_lden_r ? lsu_lsres_r : lsu_exres_r;
  assign o_wbu_rdid   = lsu_rdid_r  ;
  assign s_wbu_pc     = lsu_pc_r    ;
  assign s_wbu_ins    = lsu_ins_r   ;
  assign s_wbu_cmt    = commit      ;

endmodule
