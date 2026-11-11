`timescale 1ns / 1ps

module riscv_soc #(
    parameter MEM_WORDS = 32768, // 128 KB RAM (0x00000000 - 0x0001ffff)
    parameter FIRMWARE_HEX = ""
) (
    input  logic        clk,
    input  logic        resetn,
    output logic        trap,
    output logic        sim_finish,
    output logic        sim_pass,
    output logic [63:0] cycles_out,
    output logic [63:0] insns_out
);

    // CPU Memory Bus
    wire        mem_valid;
    wire        mem_instr;
    logic       mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_wstrb;
    logic [31:0] mem_rdata;

    // Look-Ahead & Trace
    wire        mem_la_read;
    wire        mem_la_write;
    wire [31:0] mem_la_addr;
    wire [31:0] mem_la_wdata;
    wire [ 3:0] mem_la_wstrb;
    wire        trace_valid;
    wire [35:0] trace_data;

    // PCPI Bus
    wire        pcpi_valid;
    wire [31:0] pcpi_insn;
    wire [31:0] pcpi_rs1;
    wire [31:0] pcpi_rs2;
    wire        pcpi_wr;
    wire [31:0] pcpi_rd;
    wire        pcpi_wait;
    wire        pcpi_ready;

    // Instantiate PicoRV32 Core
    picorv32_wrapper #(
        .PROGADDR_RESET (32'h00000000),
        .STACKADDR      (32'h00020000), // Top of 128 KB
        .BARREL_SHIFTER (1),
        .ENABLE_PCPI    (1)
    ) u_cpu (
        .clk         (clk),
        .resetn      (resetn),
        .trap        (trap),

        .mem_valid   (mem_valid),
        .mem_instr   (mem_instr),
        .mem_ready   (mem_ready),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_wstrb   (mem_wstrb),
        .mem_rdata   (mem_rdata),

        .mem_la_read (mem_la_read),
        .mem_la_write(mem_la_write),
        .mem_la_addr (mem_la_addr),
        .mem_la_wdata(mem_la_wdata),
        .mem_la_wstrb(mem_la_wstrb),

        .pcpi_valid  (pcpi_valid),
        .pcpi_insn   (pcpi_insn),
        .pcpi_rs1    (pcpi_rs1),
        .pcpi_rs2    (pcpi_rs2),
        .pcpi_wr     (pcpi_wr),
        .pcpi_rd     (pcpi_rd),
        .pcpi_wait   (pcpi_wait),
        .pcpi_ready  (pcpi_ready),

        .irq         (32'h0),
        .eoi         (),

        .trace_valid (trace_valid),
        .trace_data  (trace_data)
    );

    // Instantiate XSHA256 PCPI Accelerator
    xsha256_pcpi u_xsha256 (
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

    // Hardware Cycle and Instruction Counters
    logic [63:0] cycle_ctr;
    logic [63:0] insn_ctr;

    assign cycles_out = cycle_ctr;
    assign insns_out  = insn_ctr;

    cycle_counter u_cycles (
        .clk    (clk),
        .resetn (resetn),
        .cycles (cycle_ctr)
    );

    always_ff @(posedge clk) begin
        if (!resetn) begin
            insn_ctr <= 64'd0;
        end else if (trace_valid) begin
            insn_ctr <= insn_ctr + 64'd1;
        end
    end

    // Unified RAM (128 KB)
    // Synchronous read/write, 1-cycle access
    logic [31:0] ram [0:MEM_WORDS-1];
    wire [14:0] word_idx = mem_addr[16:2];
    wire is_ram  = (mem_addr < 32'h00020000);
    wire is_mmio = (mem_addr >= 32'h80000000 && mem_addr < 32'h80000100);

    initial begin
        if (FIRMWARE_HEX != "") begin
            $readmemh(FIRMWARE_HEX, ram);
        end
    end

    always_ff @(posedge clk) begin
        if (!resetn) begin
            mem_ready  <= 1'b0;
            mem_rdata  <= 32'h00000000;
            sim_finish <= 1'b0;
            sim_pass   <= 1'b0;
        end else begin
            mem_ready <= 1'b0;

            if (mem_valid && !mem_ready) begin
                mem_ready <= 1'b1;

                if (is_ram) begin
                    // RAM access
                    if (mem_wstrb[0]) ram[word_idx][ 7: 0] <= mem_wdata[ 7: 0];
                    if (mem_wstrb[1]) ram[word_idx][15: 8] <= mem_wdata[15: 8];
                    if (mem_wstrb[2]) ram[word_idx][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) ram[word_idx][31:24] <= mem_wdata[31:24];
                    mem_rdata <= ram[word_idx];
                end else if (is_mmio) begin
                    // MMIO Reads
                    case (mem_addr[7:0])
                        8'h00: mem_rdata <= cycle_ctr[31:0];
                        8'h04: mem_rdata <= cycle_ctr[63:32];
                        8'h08: mem_rdata <= insn_ctr[31:0];
                        8'h0c: mem_rdata <= insn_ctr[63:32];
                        default: mem_rdata <= 32'h00000000;
                    endcase

                    // MMIO Writes
                    if (|mem_wstrb) begin
                        if (mem_addr[7:0] == 8'h10) begin
                            // Simulation finish/status control
                            sim_finish <= 1'b1;
                            sim_pass   <= (mem_wdata == 32'h00000001);
                        end else if (mem_addr[7:0] == 8'h14) begin
                            // Console output (UART-like character sink)
                            $write("%c", mem_wdata[7:0]);
                        end
                    end
                end else begin
                    mem_rdata <= 32'h00000000;
                end
            end
        end
    end

endmodule

