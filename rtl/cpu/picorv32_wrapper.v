`timescale 1ns / 1ps

module picorv32_wrapper #(
    parameter [31:0] PROGADDR_RESET = 32'h00000000,
    parameter [31:0] STACKADDR      = 32'h00010000,
    parameter        BARREL_SHIFTER = 1,
    parameter        ENABLE_PCPI    = 1
) (
    input  wire        clk,
    input  wire        resetn,
    output wire        trap,

    // Memory interface
    output wire        mem_valid,
    output wire        mem_instr,
    input  wire        mem_ready,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    output wire [ 3:0] mem_wstrb,
    input  wire [31:0] mem_rdata,

    // Look-Ahead interface
    output wire        mem_la_read,
    output wire        mem_la_write,
    output wire [31:0] mem_la_addr,
    output wire [31:0] mem_la_wdata,
    output wire [ 3:0] mem_la_wstrb,

    // Pico Co-Processor Interface (PCPI)
    output wire        pcpi_valid,
    output wire [31:0] pcpi_insn,
    output wire [31:0] pcpi_rs1,
    output wire [31:0] pcpi_rs2,
    input  wire        pcpi_wr,
    input  wire [31:0] pcpi_rd,
    input  wire        pcpi_wait,
    input  wire        pcpi_ready,

    // IRQ interface
    input  wire [31:0] irq,
    output wire [31:0] eoi,

    // Trace interface
    output wire        trace_valid,
    output wire [35:0] trace_data
);

    picorv32 #(
        .PROGADDR_RESET (PROGADDR_RESET),
        .STACKADDR      (STACKADDR),
        .BARREL_SHIFTER (BARREL_SHIFTER),
        .COMPRESSED_ISA (0),
        .ENABLE_COUNTERS(1),
        .ENABLE_COUNTERS64(1),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .LATCHED_MEM_RDATA(0),
        .TWO_STAGE_SHIFT(1),
        .TWO_CYCLE_COMPARE(0),
        .TWO_CYCLE_ALU(0),
        .CATCH_MISALIGN (1),
        .CATCH_ILLINSN  (1),
        .ENABLE_PCPI    (ENABLE_PCPI),
        .ENABLE_MUL     (0),
        .ENABLE_FAST_MUL(0),
        .ENABLE_DIV     (0),
        .ENABLE_IRQ     (0),
        .ENABLE_TRACE   (1)
    ) u_picorv32 (
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

        .irq         (irq),
        .eoi         (eoi),

        .trace_valid (trace_valid),
        .trace_data  (trace_data)
    );

endmodule

