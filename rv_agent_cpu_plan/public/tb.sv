// RVA-01 public smoke test: fixed SimTop interface + 64 independent ADDIs.
//
// The CPU fetches the program from a 256 KiB AXI memory model at
// 0x8000_0000.  The stub DifftestInstrCommit checks that the first 64
// retired instructions are exactly
//   pc = 0x8000_0000 + 4*i, rd = (i%31)+1, wdata = i+1
// and that they retire in order.  ADDI must not issue data-memory requests.
//
// Build (Verilator 4.204, no --binary/--timing needed):
// Command: verilator --cc --exe --build -j 4 -Wno-fatal -Wno-WIDTH \
//     --top-module tb_rva01_smoke -o tb_smoke \
//     -Iprojects/<name>/vsrc \
//     rv_agent_cpu_plan/public/difftest_stub.sv \
//     rv_agent_cpu_plan/public/tb.sv \
//     rv_agent_cpu_plan/public/axi_mem_model.sv \
//     rv_agent_cpu_plan/public/tb_smoke_main.cpp \
//     $(find projects/<name>/vsrc \( -name '*.sv' -o -name '*.v' \) ! -name 'SimTop.v')
//
// Validated with projects/cpu_axi_diff_cache on 2026-11-17:
//   PUBLIC_PASS commits=64 cycles=248 read_beats=32 write_beats=0

