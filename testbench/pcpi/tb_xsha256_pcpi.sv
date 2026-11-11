`timescale 1ns / 1ps

module tb_xsha256_pcpi;

    logic        clk = 0;
    always #5 clk = ~clk;

    logic        resetn;
    logic        pcpi_valid;
    logic [31:0] pcpi_insn;
    logic [31:0] pcpi_rs1;
    logic [31:0] pcpi_rs2;
    logic        pcpi_wr;
    logic [31:0] pcpi_rd;
    logic        pcpi_wait;
    logic        pcpi_ready;

    xsha256_pcpi dut (
        .clk        (clk),
        .resetn     (resetn),
        .pcpi_valid (pcpi_valid),
        .pcpi_insn  (pcpi_insn),
        .pcpi_rs1   (pcpi_rs1),
        .pcpi_rs2   (pcpi_rs2),
        .pcpi_wr    (pcpi_wr),
        .pcpi_rd    (pcpi_rd),
        .pcpi_wait  (pcpi_wait),
        .pcpi_ready (pcpi_ready)
    );

    // Instruction generator function
    function automatic logic [31:0] encode_custom0(
        input logic [6:0] funct7,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd
    );
        return {funct7, rs2, rs1, funct3, rd, 7'b0001011};
    endfunction

    // Expected digest for "abc"
    logic [31:0] exp_abc [0:7] = '{
        32'hba7816bf, 32'h8f01cfea, 32'h414140de, 32'h5dae2223,
        32'hb00361a3, 32'h96177a9c, 32'hb410ff61, 32'hf20015ad
    };

    logic [31:0] block_abc [0:15] = '{
        32'h61626380, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000018
    };

    // Task to execute a PCPI instruction mimicking PicoRV32
    task execute_pcpi_insn(
        input logic [31:0] insn,
        input logic [31:0] rs1_val,
        input logic [31:0] rs2_val,
        output logic [31:0] rd_val,
        output logic wr_val
    );
    begin
        @(posedge clk);
        #1;
        pcpi_valid = 1'b1;
        pcpi_insn  = insn;
        pcpi_rs1   = rs1_val;
        pcpi_rs2   = rs2_val;

        // PicoRV32 waits until pcpi_ready is asserted
        while (!pcpi_ready) begin
            @(posedge clk);
            #1;
        end

        rd_val = pcpi_rd;
        wr_val = pcpi_wr;

        @(posedge clk);
        #1;
        pcpi_valid = 1'b0;
        pcpi_insn  = 32'h00000013; // nop
        pcpi_rs1   = 32'h00000000;
        pcpi_rs2   = 32'h00000000;
    end
    endtask

    integer i;
    int errors = 0;
    logic [31:0] ret_rd;
    logic ret_wr;

    initial begin
        $display("=== Starting PCPI XSHA256 Interface Testbench ===");
        resetn     = 0;
        pcpi_valid = 0;
        pcpi_insn  = 32'h00000013;
        pcpi_rs1   = 0;
        pcpi_rs2   = 0;

        repeat (5) @(posedge clk);
        #1;
        resetn = 1;
        repeat (2) @(posedge clk);

        // TEST 1: sha256.init
        $display("[PCPI TEST 1] sha256.init...");
        execute_pcpi_insn(
            encode_custom0(7'b0, 5'b0, 5'b0, 3'b000, 5'b0),
            32'h0, 32'h0, ret_rd, ret_wr
        );

        // TEST 2: sha256.load (16 words)
        $display("[PCPI TEST 2] sha256.load 16 words...");
        for (i = 0; i < 16; i = i + 1) begin
            execute_pcpi_insn(
                encode_custom0(7'b0, 5'b0, 5'd1, 3'b001, 5'b0),
                block_abc[i], 32'h0, ret_rd, ret_wr
            );
        end

        // TEST 3: sha256.round (64 rounds)
        $display("[PCPI TEST 3] sha256.round 64 single-step rounds...");
        for (i = 0; i < 64; i = i + 1) begin
            execute_pcpi_insn(
                encode_custom0(7'b0, 5'b0, 5'b0, 3'b010, 5'b0),
                32'h0, 32'h0, ret_rd, ret_wr
            );
        end

        // TEST 4: sha256.getstate (8 words)
        $display("[PCPI TEST 4] sha256.getstate readback...");
        for (i = 0; i < 8; i = i + 1) begin
            execute_pcpi_insn(
                encode_custom0(7'b0, 5'b0, 5'd1, 3'b011, 5'd1),
                i, 32'h0, ret_rd, ret_wr
            );
            $display("  State[%0d]: got %08x (exp %08x)", i, ret_rd, exp_abc[i]);
            if (ret_rd !== exp_abc[i] || ret_wr !== 1'b1) begin
                $display("  ERROR in PCPI getstate[%0d]", i);
                errors++;
            end
        end

        // TEST 5: sha256.compress (autonomous multi-cycle)
        $display("[PCPI TEST 5] sha256.compress autonomous block compression...");
        // Re-init
        execute_pcpi_insn(
            encode_custom0(7'b0, 5'b0, 5'b0, 3'b000, 5'b0),
            32'h0, 32'h0, ret_rd, ret_wr
        );
        // Load words
        for (i = 0; i < 16; i = i + 1) begin
            execute_pcpi_insn(
                encode_custom0(7'b0, 5'b0, 5'd1, 3'b001, 5'b0),
                block_abc[i], 32'h0, ret_rd, ret_wr
            );
        end
        // Issue compress
        execute_pcpi_insn(
            encode_custom0(7'b0, 5'b0, 5'b0, 3'b100, 5'b0),
            32'h0, 32'h0, ret_rd, ret_wr
        );

        // Verify getstate
        for (i = 0; i < 8; i = i + 1) begin
            execute_pcpi_insn(
                encode_custom0(7'b0, 5'b0, 5'd1, 3'b011, 5'd1),
                i, 32'h0, ret_rd, ret_wr
            );
            $display("  Auto State[%0d]: got %08x (exp %08x)", i, ret_rd, exp_abc[i]);
            if (ret_rd !== exp_abc[i] || ret_wr !== 1'b1) begin
                $display("  ERROR in auto PCPI getstate[%0d]", i);
                errors++;
            end
        end

        if (errors == 0) begin
            $display("=== ALL PCPI XSHA256 TESTS PASSED! ===");
        end else begin
            $display("=== PCPI TESTS FAILED WITH %0d ERRORS ===", errors);
        end

        $finish;
    end

endmodule

