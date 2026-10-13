// MiniTile GPU - top level (04_interfaces.md).
// Iteration 2 skeleton: full port list and reset synchronizer only.
// All outputs are tied to their idle values until the blocks are implemented.
module gpu_top
  import gpu_pkg::*;
(
    input logic clk,
    input logic rst_n,

    // APB slave (CSR access)
    input  logic                   psel,
    input  logic                   penable,
    input  logic                   pwrite,
    input  logic  [CSR_ADDR_W-1:0] paddr,
    input  word_t                  pwdata,
    output word_t                  prdata,
    output logic                   pready,
    output logic                   pslverr,
    output logic                   irq,

    // Instruction fetch port
    output logic  imem_req_valid,
    input  logic  imem_req_ready,
    output word_t imem_req_addr,
    input  logic  imem_rsp_valid,
    input  word_t imem_rsp_data,

    // Data port
    output logic  dmem_req_valid,
    input  logic  dmem_req_ready,
    output logic  dmem_req_write,
    output word_t dmem_req_addr,
    output word_t dmem_req_wdata,
    input  logic  dmem_rsp_valid,
    input  word_t dmem_rsp_rdata
);

  logic rst_n_sync;

  rst_sync u_rst_sync (
      .clk        (clk),
      .rst_n_async(rst_n),
      .rst_n_sync (rst_n_sync)
  );

  // Idle outputs until the CSR block, dispatcher and shader core exist.
  assign prdata         = '0;
  assign pready         = 1'b1;
  assign pslverr        = 1'b0;
  assign irq            = 1'b0;

  assign imem_req_valid = 1'b0;
  assign imem_req_addr  = '0;

  assign dmem_req_valid = 1'b0;
  assign dmem_req_write = 1'b0;
  assign dmem_req_addr  = '0;
  assign dmem_req_wdata = '0;

  // Inputs not used yet. Remove from this list as blocks are implemented.
  // (Waived for Verilator in lint/waivers.vlt.)
  logic unused_inputs;
  assign unused_inputs = ^{rst_n_sync, psel, penable, pwrite, paddr, pwdata,
                           imem_req_ready, imem_rsp_valid, imem_rsp_data,
                           dmem_req_ready, dmem_rsp_valid, dmem_rsp_rdata};

endmodule : gpu_top
