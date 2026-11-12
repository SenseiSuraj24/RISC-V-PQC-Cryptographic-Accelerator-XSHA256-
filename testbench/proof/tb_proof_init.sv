// =============================================================================
// PROOF TESTBENCH 1: sha256.init (funct3=000)
// =============================================================================
// Verifies that sha256.init correctly loads the NIST FIPS 180-4 Initial Values
// (IV) into the hardware hash state registers H0..H7 and resets round counter.
//
// NIST FIPS 180-4 §5.3.3 — SHA-256 Initial Hash Value:
//   H0 = 6a09e667, H1 = bb67ae85, H2 = 3c6ef372, H3 = a54ff53a
//   H4 = 510e527f, H5 = 9b05688c, H6 = 1f83d9ab, H7 = 5be0cd19
//
// PASS CRITERIA:
//   After cmd_init pulse, all 8 state registers must match the NIST IV exactly.
// =============================================================================
`timescale 1ns / 1ps

module tb_proof_init;

    logic clk = 0;
    always #5 clk = ~clk;

    logic        resetn;
    logic        cmd_init;
    logic        cmd_load;
    logic [31:0] load_data;
    logic        cmd_round;
    logic        cmd_compress;
    logic [2:0]  state_idx;
    logic [31:0] state_out;
    logic [5:0]  current_round;
    logic        busy;
    logic        done;

    sha256_core dut (
        .clk(clk), .resetn(resetn),
        .cmd_init(cmd_init), .cmd_load(cmd_load), .load_data(load_data),
        .cmd_round(cmd_round), .cmd_compress(cmd_compress),
        .state_idx(state_idx), .state_out(state_out),
        .current_round(current_round), .busy(busy), .done(done)
    );

    // NIST FIPS 180-4 §5.3.3 Initial Hash Values
    logic [31:0] NIST_IV [0:7] = '{
        32'h6a09e667,  // H0 = sqrt(2)  fractional
        32'hbb67ae85,  // H1 = sqrt(3)  fractional
        32'h3c6ef372,  // H2 = sqrt(5)  fractional
        32'ha54ff53a,  // H3 = sqrt(7)  fractional
        32'h510e527f,  // H4 = sqrt(11) fractional
        32'h9b05688c,  // H5 = sqrt(13) fractional
        32'h1f83d9ab,  // H6 = sqrt(17) fractional
        32'h5be0cd19   // H7 = sqrt(19) fractional
    };

    string reg_names [0:7] = '{"H0","H1","H2","H3","H4","H5","H6","H7"};
    int errors = 0;

    task automatic check_iv(string phase);
        for (int i = 0; i < 8; i++) begin
            state_idx = i[2:0]; #1;
            if (state_out !== NIST_IV[i]) begin
                $display("  [FAIL] %s %s: got %08h, expected %08h (NIST FIPS 180-4)",
                         phase, reg_names[i], state_out, NIST_IV[i]);
                errors++;
            end else begin
                $display("  [OK]   %s %s = %08h (matches NIST IV)", phase, reg_names[i], state_out);
            end
        end
    endtask

    initial begin
        $display("=================================================================");
        $display("PROOF: sha256.init — NIST FIPS 180-4 Initial Value Verification");
        $display("=================================================================");

        resetn = 0; cmd_init = 0; cmd_load = 0; cmd_round = 0;
        cmd_compress = 0; load_data = 0; state_idx = 0;
        repeat(5) @(posedge clk); #1;
        resetn = 1;
        repeat(2) @(posedge clk); #1;

        // --- TEST 1: Hardware reset loads NIST IV ---
        $display("\n[TEST 1] Verify hardware reset (resetn=1) loads NIST IV...");
        check_iv("RESET");

        // --- TEST 2: Corrupt state then re-init restores IV ---
        $display("\n[TEST 2] Corrupt state with arbitrary data, then sha256.init restores IV...");
        // Load garbage data to corrupt working state
        cmd_load  = 1; load_data = 32'hDEADBEEF; @(posedge clk); #1; cmd_load = 0;
        cmd_round = 1; @(posedge clk); #1; cmd_round = 0;

        // Now fire sha256.init — equivalent to: asm(".insn r 0x0B, 0x0, 0x00, x0, x0, x0")
        $display("  Firing sha256.init (cmd_init pulse)...");
        cmd_init = 1; @(posedge clk); #1; cmd_init = 0;
        @(posedge clk); #1;

        check_iv("POST-INIT");

        // --- TEST 3: round_ctr reset to 0 after init ---
        $display("\n[TEST 3] Verify round counter resets to 0 after sha256.init...");
        if (current_round !== 6'd0)
            $display("  [FAIL] round_ctr=%0d, expected 0", current_round);
        else
            $display("  [OK]   round_ctr = 0 (correctly reset)");

        // --- TEST 4: busy=0, done=0 after init (no spurious signals) ---
        $display("\n[TEST 4] Verify busy=0, done=0 after sha256.init...");
        if (busy !== 1'b0)
            $display("  [FAIL] busy=%b, expected 0", busy);
        else
            $display("  [OK]   busy = 0");
        if (done !== 1'b0)
            $display("  [FAIL] done=%b, expected 0", done);
        else
            $display("  [OK]   done = 0");

        $display("\n=================================================================");
        if (errors == 0)
            $display("PROOF RESULT: sha256.init PASSED — IV matches NIST FIPS 180-4");
        else
            $display("PROOF RESULT: sha256.init FAILED with %0d errors", errors);
        $display("=================================================================");
        $finish;
    end

endmodule
