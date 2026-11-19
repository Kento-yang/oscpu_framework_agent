// Simple AXI4 slave + 256 KiB memory for the RVA-01 public smoke tests.
//
// Address map: the CPU sees the image at BASE (default 0x8000_0000).
// The model accepts one read and one write transaction at a time and
// supports INCR bursts with 64-bit beats (size=3 is what the reference
// cache uses).  AW must be accepted before W beats are accepted; this is
// legal AXI backpressure and matches the reference uni2axi/cache behaviour.
//
// Plusargs:
//   +IMAGE=<path>       raw binary loaded at BASE (when INIT_ADDI64=0)
//   +RESP_DELAY=<0..8>  cycles before the first R beat and before B
//   +BACKPRESSURE=<0/1> gate ready with a deterministic 1-in-3 pattern
//
// Validated with the reference design through public/tb.sv and
// public/tb_cpu_elf.sv on 2026-11-17, including response delay and
// backpressure runs.

`timescale 1ns/1ps

module axi_mem_model #(
  parameter int          MEM_BYTES   = 256 * 1024,
  parameter logic [63:0] BASE        = 64'h0000_0000_8000_0000,
  parameter bit          INIT_ADDI64 = 1'b0
)(
  input  logic        clock,
  input  logic        reset,

  // AW
  output logic        aw_ready,
  input  logic        aw_valid,
  input  logic [63:0] aw_addr,
  input  logic [ 2:0] aw_prot,
  input  logic [ 3:0] aw_id,
  input  logic        aw_user,
  input  logic [ 7:0] aw_len,
  input  logic [ 2:0] aw_size,
  input  logic [ 1:0] aw_burst,
  input  logic        aw_lock,
  input  logic [ 3:0] aw_cache,
  input  logic [ 3:0] aw_qos,

  // W
  output logic        w_ready,
  input  logic        w_valid,
  input  logic [63:0] w_data,
  input  logic [ 7:0] w_strb,
  input  logic        w_last,

  // B
  input  logic        b_ready,
  output logic        b_valid,
  output logic [ 1:0] b_resp,
  output logic [ 3:0] b_id,
  output logic        b_user,

  // AR
  output logic        ar_ready,
  input  logic        ar_valid,
  input  logic [63:0] ar_addr,
  input  logic [ 2:0] ar_prot,
  input  logic [ 3:0] ar_id,
  input  logic        ar_user,
  input  logic [ 7:0] ar_len,
  input  logic [ 2:0] ar_size,
  input  logic [ 1:0] ar_burst,
  input  logic        ar_lock,
  input  logic [ 3:0] ar_cache,
  input  logic [ 3:0] ar_qos,

  // R
  input  logic        r_ready,
  output logic        r_valid,
  output logic [ 1:0] r_resp,
  output logic [63:0] r_data,
  output logic        r_last,
  output logic [ 3:0] r_id,
  output logic        r_user,

  // Statistics
  output logic [31:0] read_beats,
  output logic [31:0] write_beats,
  output logic [31:0] backpressure_cycles,
  output logic [31:0] image_bytes
);

  logic [7:0] mem [0:MEM_BYTES-1];

  // ------------------------------------------------------------------
  // Configuration and memory preload (time 0)
  // ------------------------------------------------------------------
  int unsigned resp_delay_cfg;
  bit          bp_en;
  string       image_file;
  int          image_fd;
  int          image_ch;
  int          image_idx;
  int          cfg_tmp;

  initial begin
    resp_delay_cfg = 0;
    bp_en          = 1'b0;
    image_bytes    = 0;

    if ($value$plusargs("RESP_DELAY=%d", cfg_tmp)) begin
      if (cfg_tmp < 0) cfg_tmp = 0;
      if (cfg_tmp > 8) cfg_tmp = 8;
      resp_delay_cfg = cfg_tmp;
    end
    if ($value$plusargs("BACKPRESSURE=%d", cfg_tmp))
      bp_en = (cfg_tmp != 0);

    for (int i = 0; i < MEM_BYTES; i = i + 1)
      mem[i] = 8'h00;

    if (INIT_ADDI64) begin
      for (int i = 0; i < 64; i = i + 1) begin
        logic [31:0] insn;
        // addi x((i%31)+1), x0, i+1
        insn = 32'h0000_0013 |
               (((i + 1) & 32'h0000_0fff) << 20) |
               ((((i % 31) + 1) & 32'h0000_001f) << 7);
        for (int b = 0; b < 4; b = b + 1)
          mem[4*i + b] = insn[8*b +: 8];
      end
      image_bytes = 64 * 4;
      $display("AXI_MEM: preloaded 64-ADDI program at %h", BASE);
    end
    else if ($value$plusargs("IMAGE=%s", image_file)) begin
      image_fd = $fopen(image_file, "rb");
      if (image_fd == 0)
        $fatal(1, "AXI_MEM: cannot open IMAGE=%s", image_file);
      image_idx = 0;
      image_ch  = $fgetc(image_fd);
      while (image_ch != -1 && image_idx < MEM_BYTES) begin
        mem[image_idx] = image_ch[7:0];
        image_idx = image_idx + 1;
        image_ch  = $fgetc(image_fd);
      end
      $fclose(image_fd);
      image_bytes = image_idx;
      $display("AXI_MEM: loaded %0d bytes from %s at %h",
               image_idx, image_file, BASE);
      if (image_ch != -1)
        $display("AXI_MEM: warning: image larger than %0d bytes, truncated",
                 MEM_BYTES);
    end
    else begin
      $display("AXI_MEM: no IMAGE and INIT_ADDI64=0; memory is zero");
    end
  end

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  function automatic bit in_range(input logic [63:0] addr);
    return (addr >= BASE) && (addr < (BASE + MEM_BYTES));
  endfunction

  function automatic logic [63:0] read_beat(
    input logic [63:0] addr,
    input logic [ 2:0] size
  );
    logic [63:0] value;
    int          idx;
    int          nbytes;
    value  = 64'h0;
    idx    = int'(addr - BASE);
    nbytes = 1 << size;
    for (int b = 0; b < nbytes; b = b + 1)
      if (in_range(addr + b))
        value[8*b +: 8] = mem[idx + b];
    return value;
  endfunction

  // ------------------------------------------------------------------
  // Backpressure phase
  // ------------------------------------------------------------------
  logic [1:0] bp_phase;
  logic       bp_stall;

  assign bp_stall = bp_en && (bp_phase == 2'b01);

  always @(posedge clock or posedge reset) begin
    if (reset)
      bp_phase <= 2'b00;
    else if (bp_phase == 2'b10)
      bp_phase <= 2'b00;
    else
      bp_phase <= bp_phase + 2'b01;
  end

  // ------------------------------------------------------------------
  // Read channel
  // ------------------------------------------------------------------
  localparam logic [0:0] R_IDLE = 1'b0;
  localparam logic [0:0] R_DATA = 1'b1;
  localparam logic [1:0] W_IDLE = 2'b00;
  localparam logic [1:0] W_DATA = 2'b01;
  localparam logic [1:0] W_RESP = 2'b10;

  logic        r_state;
  logic [63:0] r_addr;
  logic [ 7:0] r_len;
  logic [ 7:0] r_cnt;
  logic [ 2:0] r_size;
  logic [ 3:0] r_id_reg;
  logic        r_error;
  logic [ 3:0] r_delay;

  logic [1:0]  w_state;
  logic [63:0] w_addr;
  logic [ 2:0] w_size;
  logic [ 3:0] w_id_reg;
  logic        w_error;
  logic [ 3:0] b_delay;

  assign aw_ready = (w_state == W_IDLE) && !bp_stall;
  assign w_ready  = (w_state == W_DATA) && !bp_stall;
  assign b_valid  = (w_state == W_RESP) && (b_delay == 4'd0);
  assign b_resp   = w_error ? 2'b10 : 2'b00;
  assign b_id     = w_id_reg;
  assign b_user   = 1'b0;

  assign ar_ready = (r_state == R_IDLE) && !bp_stall;
  assign r_valid  = (r_state == R_DATA) && (r_delay == 4'd0);
  assign r_data   = read_beat(r_addr, r_size);
  assign r_resp   = r_error ? 2'b10 : 2'b00;
  assign r_last   = (r_cnt == r_len);
  assign r_id     = r_id_reg;
  assign r_user   = 1'b0;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      r_state <= R_IDLE;
      r_addr  <= 64'h0;
      r_len   <= 8'h0;
      r_cnt   <= 8'h0;
      r_size  <= 3'h0;
      r_id_reg<= 4'h0;
      r_error <= 1'b0;
      r_delay <= 4'h0;

      w_state <= W_IDLE;
      w_addr  <= 64'h0;
      w_size  <= 3'h0;
      w_id_reg<= 4'h0;
      w_error <= 1'b0;
      b_delay <= 4'h0;

      read_beats         <= 32'h0;
      write_beats        <= 32'h0;
      backpressure_cycles<= 32'h0;
    end
    else begin
      // ---------------- read address ----------------
      if (ar_valid && ar_ready) begin
        r_addr  <= ar_addr;
        r_len   <= ar_len;
        r_cnt   <= 8'h0;
        r_size  <= ar_size;
        r_id_reg<= ar_id;
        r_error <= !in_range(ar_addr);
        r_delay <= resp_delay_cfg[3:0];
        r_state <= R_DATA;
      end

      // ---------------- read data ----------------
      if (r_state == R_DATA) begin
        if (r_delay != 4'd0) begin
          r_delay <= r_delay - 4'd1;
        end
        else if (r_ready) begin
          read_beats <= read_beats + 32'd1;
          if (r_cnt == r_len) begin
            r_state <= R_IDLE;
          end
          else begin
            r_cnt   <= r_cnt + 8'd1;
            r_addr  <= r_addr + (64'd1 << r_size);
            r_delay <= resp_delay_cfg[3:0];
          end
        end
      end

      // ---------------- write address ----------------
      if (aw_valid && aw_ready) begin
        w_addr  <= aw_addr;
        w_size  <= aw_size;
        w_id_reg<= aw_id;
        w_error <= !in_range(aw_addr);
        w_state <= W_DATA;
      end

      // ---------------- write data ----------------
      if (w_state == W_DATA) begin
        if (w_valid && w_ready) begin
          write_beats <= write_beats + 32'd1;
          for (int b = 0; b < 8; b = b + 1) begin
            if (w_strb[b] && in_range(w_addr + b))
              mem[int'(w_addr - BASE) + b] <= w_data[8*b +: 8];
          end
          if (w_last) begin
            w_state <= W_RESP;
            b_delay <= resp_delay_cfg[3:0];
          end
          else begin
            w_addr <= w_addr + (64'd1 << w_size);
          end
        end
      end

      // ---------------- write response ----------------
      if (w_state == W_RESP) begin
        if (b_delay != 4'd0)
          b_delay <= b_delay - 4'd1;
        else if (b_ready)
          w_state <= W_IDLE;
      end

      // ---------------- backpressure statistics ----------------
      if ((aw_valid && !aw_ready) || (w_valid && !w_ready) ||
          (ar_valid && !ar_ready) || (r_valid && !r_ready) ||
          (b_valid && !b_ready))
        backpressure_cycles <= backpressure_cycles + 32'd1;
    end
  end

endmodule
