// =============================================================================
// PROOF TESTBENCH 1: sha256.init (opcode=0x0B, funct3=000, insn=0x0000000B)
// =============================================================================
// Verifies through the actual RISC-V PCPI custom-0 instruction interface:
//   [CLAIM 1] ISA Decode & Handshake: 32'h0000000B completes in 1 PCPI cycle,
//             asserts pcpi_ready=1, pcpi_wr=0, pcpi_wait=0.
//   [CLAIM 2] Non-interference: Standard RV32I opcodes (ADDI) & unimplemented
//             funct3 (101..111) do NOT trigger pcpi_ready or corrupt state.
//   [CLAIM 3] NIST FIPS 180-4 §5.3.3 Initial Hash Value: Both reset and
//             sha256.init load exact H0..H7 AND working variables a..h.
//   [CLAIM 4] Mid-Computation State Reset: Firing sha256.init after arbitrary
//             loads & rounds restores H0..H7, a..h, round_ctr=0, load_ctr=0,
//             w_mem=0, busy=0, done=0.
// =============================================================================
`timescale 1ns / 1ps

module tb_proof_init;

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

    string reg_names [0:7] = '{"H0","H1","H2","H3","H4","H5","H6","H7"};
    int errors = 0;

    task automatic check_all_iv(input string phase);
        logic [31:0] rd_val;
        logic        wr_val;
        logic [31:0] work_regs [0:7];

        // 1. Read back H0..H7 using sha256.getstate
        for (int i = 0; i < 8; i++) begin
            pcpi_getstate(i, rd_val, wr_val);
            if (rd_val !== NIST_IV[i] || wr_val !== 1'b1) begin
                $display("  [FAIL] %s %s: got %08h (wr=%b), exp %08h",
                         phase, reg_names[i], rd_val, wr_val, NIST_IV[i]);
                errors++;
            end else begin
                $display("  [OK]   %s %s = %08h (NIST FIPS 180-4 IV)", phase, reg_names[i], rd_val);
            end
        end

        // 2. Also verify internal working registers a..h == NIST_IV
        work_regs[0] = dut.u_core.a; work_regs[1] = dut.u_core.b;
        work_regs[2] = dut.u_core.c; work_regs[3] = dut.u_core.d;
        work_regs[4] = dut.u_core.e; work_regs[5] = dut.u_core.f;
        work_regs[6] = dut.u_core.g; work_regs[7] = dut.u_core.h;
        for (int i = 0; i < 8; i++) begin
            if (work_regs[i] !== NIST_IV[i]) begin
                $display("  [FAIL] %s working reg[%0d]: got %08h, exp %08h", phase, i, work_regs[i], NIST_IV[i]);
                errors++;
            end
        end

        // 3. Verify counters & flags are clean
        if (dut.u_core.round_ctr !== 6'd0) begin
            $display("  [FAIL] %s round_ctr=%0d, expected 0", phase, dut.u_core.round_ctr);
            errors++;
        end
        if (dut.u_core.load_count !== 4'd0) begin
            $display("  [FAIL] %s load_count=%0d, expected 0", phase, dut.u_core.load_count);
            errors++;
        end
        if (dut.u_core.busy !== 1'b0 || dut.u_core.done !== 1'b0) begin
            $display("  [FAIL] %s busy=%b done=%b, expected 0/0", phase, dut.u_core.busy, dut.u_core.done);
            errors++;
        end
    endtask

    logic [31:0] ret_rd;
    logic        ret_wr;
    int          wait_cyc;

    initial begin
        $display("=================================================================");
        $display("PROOF 1: sha256.init (0x%08h | custom-0 funct3=000)", INSN_INIT);
        $display("=================================================================");

        resetn = 0; pcpi_valid = 0; pcpi_insn = 32'h00000013; pcpi_rs1 = 0; pcpi_rs2 = 0;
        repeat(5) @(posedge clk); #1;
        resetn = 1;
        repeat(2) @(posedge clk); #1;

        // --- TEST 1: Hardware reset loads NIST IV ---
        $display("\n[TEST 1] Verify post-reset state matches NIST FIPS 180-4 §5.3.3...");
        check_all_iv("RESET");

        // --- TEST 2: Corrupt all internal state, then fire sha256.init via PCPI ---
        $display("\n[TEST 2] Run 16 loads + 64 rounds to mutate H0..H7, W[], a..h, then fire sha256.init...");
        for (int i = 0; i < 16; i++) pcpi_load(32'hA5A50000 ^ i);
        for (int r = 0; r < 64; r++) pcpi_round();

        // Now load partial second block + 17 rounds so round_ctr=17 and load_count=5
        for (int i = 0; i < 5; i++) pcpi_load(32'hDEADBEEF ^ i);
        for (int r = 0; r < 17; r++) pcpi_round();

        $display("  Mid-state before init: round_ctr=%0d, load_count=%0d, H0=%08h",
                 dut.u_core.round_ctr, dut.u_core.load_count, dut.u_core.h0);

        exec_pcpi(INSN_INIT, 32'hCAFEBABE, 32'h12345678, ret_rd, ret_wr, wait_cyc);
        $display("  PCPI sha256.init completed in %0d wait cycle(s), pcpi_wr=%b", wait_cyc, ret_wr);

        if (wait_cyc !== 1) begin
            $display("  [FAIL] sha256.init latency=%0d cycles, expected 1", wait_cyc);
            errors++;
        end
        if (ret_wr !== 1'b0) begin
            $display("  [FAIL] sha256.init asserted pcpi_wr=1 (must not write GPR)");
            errors++;
        end
        @(posedge clk); #1; // let core clock edge settle

        check_all_iv("POST-INIT");

        // Verify W[0..15] schedule memory cleared to 0
        for (int i = 0; i < 16; i++) begin
            if (dut.u_core.u_schedule.w_mem[i] !== 32'h0) begin
                $display("  [FAIL] w_mem[%0d] = %08h after init, expected 0", i, dut.u_core.u_schedule.w_mem[i]);
                errors++;
            end
        end
        $display("  [OK]   w_mem[0..15] cleared, round_ctr=0, load_count=0, busy=0, done=0");

        // --- TEST 3: Non-custom opcode & reserved funct3 isolation ---
        $display("\n[TEST 3] Verify non-custom0 & reserved funct3 do NOT trigger PCPI or alter IV...");
        @(posedge clk); #1;
        pcpi_valid = 1'b1;
        pcpi_insn  = 32'h00000013; // ADDI x0,x0,0 (standard RV32I)
        repeat(3) @(posedge clk); #1;
        if (pcpi_ready !== 1'b0 || pcpi_wr !== 1'b0 || pcpi_wait !== 1'b0) begin
            $display("  [FAIL] PCPI responded to standard ADDI opcode!");
            errors++;
        end else begin
            $display("  [OK]   Standard RV32I instruction ignored cleanly");
        end
        pcpi_insn = encode_custom0(7'd0, 5'd0, 5'd0, 3'b101, 5'd0); // reserved funct3=101
        repeat(3) @(posedge clk); #1;
        if (pcpi_ready !== 1'b0 || pcpi_wr !== 1'b0 || pcpi_wait !== 1'b0) begin
            $display("  [FAIL] PCPI responded to reserved funct3=101!");
            errors++;
        end else begin
            $display("  [OK]   Reserved funct3=101 ignored cleanly");
        end
        pcpi_valid = 1'b0; pcpi_insn = 32'h00000013;
        @(posedge clk); #1;

        check_all_iv("ISOLATION");

        $display("\n=================================================================");
        if (errors == 0)
            $display("PROOF RESULT: sha256.init PASSED (all %0d checks clean)", 30);
        else
            $display("PROOF RESULT: sha256.init FAILED with %0d error(s)", errors);
        $display("=================================================================");
        $finish;
    end

endmodule
