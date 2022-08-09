`include "defines.sv"
module dCache (
  input                       i_clk     ,
  input                       i_rst_n   ,
  uni_if.Slave                dCacheIf_S,  //  64 bit width
  uni_if.Master               dMemIf_M     // 128 bit width
);

  //1. dCache : ////////////////////////////////////////////////////////////////////////////////////////////////////////////

  //          |<------16 bytes---->|                |<------16 bytes---->|
  //   ⌈‾‾‾‾‾⌉ ⌈‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾⌉         ⌈‾‾‾‾‾⌉ ⌈‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾⌉ ——
  //   |    | |                    |        |     | |                   |  ↑
  //   |    | |                    |        |     | |                   |  |
  //   |    | |                    |        |     | |                   |  |
  //   |    | |                    |        |     | |                   |  |
  //   |Tag0| |    Cacheline0      |        |Tag1 | |    Cacheline1     |  |128 sets.
  //   |    | |                    |        |     | |                   |  |
  //   |    | |                    |        |     | |                   |  |
  //   |    | |                    |        |     | |                   |  |
  //   |    | |                    |        |     | |                   |  ↓
  //   ⌊_____⌋ ⌊____________________⌋         ⌊_____⌋ ⌊____________________⌋ ——


  // tag array signal:
  logic                  tary_wen   [1:0];
  logic [`dTARY_W-1:0]   tary_wdata [1:0];
  logic [`dTARY_W-1:0]   tary_rdata [1:0];

  // data array signal:
  logic                  dary_ren   [1:0];
  logic                  dary_wen   [1:0];
  logic [15:0]           dary_wstrb [1:0];
  logic [127:0]          dary_wdata [1:0];
  logic [127:0]          dary_rdata [1:0];

  for (genvar i=0; i<2 ; i=i+1) begin
    tag_ary #(
      .DATA_WIDTH (`dTARY_W)
    ) u_tag_ary(
      .i_clk   (i_clk         ),
      .i_rst_n (i_rst_n       ),
      .i_wen   (tary_wen  [i] ),
      .i_addr  (index         ),
      .i_din   (tary_wdata[i] ),
      .o_dout  (tary_rdata[i] )
    );
    data_ary u_data_ary(
      .i_clk   (i_clk         ),
      .i_rst_n (i_rst_n       ),
      .i_ren   (dary_ren  [i] ),
      .i_wen   (dary_wen  [i] ),
      .i_wstrb (dary_wstrb[i] ),
      .i_addr  (index         ),
      .i_wdata (dary_wdata[i] ),
      .o_rdata (dary_rdata[i] )
    );
  end

  logic [127:0] recent, recent_wen;
  logic recent_wdata;

  for (genvar i=0; i<128 ; i=i+1) begin
    stl_reg #(
      .WIDTH      (1            ),
      .RESET_VAL  (1'b0         )
    ) reg_recent (
      .i_clk      (i_clk        ),
      .i_rst_n    (i_rst_n      ),
      .i_wen      (recent_wen[i]),
      .i_din      (recent_wdata ),
      .o_dout     (recent[i]    )
    );
  end

  // 2. control signals: ///////////////////////////////////////////////////////////////////////////////////////////////////
  wire [`TAG_BIT] tag    = dCacheIf_S.addr[`ADR_WIDTH-1:11];
  wire [6:0]      index  = dCacheIf_S.addr[ 10:4];
  wire [3:0]      offset = dCacheIf_S.addr[  3:0];

  wire [1:0] hit;
  for (genvar i=0; i<2 ; i=i+1) begin
    assign hit[i] = (tary_rdata[i][`TAG_BIT] == tag) & tary_rdata[i][`VLD_BIT];
  end

  wire victim_blkid, victim_dirty, victim_valid;
  wire [`TAG_BIT] victim_tag;

  assign victim_blkid = ~recent[index];
  assign victim_dirty = tary_rdata[victim_blkid][`DRT_BIT];
  assign victim_valid = tary_rdata[victim_blkid][`VLD_BIT];
  assign victim_tag   = tary_rdata[victim_blkid][`TAG_BIT];

  // 3. state machine: /////////////////////////////////////////////////////////////////////////////////////////////////////

  enum logic[1:0] {IDLE, WBUS, RBUS, HIT} state;
  logic [1:0] ich_state, ich_state_n;

  stl_reg #(
    .WIDTH      (2          ),
    .RESET_VAL  (IDLE       )
  ) reg_status (
  	.i_clk      (i_clk      ),
    .i_rst_n    (i_rst_n    ),
    .i_wen      (1'b1       ),
    .i_din      (ich_state_n),
    .o_dout     (ich_state  )
  );

  always @(*) begin
    case (ich_state)
      IDLE:     if(dCacheIf_S.valid)begin
                  if(|hit)begin
                    ich_state_n = HIT;
                  end else if (victim_valid & victim_dirty) begin
                    ich_state_n = WBUS;
                  end else begin
                    ich_state_n = RBUS;
                  end
                end else begin
                  ich_state_n = IDLE;
                end
      WBUS:     if(dMemIf_M.ready)
                  ich_state_n = RBUS;
                else
                  ich_state_n = WBUS;
      RBUS:     if(dMemIf_M.ready)
                  ich_state_n = IDLE;
                else
                  ich_state_n = RBUS;
      HIT:      ich_state_n = IDLE;
      default:  ich_state_n = IDLE;
    endcase
  end

  // 4. hit, read/write data array, update recent/dirty, update iCacheIf_S signal: ///////////////////////////////////////////
  logic                 tary_hit_wen   [1:0];
  logic [`dTARY_W-1:0]  tary_hit_wdata [1:0];
  logic                 dary_hit_ren   [1:0];
  logic                 dary_hit_wen   [1:0];
  logic [15:0]          dary_hit_wstrb [1:0];
  logic [127:0]         dary_hit_wdata [1:0];

  // 4.1 update recent://////////////////////////////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<128; i=i+1 ) begin
    assign recent_wen[i] = (ich_state == HIT) & (index == i);
  end
  assign recent_wdata = hit[1];

  // 4.2 read data array: ///////////////////////////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<2 ; i=i+1) begin
    assign dary_hit_ren  [i] = (ich_state_n == HIT) & hit[i] & (dCacheIf_S.reqtyp == `REQ_READ);
  end

  wire [127:0] hit_cacheline = hit[1] ? dary_rdata[1] : (hit[0] ? dary_rdata[0] : 128'b0);

  // 4.3 write data array, update tag array dirty bit: ///////////////////////////////////////////////////////////////////////
  wire [7:0] wstrb;
  stl_mux_default #(4, 2, 8) mux_size (wstrb, dCacheIf_S.size, 8'b0, {
    2'b00 , 8'b0000_0001, // 1 byte.
    2'b01 , 8'b0000_0011, // 2 byte.
    2'b10 , 8'b0000_1111, // 4 byte.
    2'b11 , 8'b1111_1111  // 8 byte.
  });

  for (genvar i=0; i<2 ; i=i+1) begin
    assign tary_hit_wen   [i] = (dCacheIf_S.reqtyp == `REQ_WRITE) & (ich_state == HIT) & hit[i];
    assign tary_hit_wdata [i] = {1'b1,tary_rdata[i][`dTARY_W-2:0]};       // dirty bit <= 1;
    assign dary_hit_wen   [i] = (dCacheIf_S.reqtyp == `REQ_WRITE) & (ich_state == HIT) & hit[i];
    assign dary_hit_wstrb [i] = {8'b0, wstrb} << offset;                    // bytes.
    assign dary_hit_wdata [i] = {64'b0, dCacheIf_S.wdata} << {offset,3'b0}; // bits. {offset,3'b0} means (offset*8)
  end

  // 4.4 update iCacheIf_S signal: ///////////////////////////////////////////////////////////////////////////////////////////
  // input:  valid, addr, reqtyp, wdata, size;
  // output: ready, rdata;
  assign dCacheIf_S.ready = (ich_state == HIT);
  assign dCacheIf_S.rdata = hit_cacheline >> {offset,3'b0};

  // 5. miss, write dirty cacheline to bus, read new cacheline from bus : ///////////////////////////////////////////////////
  logic                 tary_miss_wen   [1:0];
  logic [`dTARY_W-1:0]  tary_miss_wdata [1:0];
  logic                 dary_miss_ren   [1:0];
  logic                 dary_miss_wen   [1:0];
  logic [15:0]          dary_miss_wstrb [1:0];
  logic [127:0]         dary_miss_wdata [1:0];

  // 5.1 read dirty victim block, write bus: ///////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<2 ; i=i+1) begin
    assign dary_miss_ren  [i] = (ich_state_n == WBUS) & (i == victim_blkid);
  end

  // 5.2 read bus, write to victim block: //////////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<2 ; i=i+1) begin
    assign tary_miss_wen    [i] = dMemIf_M.valid & dMemIf_M.ready & (i == victim_blkid);
    assign tary_miss_wdata  [i] = (ich_state == WBUS) ? {1'b0, victim_valid, victim_tag}: {1'b0, 1'b1, tag};  //{dirty,valid,tag};
    // assign tary_miss_wen    [i] = (ich_state == RBUS) & dMemIf_M.ready & (i == victim_blkid);
    // assign tary_miss_wdata  [i] = {1'b0, 1'b1, tag};  //{dirty,valid,tag};
    assign dary_miss_wen    [i] = (ich_state == RBUS) & dMemIf_M.ready & (i == victim_blkid);
    assign dary_miss_wstrb  [i] = 16'hffff;
    assign dary_miss_wdata  [i] = dMemIf_M.rdata;
  end

  // 5.3 dMemIf_M signal: //////////////////////////////////////////////////////////////////////////////////////////////////
  // input:  ready, rdata;
  // output: valid, reqtyp, addr, wdata, size;

  assign dMemIf_M.valid  =  (ich_state == WBUS) | (ich_state == RBUS);
  assign dMemIf_M.reqtyp =  (ich_state == WBUS) ? `REQ_WRITE : `REQ_READ;
  assign dMemIf_M.addr   =  (ich_state == WBUS) ? {victim_tag,index,4'b0} : {tag,index,4'b0};
  assign dMemIf_M.wdata  =  (ich_state == WBUS) ? dary_rdata[victim_blkid] : 128'b0;
  assign dMemIf_M.size   =  2'b11;

  // 6. tag_arry & data_array control signals://////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<2 ; i=i+1) begin
    assign tary_wen    [i] = tary_miss_wen[i] | tary_hit_wen[i];
    assign tary_wdata  [i] = tary_miss_wen[i] ? tary_miss_wdata[i] : tary_hit_wdata[i];
    assign dary_ren    [i] = dary_miss_ren[i] | dary_hit_ren[i];
    assign dary_wen    [i] = dary_miss_wen[i] | dary_hit_wen[i];
    assign dary_wstrb  [i] = dary_miss_wen[i] ? dary_miss_wstrb[i] : dary_hit_wstrb[i];
    assign dary_wdata  [i] = dary_miss_wen[i] ? dary_miss_wdata[i] : dary_hit_wdata[i];
  end

endmodule