`timescale 1ns/1ps

module tb_rva01_smoke(
  input logic clock,
  input logic reset
);

  logic [63:0] io_logCtrl_log_begin;
  logic [63:0] io_logCtrl_log_end;
  logic [63:0] io_logCtrl_log_level;
  logic        io_perfInfo_clean;
  logic        io_perfInfo_dump;

  logic        io_uart_out_valid;
  logic [ 7:0] io_uart_out_ch;
  logic        io_uart_in_valid;
  logic [ 7:0] io_uart_in_ch;

  logic        io_memAXI_0_aw_ready;
  logic        io_memAXI_0_aw_valid;
  logic [63:0] io_memAXI_0_aw_bits_addr;
  logic [ 2:0] io_memAXI_0_aw_bits_prot;
  logic [ 3:0] io_memAXI_0_aw_bits_id;
  logic        io_memAXI_0_aw_bits_user;
  logic [ 7:0] io_memAXI_0_aw_bits_len;
  logic [ 2:0] io_memAXI_0_aw_bits_size;
  logic [ 1:0] io_memAXI_0_aw_bits_burst;
  logic        io_memAXI_0_aw_bits_lock;
  logic [ 3:0] io_memAXI_0_aw_bits_cache;
  logic [ 3:0] io_memAXI_0_aw_bits_qos;

  logic        io_memAXI_0_w_ready;
  logic        io_memAXI_0_w_valid;
  logic [63:0] io_memAXI_0_w_bits_data [3:0];
  logic [ 7:0] io_memAXI_0_w_bits_strb;
  logic        io_memAXI_0_w_bits_last;

  logic        io_memAXI_0_b_ready;
  logic        io_memAXI_0_b_valid;
  logic [ 1:0] io_memAXI_0_b_bits_resp;
  logic [ 3:0] io_memAXI_0_b_bits_id;
  logic        io_memAXI_0_b_bits_user;

  logic        io_memAXI_0_ar_ready;
  logic        io_memAXI_0_ar_valid;
  logic [63:0] io_memAXI_0_ar_bits_addr;
  logic [ 2:0] io_memAXI_0_ar_bits_prot;
  logic [ 3:0] io_memAXI_0_ar_bits_id;
  logic        io_memAXI_0_ar_bits_user;
  logic [ 7:0] io_memAXI_0_ar_bits_len;
  logic [ 2:0] io_memAXI_0_ar_bits_size;
  logic [ 1:0] io_memAXI_0_ar_bits_burst;
  logic        io_memAXI_0_ar_bits_lock;
  logic [ 3:0] io_memAXI_0_ar_bits_cache;
  logic [ 3:0] io_memAXI_0_ar_bits_qos;

  logic        io_memAXI_0_r_ready;
  logic        io_memAXI_0_r_valid;
  logic [ 1:0] io_memAXI_0_r_bits_resp;
  logic [63:0] io_memAXI_0_r_bits_data [3:0];
  logic        io_memAXI_0_r_bits_last;
  logic [ 3:0] io_memAXI_0_r_bits_id;
  logic        io_memAXI_0_r_bits_user;

  wire  [63:0] bfm_r_data;
  wire  [31:0] bfm_read_beats;
  wire  [31:0] bfm_write_beats;
  wire  [31:0] bfm_backpressure_cycles;
  wire  [31:0] bfm_image_bytes;

  // The fixed DUT interface.  Do not add or remove ports here; this is the
  // interface contract of RVA-01.
  SimTop dut (.*);

  // ------------------------------------------------------------------
  // AXI memory model
  // ------------------------------------------------------------------
  axi_mem_model #(
    .MEM_BYTES  (256 * 1024),
    .BASE       (64'h0000_0000_8000_0000),
    .INIT_ADDI64(1'b1)
  ) bfm (
    .clock(clock),
    .reset(reset),

    .aw_ready       (io_memAXI_0_aw_ready),
    .aw_valid       (io_memAXI_0_aw_valid),
    .aw_addr        (io_memAXI_0_aw_bits_addr),
    .aw_prot        (io_memAXI_0_aw_bits_prot),
    .aw_id          (io_memAXI_0_aw_bits_id),
    .aw_user        (io_memAXI_0_aw_bits_user),
    .aw_len         (io_memAXI_0_aw_bits_len),
    .aw_size        (io_memAXI_0_aw_bits_size),
    .aw_burst       (io_memAXI_0_aw_bits_burst),
    .aw_lock        (io_memAXI_0_aw_bits_lock),
    .aw_cache       (io_memAXI_0_aw_bits_cache),
    .aw_qos         (io_memAXI_0_aw_bits_qos),

    .w_ready        (io_memAXI_0_w_ready),
    .w_valid        (io_memAXI_0_w_valid),
    .w_data         (io_memAXI_0_w_bits_data[0]),
    .w_strb         (io_memAXI_0_w_bits_strb),
    .w_last         (io_memAXI_0_w_bits_last),

    .b_ready        (io_memAXI_0_b_ready),
    .b_valid        (io_memAXI_0_b_valid),
    .b_resp         (io_memAXI_0_b_bits_resp),
    .b_id           (io_memAXI_0_b_bits_id),
    .b_user         (io_memAXI_0_b_bits_user),

    .ar_ready       (io_memAXI_0_ar_ready),
    .ar_valid       (io_memAXI_0_ar_valid),
    .ar_addr        (io_memAXI_0_ar_bits_addr),
    .ar_prot        (io_memAXI_0_ar_bits_prot),
    .ar_id          (io_memAXI_0_ar_bits_id),
    .ar_user        (io_memAXI_0_ar_bits_user),
    .ar_len         (io_memAXI_0_ar_bits_len),
    .ar_size        (io_memAXI_0_ar_bits_size),
    .ar_burst       (io_memAXI_0_ar_bits_burst),
    .ar_lock        (io_memAXI_0_ar_bits_lock),
    .ar_cache       (io_memAXI_0_ar_bits_cache),
    .ar_qos         (io_memAXI_0_ar_bits_qos),

    .r_ready        (io_memAXI_0_r_ready),
    .r_valid        (io_memAXI_0_r_valid),
    .r_resp         (io_memAXI_0_r_bits_resp),
    .r_data         (bfm_r_data),
    .r_last         (io_memAXI_0_r_bits_last),
    .r_id           (io_memAXI_0_r_bits_id),
    .r_user         (io_memAXI_0_r_bits_user),

    .read_beats          (bfm_read_beats),
    .write_beats         (bfm_write_beats),
    .backpressure_cycles (bfm_backpressure_cycles),
    .image_bytes         (bfm_image_bytes)
  );

  // Only lane 0 of the AXI data array is used by the reference DUT.
  assign io_memAXI_0_r_bits_data[0] = bfm_r_data;
  assign io_memAXI_0_r_bits_data[1] = 64'h0;
  assign io_memAXI_0_r_bits_data[2] = 64'h0;
  assign io_memAXI_0_r_bits_data[3] = 64'h0;

  // Unused framework inputs.
  assign io_logCtrl_log_begin = 64'h0;
  assign io_logCtrl_log_end   = 64'h0;
  assign io_logCtrl_log_level = 64'h0;
  assign io_perfInfo_clean    = 1'b0;
  assign io_perfInfo_dump     = 1'b0;
  assign io_uart_in_ch        = 8'h00;

  // ------------------------------------------------------------------
  // Scoreboard (clock/reset are driven by tb_smoke_main.cpp)
  // ------------------------------------------------------------------
  int cycle_count;

  initial begin
    cycle_count = 0;

    public_difftest_pkg::commit_count      = 0;
    public_difftest_pkg::trap_count        = 0;
    public_difftest_pkg::good_trap_count   = 0;
    public_difftest_pkg::bad_trap_count    = 0;
    public_difftest_pkg::check_addi64      = 1'b1;
    public_difftest_pkg::addi_base         = 64'h0000_0000_8000_0000;
    public_difftest_pkg::trace_en          = $test$plusargs("TRACE");
  end

  always @(posedge clock) begin
    if (reset) begin
      cycle_count <= 0;
    end
    else begin
      cycle_count <= cycle_count + 1;

      if (public_difftest_pkg::commit_count >= 64) begin
        if (public_difftest_pkg::trap_count != 0)
          $fatal(1, "PUBLIC_SMOKE unexpected trap count=%0d",
                 public_difftest_pkg::trap_count);
        if (bfm_write_beats != 32'h0)
          $fatal(1, "PUBLIC_SMOKE ADDI program issued %0d data writes",
                 bfm_write_beats);
        $display("PUBLIC_PASS commits=%0d cycles=%0d read_beats=%0d write_beats=%0d image_bytes=%0d bp=%0d",
                 public_difftest_pkg::commit_count, cycle_count,
                 bfm_read_beats, bfm_write_beats, bfm_image_bytes,
                 bfm_backpressure_cycles);
        $finish;
      end

      if (cycle_count > 20000)
        $fatal(1, "PUBLIC_SMOKE timeout commits=%0d traps=%0d cycles=%0d",
               public_difftest_pkg::commit_count,
               public_difftest_pkg::trap_count, cycle_count);
    end
  end

endmodule
