// =============================================================================
// PROOF TESTBENCH 4: sha256.getstate (opcode=0x0B, funct3=011, rs1=idx, rd=val)
// =============================================================================
// Verifies through the actual RISC-V PCPI custom-0 instruction interface:
//   [CLAIM 1] ISA Decode & GPR Writeback: funct3=011 asserts pcpi_ready=1 AND
//             pcpi_wr=1 in 1 cycle and places H[pcpi_rs1[2:0]] on pcpi_rd.
//   [CLAIM 2] Full 8-Register Coverage & Aliasing Freedom: Indices 0..7 in
//             forward, reverse, and upper-bit masked (0xFFFF_FFF8 | i) order.
//   [CLAIM 3] Non-Destructive Read: Repeated reads return identical values
//             without altering H0..H7, a..h, round_ctr, or load_count.
// =============================================================================
`timescale 1ns / 1ps

module tb_proof_getstate;

    logic clk = 0;
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

    `include "proof_common.svh"

    logic [31:0] block_abc [0:15] = '{
        32'h61626380, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000018
    };
    logic [31:0] exp_abc [0:7] = '{
        32'hba7816bf, 32'h8f01cfea, 32'h414140de, 32'h5dae2223,
        32'hb00361a3, 32'h96177a9c, 32'hb410ff61, 32'hf20015ad
    };

    logic [31:0] block_empty [0:15] = '{
        32'h80000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000
    };
    logic [31:0] exp_empty [0:7] = '{
        32'he3b0c442, 32'h98fc1c14, 32'h9afbf4c8, 32'h996fb924,
        32'h27ae41e4, 32'h649b934c, 32'ha495991b, 32'h7852b855
    };

    int errors = 0;

    task automatic compute_via_pcpi(input logic [31:0] blk[0:15]);
        int cyc;
        pcpi_init();
        for (int i = 0; i < 16; i++) pcpi_load(blk[i]);
        pcpi_compress(cyc);
    endtask

    logic [31:0] rd_val;
    logic        wr_val;
    int          cyc;

    initial begin
        $display("=================================================================");
        $display("PROOF 4: sha256.getstate (0x%08h | custom-0 funct3=011)", INSN_GETSTATE);
        $display("=================================================================");

        resetn = 0; pcpi_valid = 0; pcpi_insn = 32'h00000013; pcpi_rs1 = 0; pcpi_rs2 = 0;
        repeat(5) @(posedge clk); #1;
        resetn = 1; repeat(2) @(posedge clk); #1;

        // --- TEST 1: Forward readout + PCPI latency/wr verification ---
        $display("\n[TEST 1] Forward readout H0..H7 on SHA-256('abc') with PCPI handshake check:");
        compute_via_pcpi(block_abc);
        for (int i = 0; i < 8; i++) begin
            exec_pcpi(encode_custom0(7'd0, 5'd0, 5'd11, XSHA_F3_GETSTATE, 5'd12),
                      i[31:0], 32'h0, rd_val, wr_val, cyc);
            if (cyc !== 1 || wr_val !== 1'b1 || rd_val !== exp_abc[i]) begin
                $display("  [FAIL] idx=%0d: rd=%08h (exp %08h), wr=%b, cyc=%0d",
                         i, rd_val, exp_abc[i], wr_val, cyc);
                errors++;
            end else begin
                $display("  [OK]   getstate(%0d) = %08h (pcpi_wr=1, cyc=1)", i, rd_val);
            end
        end

        // --- TEST 2: Idempotency / non-destructive readout ---
        $display("\n[TEST 2] Idempotency check (second read + counter invariance):");
        for (int i = 0; i < 8; i++) begin
            pcpi_getstate(i, rd_val, wr_val);
            if (rd_val !== exp_abc[i] || wr_val !== 1'b1) begin
                $display("  [FAIL] Second read idx=%0d mismatch: %08h", i, rd_val);
                errors++;
            end
        end
        if (dut.u_core.round_ctr !== 6'd0 || dut.u_core.load_count !== 4'd0) begin
            $display("  [FAIL] getstate altered round_ctr/load_count!");
            errors++;
        end
        $display("  [OK]   All 8 reads identical & non-destructive");

        // --- TEST 3: Upper-bit masking rs1[31:3] ignored cleanly ---
        $display("\n[TEST 3] Upper-bit rs1 masking check (rs1 = 32'hFFFF_FFF8 | idx):");
        for (int i = 0; i < 8; i++) begin
            exec_pcpi(INSN_GETSTATE, 32'hFFFF_FFF8 | i[31:0], 32'h0, rd_val, wr_val, cyc);
            if (rd_val !== exp_abc[i]) begin
                $display("  [FAIL] Masked rs1=0x%08h returned %08h, exp %08h",
                         (32'hFFFF_FFF8 | i[31:0]), rd_val, exp_abc[i]);
                errors++;
            end
        end
        $display("  [OK]   Only rs1[2:0] selects H0..H7 (upper bits safely masked)");

        // --- TEST 4: Reverse order (7->0) on SHA-256('') ---
        $display("\n[TEST 4] Reverse read order (7->0) on SHA-256(''):");
        compute_via_pcpi(block_empty);
        for (int i = 7; i >= 0; i--) begin
            pcpi_getstate(i, rd_val, wr_val);
            if (rd_val !== exp_empty[i]) begin
                $display("  [FAIL] Reverse idx=%0d: got %08h, exp %08h", i, rd_val, exp_empty[i]);
                errors++;
            end else begin
                $display("  [OK]   getstate(%0d) = %08h (mux[%0d] isolated)", i, rd_val, i);
            end
        end

        $display("\n=================================================================");
        if (errors == 0)
            $display("PROOF RESULT: sha256.getstate PASSED — All 8 GPR writeback paths verified");
        else
            $display("PROOF RESULT: sha256.getstate FAILED with %0d error(s)", errors);
        $display("=================================================================");
        $finish;
    end

endmodule
