// Smoke test: reset gpu_top, check that every output is idle and that an APB
// read completes. Proves the build and simulation flow works end to end.
module tb_smoke;
  import gpu_pkg::*;

  logic clk = 1'b0;
  logic rst_n = 1'b0;

  logic psel = 1'b0, penable = 1'b0, pwrite = 1'b0;
  logic [CSR_ADDR_W-1:0] paddr = '0;
  word_t pwdata = '0, prdata;
  logic pready, pslverr, irq;

  logic imem_req_valid, dmem_req_valid, dmem_req_write;
  word_t imem_req_addr, dmem_req_addr, dmem_req_wdata;

  int errors = 0;

  always #10 clk = ~clk;  // 50 MHz

  gpu_top dut (
      .clk,
      .rst_n,
      .psel,
      .penable,
      .pwrite,
      .paddr,
      .pwdata,
      .prdata,
      .pready,
      .pslverr,
      .irq,
      .imem_req_valid,
      .imem_req_ready(1'b1),
      .imem_req_addr,
      .imem_rsp_valid(1'b0),
      .imem_rsp_data ('0),
      .dmem_req_valid,
      .dmem_req_ready(1'b1),
      .dmem_req_write,
      .dmem_req_addr,
      .dmem_req_wdata,
      .dmem_rsp_valid(1'b0),
      .dmem_rsp_rdata('0)
  );

  task automatic check(input bit cond, input string msg);
    if (!cond) begin
      $display("ERROR: %s", msg);
      errors++;
    end
  endtask

  // Inputs are driven on the falling edge so they are stable at the rising
  // edge where the DUT samples them (no race between testbench and DUT).
  task automatic apb_read(input logic [CSR_ADDR_W-1:0] addr, output word_t data);
    @(negedge clk);  // setup phase
    psel    = 1'b1;
    penable = 1'b0;
    pwrite  = 1'b0;
    paddr   = addr;
    @(negedge clk);  // access phase
    penable = 1'b1;
    // The transfer ends at the rising edge where pready is 1. Time out so a
    // hang is reported, not silent.
    for (int i = 0; i < 16; i++) begin
      @(posedge clk);
      if (pready) break;
      if (i == 15) check(1'b0, "APB read timed out");
    end
    data = prdata;
    @(negedge clk);
    psel    = 1'b0;
    penable = 1'b0;
  endtask

  initial begin
    word_t rdata;
    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    repeat (3) @(posedge clk);
    check(dut.rst_n_sync === 1'b1, "internal reset not released after 2 clocks");

    check(imem_req_valid === 1'b0, "imem_req_valid not idle");
    check(dmem_req_valid === 1'b0, "dmem_req_valid not idle");
    check(irq === 1'b0, "irq not idle");
    apb_read(CSR_ID, rdata);  // only checks the handshake; CSRs come later

    if (errors == 0) $display("PASS: tb_smoke");
    else $display("FAIL: tb_smoke (%0d errors)", errors);
    $finish;
  end
endmodule : tb_smoke
