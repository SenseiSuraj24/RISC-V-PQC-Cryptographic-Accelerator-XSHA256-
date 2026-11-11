`timescale 1ns / 1ps

module xsha256_pcpi (
    input  logic        clk,
    input  logic        resetn,

    // Pico Co-Processor Interface (PCPI)
    input  logic        pcpi_valid,
    input  logic [31:0] pcpi_insn,
    input  logic [31:0] pcpi_rs1,
    input  logic [31:0] pcpi_rs2,
    output logic        pcpi_wr,
    output logic [31:0] pcpi_rd,
    output logic        pcpi_wait,
    output logic        pcpi_ready
);

    localparam [6:0] OPCODE_CUSTOM0 = 7'b0001011;

    wire is_custom0 = pcpi_valid && (pcpi_insn[6:0] == OPCODE_CUSTOM0);
    wire [2:0] funct3 = pcpi_insn[14:12];
    wire [6:0] funct7 = pcpi_insn[31:25];

    wire is_init     = is_custom0 && (funct3 == 3'b000);
    wire is_load     = is_custom0 && (funct3 == 3'b001);
    wire is_round    = is_custom0 && (funct3 == 3'b010);
    wire is_getstate = is_custom0 && (funct3 == 3'b011);
    wire is_compress = is_custom0 && (funct3 == 3'b100);

    // Core control signals
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

    assign load_data = pcpi_rs1;
    assign state_idx = pcpi_rs1[2:0];

    // Instantiate underlying SHA-256 accelerator core
    sha256_core u_core (
        .clk           (clk),
        .resetn        (resetn),
        .cmd_init      (cmd_init),
        .cmd_load      (cmd_load),
        .load_data     (load_data),
        .cmd_round     (cmd_round),
        .cmd_compress  (cmd_compress),
        .state_idx     (state_idx),
        .state_out     (state_out),
        .current_round (current_round),
        .busy          (busy),
        .done          (done)
    );

    // PCPI Handshake FSM states
    localparam [1:0] ST_IDLE     = 2'd0;
    localparam [1:0] ST_COMPRESS = 2'd1;
    localparam [1:0] ST_DONE     = 2'd2;

    logic [1:0] state;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            state        <= ST_IDLE;
            pcpi_wr      <= 1'b0;
            pcpi_rd      <= 32'h00000000;
            pcpi_wait    <= 1'b0;
            pcpi_ready   <= 1'b0;
            cmd_init     <= 1'b0;
            cmd_load     <= 1'b0;
            cmd_round    <= 1'b0;
            cmd_compress <= 1'b0;
        end else begin
            // Default pulse clears
            pcpi_wr      <= 1'b0;
            pcpi_ready   <= 1'b0;
            cmd_init     <= 1'b0;
            cmd_load     <= 1'b0;
            cmd_round    <= 1'b0;
            cmd_compress <= 1'b0;

            case (state)
                ST_IDLE: begin
                    pcpi_wait <= 1'b0;
                    if (is_custom0) begin
                        if (is_init) begin
                            cmd_init   <= 1'b1;
                            pcpi_ready <= 1'b1;
                            pcpi_wr    <= 1'b0;
                            state      <= ST_DONE;
                        end else if (is_load) begin
                            cmd_load   <= 1'b1;
                            pcpi_ready <= 1'b1;
                            pcpi_wr    <= 1'b0;
                            state      <= ST_DONE;
                        end else if (is_round) begin
                            cmd_round  <= 1'b1;
                            pcpi_ready <= 1'b1;
                            pcpi_wr    <= 1'b0;
                            state      <= ST_DONE;
                        end else if (is_getstate) begin
                            pcpi_rd    <= state_out;
                            pcpi_ready <= 1'b1;
                            pcpi_wr    <= 1'b1;
                            state      <= ST_DONE;
                        end else if (is_compress) begin
                            cmd_compress <= 1'b1;
                            pcpi_wait    <= 1'b1;
                            state        <= ST_COMPRESS;
                        end
                    end
                end

                ST_COMPRESS: begin
                    pcpi_wait <= 1'b1;
                    if (done) begin
                        pcpi_wait  <= 1'b0;
                        pcpi_ready <= 1'b1;
                        pcpi_wr    <= 1'b0;
                        state      <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    // PicoRV32 deasserts pcpi_valid after sampling pcpi_ready
                    if (!pcpi_valid) begin
                        state <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
