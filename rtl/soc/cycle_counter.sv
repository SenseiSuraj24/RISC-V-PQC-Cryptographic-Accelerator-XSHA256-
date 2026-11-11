`timescale 1ns / 1ps

module cycle_counter (
    input  logic        clk,
    input  logic        resetn,
    output logic [63:0] cycles
);

    always_ff @(posedge clk) begin
        if (!resetn) begin
            cycles <= 64'd0;
        end else begin
            cycles <= cycles + 64'd1;
        end
    end

endmodule

