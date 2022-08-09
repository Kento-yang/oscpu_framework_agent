module sram_tb;


  reg          i_clk  ;
  reg          i_rst_n;
  reg          i_ren  ;
  reg          i_wen  ;
  reg  [ 15:0] i_wstrb;
  reg  [  6:0] i_addr ;
  reg  [127:0] i_wdata;
  wire [127:0] o_rdata;


  initial begin
    $dumpfile("build/sram.vcd");
    $dumpvars(0, sram_tb);

    i_clk = 1;
    i_rst_n = 0;
    i_ren = 0;
    i_wen = 0;
    i_addr = 0;
    i_wdata = 0;
    #5 i_rst_n  =  1;

    #5 i_wen = 1;
    i_wstrb = 16'hf0ff;
    i_wdata = 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;
    i_addr = 7'b1001101;
    #11 i_wen = 0 ;
    i_wstrb = 0;

    i_wen = 1;
    i_wstrb = 16'hff0f;
    i_wdata = 128'h0fff_bea3_ffff_7123_ffff_f32e_9a8e_ff7c;
    i_addr = 7'b0101101;
    #10 i_wen = 0 ;
    i_wstrb = 0;

    i_ren = 1;
    i_wdata = 0;
    i_addr = 7'b1001101;
    #10 i_ren = 0 ;

    i_ren = 1;
    i_wdata = 0;
    i_addr = 7'b0101101;
    #10 i_ren = 0 ;

    #100 $finish();
  end
    
  always #5 i_clk = ~i_clk;

  sram u_sram(
    .i_clk   (i_clk   ),
    .i_rst_n (i_rst_n ),
    .i_ren   (i_ren   ),
    .i_wen   (i_wen   ),
    .i_wstrb (i_wstrb ),
    .i_addr  (i_addr  ),
    .i_wdata (i_wdata ),
    .o_rdata (o_rdata )
  );

endmodule