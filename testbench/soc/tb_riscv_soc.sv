`timescale 1ns / 1ps

module tb_riscv_soc;

    logic clk = 0;
    always #5 clk = ~clk;

    logic        resetn;
    logic        trap;
    logic        sim_finish;
    logic        sim_pass;
    logic [63:0] cycles_out;
    logic [63:0] insns_out;

    string firmware_file = "build/firmware.hex";

    riscv_soc #(
        .MEM_WORDS(32768)
    ) dut (
        .clk        (clk),
        .resetn     (resetn),
        .trap       (trap),
        .sim_finish (sim_finish),
        .sim_pass   (sim_pass),
        .cycles_out (cycles_out),
        .insns_out  (insns_out)
    );

    initial begin
        if ($value$plusargs("firmware=%s", firmware_file)) begin
            $display("[TB] Loading firmware from plusarg: %s", firmware_file);
        end else begin
            $display("[TB] Using default firmware: %s", firmware_file);
        end
        $readmemh(firmware_file, dut.ram);

        resetn = 0;
        repeat (10) @(posedge clk);
        #1;
        resetn = 1;
        $display("[TB] Reset released. SoC executing firmware...");

        // Run until finish, trap, or timeout
        fork
            begin
                wait (sim_finish || trap);
                repeat (5) @(posedge clk);
                if (trap) begin
                    $display("\n[TB] ERROR: CPU trapped at cycle %0d!", cycles_out);
                    $finish(1);
                end else if (sim_pass) begin
                    $display("\n[TB] SUCCESS: Firmware completed successfully!");
                    $display("[TB] Total CPU Cycles:       %0d", cycles_out);
                    $display("[TB] Total Retired Instructions: %0d", insns_out);
                    if (insns_out > 0)
                        $display("[TB] CPI:                   %0.2f", $itor(cycles_out) / $itor(insns_out));
                    $finish(0);
                end else begin
                    $display("\n[TB] FAILURE: Firmware reported test failure at cycle %0d!", cycles_out);
                    $finish(1);
                end
            end
            begin
                // Timeout after 20,000,000 cycles (adjust if long workload)
                #200000000;
                $display("\n[TB] TIMEOUT: Simulation exceeded time limit!");
                $finish(2);
            end
        join
    end

endmodule

