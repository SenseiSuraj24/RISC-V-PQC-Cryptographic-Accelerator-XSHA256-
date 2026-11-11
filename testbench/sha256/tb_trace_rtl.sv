`timescale 1ns / 1ps

module tb_trace_rtl;
    logic clk = 0;
    always #5 clk = ~clk;

    logic resetn, cmd_init, cmd_load, cmd_round, cmd_compress;
    logic [31:0] load_data;
    logic [2:0] state_idx;
    logic [31:0] state_out;
    logic [5:0] current_round;
    logic busy, done;

    sha256_core dut (
        .clk(clk), .resetn(resetn), .cmd_init(cmd_init),
        .cmd_load(cmd_load), .load_data(load_data),
        .cmd_round(cmd_round), .cmd_compress(cmd_compress),
        .state_idx(state_idx), .state_out(state_out),
        .current_round(current_round), .busy(busy), .done(done)
    );

    logic [31:0] block_abc [0:15] = '{
        32'h61626380, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000018
    };

    integer i;
    initial begin
        resetn = 0; cmd_init = 0; cmd_load = 0; cmd_round = 0; cmd_compress = 0;
        repeat (5) @(posedge clk);
        resetn = 1;
        @(posedge clk);

        cmd_init = 1; @(posedge clk); cmd_init = 0;

        for (i = 0; i < 16; i = i + 1) begin
            cmd_load = 1; load_data = block_abc[i];
            @(posedge clk);
        end
        cmd_load = 0;

        for (i = 0; i < 64; i = i + 1) begin
            $display("RTL Round %2d: W=%08x, A=%08x, E=%08x, K=%08x",
                     dut.round_ctr, dut.w_cur, dut.a, dut.e, dut.k_cur);
            cmd_round = 1;
            @(posedge clk);
        end
        cmd_round = 0;
        $display("RTL Final: H0=%08x, H1=%08x, H2=%08x, H3=%08x, H4=%08x, H5=%08x, H6=%08x, H7=%08x",
                 dut.h0, dut.h1, dut.h2, dut.h3, dut.h4, dut.h5, dut.h6, dut.h7);
        $finish;
    end
endmodule

