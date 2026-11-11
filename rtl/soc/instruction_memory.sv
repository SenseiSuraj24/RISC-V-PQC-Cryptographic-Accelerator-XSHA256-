`timescale 1ns / 1ps

module instruction_memory #(
    parameter MEM_SIZE_WORDS = 16384 // 64 KB
) (
    input  logic        clk,
    input  logic        valid,
    input  logic [31:0] addr,
    output logic [31:0] rdata,
    output logic        ready
);

    logic [31:0] mem [0:MEM_SIZE_WORDS-1];
    wire [13:0] word_addr = addr[15:2];

    always_ff @(posedge clk) begin
        ready <= valid && !ready;
        if (valid) begin
            rdata <= mem[word_addr];
        end
    end

endmodule

