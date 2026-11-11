`timescale 1ns / 1ps

module sha256_core (
    input  logic        clk,
    input  logic        resetn,

    // Control commands
    input  logic        cmd_init,
    input  logic        cmd_load,
    input  logic [31:0] load_data,
    input  logic        cmd_round,
    input  logic        cmd_compress,

    // Readback interface
    input  logic [2:0]  state_idx,
    output logic [31:0] state_out,

    // Status outputs
    output logic [5:0]  current_round,
    output logic        busy,
    output logic        done
);

    `include "sha256_funcs.vh"

    // Hash state registers (accumulators)
    logic [31:0] h0, h1, h2, h3, h4, h5, h6, h7;

    // Working state registers
    logic [31:0] a, b, c, d, e, f, g, h;

    // Next round values from round datapath
    logic [31:0] next_a, next_b, next_c, next_d;
    logic [31:0] next_e, next_f, next_g, next_h;

    // Round constant and current schedule word
    logic [31:0] k_cur;
    logic [31:0] w_cur;

    // Control & indexing
    logic [5:0]  round_ctr;
    logic [3:0]  load_count;
    logic        auto_compress;

    assign current_round = round_ctr;
    assign busy = auto_compress;

    // Instantiate round constants
    sha256_constants u_constants (
        .round_idx (round_ctr),
        .k_out     (k_cur)
    );

    // Instantiate schedule generator
    logic sched_advance;
    assign sched_advance = cmd_round || auto_compress;

    sha256_schedule u_schedule (
        .clk           (clk),
        .resetn        (resetn),
        .init          (cmd_init),
        .load_en       (cmd_load),
        .load_word     (load_data),
        .advance_round (sched_advance),
        .round_idx     (round_ctr),
        .load_count    (load_count),
        .w_out         (w_cur)
    );

    // Instantiate round datapath
    sha256_round u_round (
        .a      (a),
        .b      (b),
        .c      (c),
        .d      (d),
        .e      (e),
        .f      (f),
        .g      (g),
        .h      (h),
        .w      (w_cur),
        .k      (k_cur),
        .next_a (next_a),
        .next_b (next_b),
        .next_c (next_c),
        .next_d (next_d),
        .next_e (next_e),
        .next_f (next_f),
        .next_g (next_g),
        .next_h (next_h)
    );

    // Readback multiplexer (returns accumulated hash state)
    always_comb begin
        case (state_idx)
            3'd0: state_out = h0;
            3'd1: state_out = h1;
            3'd2: state_out = h2;
            3'd3: state_out = h3;
            3'd4: state_out = h4;
            3'd5: state_out = h5;
            3'd6: state_out = h6;
            3'd7: state_out = h7;
            default: state_out = 32'h00000000;
        endcase
    end

    // Sequential state and control logic
    always_ff @(posedge clk) begin
        if (!resetn) begin
            h0 <= SHA256_H0;
            h1 <= SHA256_H1;
            h2 <= SHA256_H2;
            h3 <= SHA256_H3;
            h4 <= SHA256_H4;
            h5 <= SHA256_H5;
            h6 <= SHA256_H6;
            h7 <= SHA256_H7;

            a <= SHA256_H0;
            b <= SHA256_H1;
            c <= SHA256_H2;
            d <= SHA256_H3;
            e <= SHA256_H4;
            f <= SHA256_H5;
            g <= SHA256_H6;
            h <= SHA256_H7;

            round_ctr     <= 6'd0;
            auto_compress <= 1'b0;
            done          <= 1'b0;
        end else begin
            done <= 1'b0;

            if (cmd_init) begin
                h0 <= SHA256_H0;
                h1 <= SHA256_H1;
                h2 <= SHA256_H2;
                h3 <= SHA256_H3;
                h4 <= SHA256_H4;
                h5 <= SHA256_H5;
                h6 <= SHA256_H6;
                h7 <= SHA256_H7;

                a <= SHA256_H0;
                b <= SHA256_H1;
                c <= SHA256_H2;
                d <= SHA256_H3;
                e <= SHA256_H4;
                f <= SHA256_H5;
                g <= SHA256_H6;
                h <= SHA256_H7;

                round_ctr     <= 6'd0;
                auto_compress <= 1'b0;
            end else if (cmd_load) begin
                // When starting a new block (first word loaded and round_ctr == 0),
                // copy accumulator state into working registers
                if (load_count == 4'd0 && round_ctr == 6'd0) begin
                    a <= h0;
                    b <= h1;
                    c <= h2;
                    d <= h3;
                    e <= h4;
                    f <= h5;
                    g <= h6;
                    h <= h7;
                end
            end else if (cmd_compress) begin
                // Start autonomous 64-round block compression
                auto_compress <= 1'b1;
                round_ctr     <= 6'd0;
                a <= h0;
                b <= h1;
                c <= h2;
                d <= h3;
                e <= h4;
                f <= h5;
                g <= h6;
                h <= h7;
            end else if (auto_compress) begin
                // In autonomous compression, step round each cycle
                a <= next_a;
                b <= next_b;
                c <= next_c;
                d <= next_d;
                e <= next_e;
                f <= next_f;
                g <= next_g;
                h <= next_h;

                if (round_ctr == 6'd63) begin
                    // Final round: perform block state accumulation
                    h0 <= h0 + next_a;
                    h1 <= h1 + next_b;
                    h2 <= h2 + next_c;
                    h3 <= h3 + next_d;
                    h4 <= h4 + next_e;
                    h5 <= h5 + next_f;
                    h6 <= h6 + next_g;
                    h7 <= h7 + next_h;

                    round_ctr     <= 6'd0;
                    auto_compress <= 1'b0;
                    done          <= 1'b1;
                end else begin
                    round_ctr <= round_ctr + 6'd1;
                end
            end else if (cmd_round) begin
                // Single step round from CPU instruction
                a <= next_a;
                b <= next_b;
                c <= next_c;
                d <= next_d;
                e <= next_e;
                f <= next_f;
                g <= next_g;
                h <= next_h;

                if (round_ctr == 6'd63) begin
                    h0 <= h0 + next_a;
                    h1 <= h1 + next_b;
                    h2 <= h2 + next_c;
                    h3 <= h3 + next_d;
                    h4 <= h4 + next_e;
                    h5 <= h5 + next_f;
                    h6 <= h6 + next_g;
                    h7 <= h7 + next_h;

                    round_ctr <= 6'd0;
                    done      <= 1'b1;
                end else begin
                    round_ctr <= round_ctr + 6'd1;
                end
            end
        end
    end

endmodule
