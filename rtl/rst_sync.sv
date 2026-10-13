// Reset synchronizer (04_interfaces.md, "Reset").
// Asserts rst_n_sync immediately when rst_n_async goes low, and releases it
// on the second rising clk edge after rst_n_async goes high, so no flop sees
// reset release close to its clock edge.
module rst_sync (
    input  logic clk,
    input  logic rst_n_async,
    output logic rst_n_sync
);

  logic [1:0] sync_q;

  always_ff @(posedge clk or negedge rst_n_async) begin
    if (!rst_n_async) begin
      sync_q <= 2'b00;
    end else begin
      sync_q <= {sync_q[0], 1'b1};
    end
  end

  assign rst_n_sync = sync_q[1];

endmodule : rst_sync
