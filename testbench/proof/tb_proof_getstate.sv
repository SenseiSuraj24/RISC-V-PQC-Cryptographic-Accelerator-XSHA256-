// =============================================================================
// PROOF TESTBENCH 4: sha256.getstate (funct3=011)
// =============================================================================
// Verifies that sha256.getstate correctly reads back each of the 8 hash state
// registers H0..H7 by index (rs1[2:0]) and returns the value via rd.
//
// PROOF STRATEGY:
//   1. Run SHA-256("abc") to get a known digest in H0..H7.
//   2. Read each register index 0..7 via sha256.getstate.
//   3. Verify every read matches the known NIST digest word exactly.
//   4. Test boundary: read index 7 (last), verify no wrap-around or aliasing.
//   5. Test isolation: read same index twice, both reads must return same value.
// =============================================================================
`timescale 1ns / 1ps

module tb_proof_getstate;

    logic clk = 0;
    always #5 clk = ~clk;

    logic        resetn;
    logic        cmd_init, cmd_load, cmd_round, cmd_compress;
    logic [31:0] load_data;
    logic [2:0]  state_idx;
    logic [31:0] state_out;
    logic [5:0]  current_round;
    logic        busy, done;

    sha256_core dut (
        .clk(clk), .resetn(resetn),
        .cmd_init(cmd_init), .cmd_load(cmd_load), .load_data(load_data),
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

    // Expected SHA-256("abc") digest — NIST FIPS 180-4 §B.1
    logic [31:0] exp_abc [0:7] = '{
        32'hba7816bf, // H0
        32'h8f01cfea, // H1
        32'h414140de, // H2
        32'h5dae2223, // H3
        32'hb00361a3, // H4
        32'h96177a9c, // H5
        32'hb410ff61, // H6
        32'hf20015ad  // H7
    };

    // Also test SHA-256("") — different known state
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
    logic [31:0] read_cache [0:7];

    task automatic compute_sha(input logic [31:0] blk[0:15]);
        cmd_init = 1; @(posedge clk); #1; cmd_init = 0;
        for (int i = 0; i < 16; i++) begin
            cmd_load = 1; load_data = blk[i]; @(posedge clk); #1;
        end
        cmd_load = 0;
        cmd_compress = 1; @(posedge clk); #1; cmd_compress = 0;
        wait(done == 1'b1); @(posedge clk); #1;
    endtask

    initial begin
        $display("=================================================================");
        $display("PROOF: sha256.getstate — Hash State Readback Verification");
        $display("=================================================================");

        resetn = 0; cmd_init = 0; cmd_load = 0;
        cmd_round = 0; cmd_compress = 0; load_data = 0; state_idx = 0;
        repeat(5) @(posedge clk); #1;
        resetn = 1;
        repeat(2) @(posedge clk); #1;

        // --- TEST 1: Read all 8 registers after SHA-256("abc") ---
        $display("\n[TEST 1] SHA-256('abc') — read H0..H7 via sha256.getstate:");
        compute_sha(block_abc);

        for (int i = 0; i < 8; i++) begin
            state_idx = i[2:0]; #1;    // sha256.getstate(i) → state_out
            read_cache[i] = state_out;
            if (state_out !== exp_abc[i]) begin
                $display("  [FAIL] getstate(%0d): got %08h, expected %08h", i, state_out, exp_abc[i]);
                errors++;
            end else
                $display("  [OK]   getstate(%0d) = %08h (H%0d correct)", i, state_out, i);
        end

        // --- TEST 2: Read same registers again (idempotency — read doesn't destroy state) ---
        $display("\n[TEST 2] Idempotency check — read H0..H7 again, must match first read:");
        for (int i = 0; i < 8; i++) begin
            state_idx = i[2:0]; #1;
            if (state_out !== read_cache[i]) begin
                $display("  [FAIL] Second read getstate(%0d): got %08h, first was %08h", i, state_out, read_cache[i]);
                errors++;
            end else
                $display("  [OK]   getstate(%0d) = %08h (unchanged, read is non-destructive)", i, state_out);
        end

        // --- TEST 3: Different vector — SHA-256("") to prove index isolation ---
        $display("\n[TEST 3] SHA-256('') — verify no register aliasing:");
        compute_sha(block_empty);

        for (int i = 0; i < 8; i++) begin
            state_idx = i[2:0]; #1;
            if (state_out !== exp_empty[i]) begin
                $display("  [FAIL] getstate(%0d) after SHA-256(''): got %08h, expected %08h", i, state_out, exp_empty[i]);
                errors++;
            end else
                $display("  [OK]   getstate(%0d) = %08h (correct, no aliasing)", i, state_out);
        end

        // --- TEST 4: Reverse index order — verify full mux coverage ---
        $display("\n[TEST 4] Reverse read order (7→0) — mux coverage:");
        compute_sha(block_abc);
        for (int i = 7; i >= 0; i--) begin
            state_idx = i[2:0]; #1;
            if (state_out !== exp_abc[i]) begin
                $display("  [FAIL] Reverse getstate(%0d): got %08h, expected %08h", i, state_out, exp_abc[i]);
                errors++;
            end else
                $display("  [OK]   getstate(%0d) = %08h (mux[%0d] correct)", i, state_out, i);
        end

        $display("\n=================================================================");
        if (errors == 0)
            $display("PROOF RESULT: sha256.getstate PASSED — All 8 registers readable, non-destructive");
        else
            $display("PROOF RESULT: sha256.getstate FAILED with %0d errors", errors);
        $display("=================================================================");
        $finish;
    end

endmodule
