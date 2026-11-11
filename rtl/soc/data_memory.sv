`timescale 1ns / 1ps

module data_memory #(
    parameter MEM_SIZE_WORDS = 16384 // 64 KB
) (
    input  logic        clk,
    input  logic        valid,
    input  logic [3:0]  wstrb,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    output logic        ready
);

    logic [31:0] mem [0:MEM_SIZE_WORDS-1];
    wire [13:0] word_addr = addr[15:2];

    always_ff @(posedge clk) begin
        ready <= valid && !ready;
        if (valid) begin
            if (wstrb[0]) mem[word_addr][ 7: 0] <= wdata[ 7: 0];
            if (wstrb[1]) mem[word_addr][15: 8] <= wdata[15: 8];
            if (wstrb[2]) mem[word_addr][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[word_addr][31:24] <= wdata[31:24];
            rdata <= mem[word_addr];
        end
    end

endmodule

