// =============================================================================
// PROOF TESTBENCH 5: sha256.compress (funct3=100)
// =============================================================================
// Verifies that sha256.compress executes ALL 64 compression rounds autonomously
// and produces an identical digest to 64 sequential sha256.round instructions.
//
// PROOF STRATEGY:
//   Level 1 — Latency proof: compress asserts done exactly 64 cycles after firing.
//   Level 2 — Digest equivalence: SHA-256('abc') via compress == via 64x round.
//   Level 3 — Multi-vector: SHA-256(''), SHA-256('abc') both pass.
//   Level 4 — Multi-block chaining: 2-block message hashed with compress.
//   Level 5 — busy/wait signalling: busy=1 during, busy=0 after.
//
// NOTE: Both paths (compress and 64x round) run on the SAME single DUT instance
//       sequentially to avoid parallel-DUT synchronisation issues in iverilog.
// =============================================================================
`timescale 1ns / 1ps

module tb_proof_compress;

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

    // NIST Test Vectors
    // "abc"
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

    // empty string ""
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

    // 2-block message "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
    logic [31:0] block_long1 [0:15] = '{
        32'h61626364, 32'h62636465, 32'h63646566, 32'h64656667,
        32'h65666768, 32'h66676869, 32'h6768696A, 32'h68696A6B,
        32'h696A6B6C, 32'h6A6B6C6D, 32'h6B6C6D6E, 32'h6C6D6E6F,
        32'h6D6E6F70, 32'h6E6F7071, 32'h80000000, 32'h00000000
    };
    logic [31:0] block_long2 [0:15] = '{
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h000001C0
    };
    logic [31:0] exp_long [0:7] = '{
        32'h248d6a61, 32'hd20638b8, 32'he5c02693, 32'h0c3e6039,
        32'ha33ce459, 32'h64ff2167, 32'hf6ecedd4, 32'h19db06c1
    };

    // Storage for reference digest (computed via rounds)
    logic [31:0] ref_digest [0:7];
    int errors = 0;
    int cycle_cnt;

    // Run sha256.compress on a block, store result in compress_digest
    task automatic run_compress(input logic [31:0] blk[0:15], output logic [31:0] digest[0:7]);
        integer i;
        cmd_init = 1; @(posedge clk); #1; cmd_init = 0;
        for (i = 0; i < 16; i++) begin
            cmd_load = 1; load_data = blk[i]; @(posedge clk); #1;
        end
        cmd_load = 0;
        cmd_compress = 1; @(posedge clk); #1; cmd_compress = 0;
        // Wait for done (up to 100 cycles)
        begin : wait_done
            integer w;
            for (w = 0; w < 100; w++) begin
                @(posedge clk); #1;
                if (done) disable wait_done;
            end
        end
        @(posedge clk); #1;
        for (i = 0; i < 8; i++) begin
            state_idx = i[2:0]; #1;
            digest[i] = state_out;
        end
    endtask

    // Run 64x sha256.round on a block, store result in round_digest
    task automatic run_rounds(input logic [31:0] blk[0:15], output logic [31:0] digest[0:7]);
        integer i;
        cmd_init = 1; @(posedge clk); #1; cmd_init = 0;
        for (i = 0; i < 16; i++) begin
            cmd_load = 1; load_data = blk[i]; @(posedge clk); #1;
        end
        cmd_load = 0;
        for (i = 0; i < 64; i++) begin
            cmd_round = 1; @(posedge clk); #1;
        end
        cmd_round = 0;
        @(posedge clk); #1;
        for (i = 0; i < 8; i++) begin
            state_idx = i[2:0]; #1;
            digest[i] = state_out;
        end
    endtask

    logic [31:0] comp_dig [0:7];
    logic [31:0] rnd_dig  [0:7];

    initial begin
        $display("=================================================================");
        $display("PROOF: sha256.compress — Autonomous 64-round Compression");
        $display("CLAIM: sha256.compress == 64x sha256.round (FIPS 180-4 §6.2.2)");
        $display("=================================================================");

        resetn = 0; cmd_init = 0; cmd_load = 0;
        cmd_round = 0; cmd_compress = 0; load_data = 0; state_idx = 0;
        repeat(5) @(posedge clk); #1;
        resetn = 1; repeat(2) @(posedge clk); #1;

        // ===== LEVEL 1: Latency = exactly 64 cycles =====
        $display("\n[LEVEL 1] Latency proof: sha256.compress must assert done in 64 cycles...");
        cmd_init = 1; @(posedge clk); #1; cmd_init = 0;
        for (int i = 0; i < 16; i++) begin
            cmd_load = 1; load_data = block_abc[i]; @(posedge clk); #1;
        end
        cmd_load = 0;

        cycle_cnt = 0;
        cmd_compress = 1; @(posedge clk); #1; cmd_compress = 0;
        begin : lat_wait
            for (int w = 0; w < 100; w++) begin
                if (done) disable lat_wait;
                @(posedge clk); #1;
                cycle_cnt++;
            end
        end
        $display("  done asserted after %0d post-fire cycles (expected 64)", cycle_cnt);
        if (cycle_cnt !== 64) begin
            $display("  [FAIL] Wrong latency: %0d != 64", cycle_cnt);
            errors++;
        end else
            $display("  [OK]   Latency = 64 cycles exactly");
        @(posedge clk); #1; // let done pulse settle

        // ===== LEVEL 2: compress == 64x round for 'abc' =====
        $display("\n[LEVEL 2] Equivalence: compress vs 64x round for SHA-256('abc')...");
        run_compress(block_abc, comp_dig);
        run_rounds  (block_abc, rnd_dig);

        for (int i = 0; i < 8; i++) begin
            if (comp_dig[i] !== exp_abc[i]) begin
                $display("  [FAIL] compress H%0d: got %08h, expected %08h", i, comp_dig[i], exp_abc[i]);
                errors++;
            end else if (comp_dig[i] !== rnd_dig[i]) begin
                $display("  [FAIL] EQUIV H%0d: compress=%08h != rounds=%08h", i, comp_dig[i], rnd_dig[i]);
                errors++;
            end else
                $display("  [OK]   H%0d = %08h (compress == rounds == NIST)", i, comp_dig[i]);
        end

        // ===== LEVEL 3: compress == 64x round for '' =====
        $display("\n[LEVEL 3] Equivalence: compress vs 64x round for SHA-256('')...");
        run_compress(block_empty, comp_dig);
        run_rounds  (block_empty, rnd_dig);

        for (int i = 0; i < 8; i++) begin
            if (comp_dig[i] !== exp_empty[i]) begin
                $display("  [FAIL] compress H%0d: got %08h, expected %08h", i, comp_dig[i], exp_empty[i]);
                errors++;
            end else if (comp_dig[i] !== rnd_dig[i]) begin
                $display("  [FAIL] EQUIV H%0d: compress=%08h != rounds=%08h", i, comp_dig[i], rnd_dig[i]);
                errors++;
            end else
                $display("  [OK]   H%0d = %08h (compress == rounds == NIST)", i, comp_dig[i]);
        end

        // ===== LEVEL 4: 2-block chaining with compress =====
        $display("\n[LEVEL 4] Multi-block chaining: 2-block NIST message via compress...");
        // Block 1
        cmd_init = 1; @(posedge clk); #1; cmd_init = 0;
        for (int i = 0; i < 16; i++) begin
            cmd_load = 1; load_data = block_long1[i]; @(posedge clk); #1;
        end
        cmd_load = 0;
        cmd_compress = 1; @(posedge clk); #1; cmd_compress = 0;
        begin : c4a
            for (int w = 0; w < 100; w++) begin
                if (done) disable c4a;
                @(posedge clk); #1;
            end
        end
        @(posedge clk); #1;
        $display("  Block 1 compress done. Chaining into block 2 (no init)...");

        // Block 2 — no init! state chains from block 1
        for (int i = 0; i < 16; i++) begin
            cmd_load = 1; load_data = block_long2[i]; @(posedge clk); #1;
        end
        cmd_load = 0;
        cmd_compress = 1; @(posedge clk); #1; cmd_compress = 0;
        begin : c4b
            for (int w = 0; w < 100; w++) begin
                if (done) disable c4b;
                @(posedge clk); #1;
            end
        end
        @(posedge clk); #1;

        for (int i = 0; i < 8; i++) begin
            state_idx = i[2:0]; #1;
            if (state_out !== exp_long[i]) begin
                $display("  [FAIL] 2-block H%0d: got %08h, expected %08h", i, state_out, exp_long[i]);
                errors++;
            end else
                $display("  [OK]   2-block H%0d = %08h (NIST correct)", i, state_out);
        end

        // ===== LEVEL 5: busy=1 during compress, busy=0 after =====
        $display("\n[LEVEL 5] busy/wait signal verification...");
        cmd_init = 1; @(posedge clk); #1; cmd_init = 0;
        for (int i = 0; i < 16; i++) begin
            cmd_load = 1; load_data = block_abc[i]; @(posedge clk); #1;
        end
        cmd_load = 0;

        cmd_compress = 1; @(posedge clk); #1; cmd_compress = 0;
        // Immediately after firing, busy should be asserted
        if (busy !== 1'b1) begin
            $display("  [FAIL] busy not asserted after cmd_compress! CPU would not stall.");
            errors++;
        end else
            $display("  [OK]   busy = 1 (pcpi_wait asserted → CPU stalled)");

        // Wait for completion
        begin : c5
            for (int w = 0; w < 100; w++) begin
                if (done) disable c5;
                @(posedge clk); #1;
            end
        end
        @(posedge clk); #1;

        if (busy !== 1'b0) begin
            $display("  [FAIL] busy still 1 after done! CPU never released.");
            errors++;
        end else
            $display("  [OK]   busy = 0 after done (pcpi_wait deasserted → CPU resumes)");

        $display("\n=================================================================");
        if (errors == 0) begin
            $display("PROOF RESULT: sha256.compress PASSED");
            $display("  - Latency: exactly 64 cycles");
            $display("  - Digest: matches 64x sha256.round (equivalent execution)");
            $display("  - 2 single-block NIST vectors verified");
            $display("  - 2-block chaining verified (248d6a61...)");
            $display("  - busy/wait signalling correct");
        end else
            $display("PROOF RESULT: sha256.compress FAILED with %0d errors", errors);
        $display("=================================================================");
        $finish;
    end

endmodule
