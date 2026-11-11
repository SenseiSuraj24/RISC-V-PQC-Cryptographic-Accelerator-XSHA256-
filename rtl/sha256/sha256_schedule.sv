`timescale 1ns / 1ps

module sha256_schedule (
    input  logic        clk,
    input  logic        resetn,
    input  logic        init,
    input  logic        load_en,
    input  logic [31:0] load_word,
    input  logic        advance_round,
    input  logic [5:0]  round_idx,
    output logic [3:0]  load_count,
    output logic [31:0] w_out
);

    `include "sha256_funcs.vh"

    logic [31:0] w_mem [0:15];
    logic [3:0]  load_ctr;

    assign load_count = load_ctr;

    wire [3:0] idx_m2  = (round_idx - 6'd2)  & 4'hf;
    wire [3:0] idx_m7  = (round_idx - 6'd7)  & 4'hf;
    wire [3:0] idx_m15 = (round_idx - 6'd15) & 4'hf;
    wire [3:0] idx_m16 = (round_idx - 6'd16) & 4'hf;

    wire [31:0] w_m2  = w_mem[idx_m2];
    wire [31:0] w_m7  = w_mem[idx_m7];
    wire [31:0] w_m15 = w_mem[idx_m15];
    wire [31:0] w_m16 = w_mem[idx_m16];

    wire [31:0] w_calc = `SIG1(w_m2) + w_m7 + `SIG0(w_m15) + w_m16;

    assign w_out = (round_idx < 6'd16) ? w_mem[round_idx[3:0]] : w_calc;

    integer i;
    always_ff @(posedge clk) begin
        if (!resetn || init) begin
            load_ctr <= 4'd0;
            for (i = 0; i < 16; i = i + 1) begin
                w_mem[i] <= 32'h00000000;
            end
        end else begin
            if (load_en) begin
                w_mem[load_ctr] <= load_word;
                load_ctr <= load_ctr + 4'd1;
            end
            if (advance_round && (round_idx >= 6'd16)) begin
                w_mem[round_idx[3:0]] <= w_calc;
            end
        end
    end

endmodule
