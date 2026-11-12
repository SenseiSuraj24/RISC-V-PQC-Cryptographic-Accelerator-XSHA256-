// =============================================================================
// proof_common.svh — Shared PCPI Instruction Driver & NIST FIPS 180-4 Golden Model
// =============================================================================
// Include INSIDE module tb_proof_* after declaring:
//   clk, pcpi_valid, pcpi_insn, pcpi_rs1, pcpi_rs2,
//   pcpi_wr, pcpi_rd, pcpi_wait, pcpi_ready
// =============================================================================

localparam [6:0] XSHA_OPCODE      = 7'b0001011; // custom-0 (0x0B)
localparam [2:0] XSHA_F3_INIT     = 3'b000;
localparam [2:0] XSHA_F3_LOAD     = 3'b001;
localparam [2:0] XSHA_F3_ROUND    = 3'b010;
localparam [2:0] XSHA_F3_GETSTATE = 3'b011;
localparam [2:0] XSHA_F3_COMPRESS = 3'b100;

function automatic logic [31:0] encode_custom0(
    input logic [6:0] funct7,
    input logic [4:0] rs2,
    input logic [4:0] rs1,
    input logic [2:0] funct3,
    input logic [4:0] rd
);
    return {funct7, rs2, rs1, funct3, rd, XSHA_OPCODE};
endfunction

localparam [31:0] INSN_INIT     = 32'h0000000B; // sha256.init
localparam [31:0] INSN_LOAD     = 32'h0005100B; // sha256.load     x10
localparam [31:0] INSN_ROUND    = 32'h0000200B; // sha256.round
localparam [31:0] INSN_GETSTATE = 32'h0005350B; // sha256.getstate x10, x10
localparam [31:0] INSN_COMPRESS = 32'h0000400B; // sha256.compress

// NIST FIPS 180-4 §5.3.3 Initial Hash Values
logic [31:0] NIST_IV [0:7] = '{
    32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
    32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19
};

// NIST FIPS 180-4 §4.2.2 Round Constants K[0..63]
logic [31:0] NIST_K [0:63] = '{
    32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
    32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
    32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
    32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
    32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
    32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
    32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
    32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
    32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
    32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
    32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
    32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
    32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
    32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
    32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
    32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
};

// Pure FIPS 180-4 §4.1.2 Bitwise Functions
function automatic logic [31:0] ref_rotr(input logic [31:0] x, input int n);
    return (x >> n) | (x << (32 - n));
endfunction

function automatic logic [31:0] ref_ch(input logic [31:0] x, input logic [31:0] y, input logic [31:0] z);
    return (x & y) ^ ((~x) & z);
endfunction

function automatic logic [31:0] ref_maj(input logic [31:0] x, input logic [31:0] y, input logic [31:0] z);
    return (x & y) ^ (x & z) ^ (y & z);
endfunction

function automatic logic [31:0] ref_big_sig0(input logic [31:0] x);
    return ref_rotr(x, 2) ^ ref_rotr(x, 13) ^ ref_rotr(x, 22);
endfunction

function automatic logic [31:0] ref_big_sig1(input logic [31:0] x);
    return ref_rotr(x, 6) ^ ref_rotr(x, 11) ^ ref_rotr(x, 25);
endfunction

function automatic logic [31:0] ref_sml_sig0(input logic [31:0] x);
    return ref_rotr(x, 7) ^ ref_rotr(x, 18) ^ (x >> 3);
endfunction

function automatic logic [31:0] ref_sml_sig1(input logic [31:0] x);
    return ref_rotr(x, 17) ^ ref_rotr(x, 19) ^ (x >> 10);
endfunction

// Golden FIPS 180-4 §6.2.2 Step 1: Message Schedule Expansion W[0..63]
task automatic ref_expand_schedule(
    input  logic [31:0] blk [0:15],
    output logic [31:0] w   [0:63]
);
    int t;
    for (t = 0; t < 16; t++)
        w[t] = blk[t];
    for (t = 16; t < 64; t++)
        w[t] = ref_sml_sig1(w[t-2]) + w[t-7] + ref_sml_sig0(w[t-15]) + w[t-16];
endtask

// Golden FIPS 180-4 §6.2.2 Step 3: Single Round Transition (pure 256-bit state)
function automatic logic [255:0] ref_round_step_fn(
    input logic [255:0] st,
    input logic [31:0]  w_t,
    input logic [31:0]  k_t
);
    logic [31:0] a, b, c, d, e, f, g, h;
    logic [31:0] t1, t2;
    {a, b, c, d, e, f, g, h} = st;
    t1 = h + ref_big_sig1(e) + ref_ch(e, f, g) + k_t + w_t;
    t2 = ref_big_sig0(a) + ref_maj(a, b, c);
    return {t1 + t2, a, b, c, d + t1, e, f, g};
endfunction

// Golden FIPS 180-4 §6.2.2 Full Block Compression (non-automatic safe arrays)
task ref_compress_block(
    input  logic [31:0] in_state  [0:7],
    input  logic [31:0] blk       [0:15],
    output logic [31:0] out_state [0:7]
);
    logic [31:0] w [0:63];
    logic [255:0] st;
    logic [31:0] a, b, c, d, e, f, g, h;
    int t;

    for (t = 0; t < 16; t++)
        w[t] = blk[t];
    for (t = 16; t < 64; t++)
        w[t] = ref_sml_sig1(w[t-2]) + w[t-7] + ref_sml_sig0(w[t-15]) + w[t-16];

    st = {in_state[0], in_state[1], in_state[2], in_state[3],
          in_state[4], in_state[5], in_state[6], in_state[7]};

    for (t = 0; t < 64; t++) begin
        st = ref_round_step_fn(st, w[t], NIST_K[t]);
    end

    {a, b, c, d, e, f, g, h} = st;
    out_state[0] = in_state[0] + a;
    out_state[1] = in_state[1] + b;
    out_state[2] = in_state[2] + c;
    out_state[3] = in_state[3] + d;
    out_state[4] = in_state[4] + e;
    out_state[5] = in_state[5] + f;
    out_state[6] = in_state[6] + g;
    out_state[7] = in_state[7] + h;
endtask

// PCPI Transaction Driver mimicking PicoRV32 handshake
task automatic exec_pcpi(
    input  logic [31:0] insn,
    input  logic [31:0] rs1_val,
    input  logic [31:0] rs2_val,
    output logic [31:0] rd_val,
    output logic        wr_val,
    output int          wait_cycles
);
    @(posedge clk); #1;
    pcpi_valid  = 1'b1;
    pcpi_insn   = insn;
    pcpi_rs1    = rs1_val;
    pcpi_rs2    = rs2_val;
    wait_cycles = 0;

    while (!pcpi_ready) begin
        @(posedge clk); #1;
        wait_cycles++;
        if (wait_cycles > 200) begin
            $display("  [TIMEOUT] pcpi_ready never asserted for insn=%08h", insn);
            break;
        end
    end

    rd_val = pcpi_rd;
    wr_val = pcpi_wr;

    @(posedge clk); #1;
    pcpi_valid = 1'b0;
    pcpi_insn  = 32'h00000013; // NOP (ADDI x0, x0, 0)
    pcpi_rs1   = 32'h00000000;
    pcpi_rs2   = 32'h00000000;
endtask

// Helper: execute sha256.getstate via PCPI for index i
task automatic pcpi_getstate(input int idx, output logic [31:0] val, output logic wr);
    int dummy_cyc;
    exec_pcpi(encode_custom0(7'd0, 5'd0, 5'd10, XSHA_F3_GETSTATE, 5'd10),
              idx[31:0], 32'h0, val, wr, dummy_cyc);
endtask

// Helper: execute sha256.init via PCPI
task automatic pcpi_init();
    logic [31:0] d_rd; logic d_wr; int d_cyc;
    exec_pcpi(INSN_INIT, 32'h0, 32'h0, d_rd, d_wr, d_cyc);
endtask

// Helper: execute sha256.load via PCPI
task automatic pcpi_load(input logic [31:0] word);
    logic [31:0] d_rd; logic d_wr; int d_cyc;
    exec_pcpi(INSN_LOAD, word, 32'h0, d_rd, d_wr, d_cyc);
endtask

// Helper: execute sha256.round via PCPI
task automatic pcpi_round();
    logic [31:0] d_rd; logic d_wr; int d_cyc;
    exec_pcpi(INSN_ROUND, 32'h0, 32'h0, d_rd, d_wr, d_cyc);
endtask

// Helper: execute sha256.compress via PCPI
task automatic pcpi_compress(output int cyc);
    logic [31:0] d_rd; logic d_wr;
    exec_pcpi(INSN_COMPRESS, 32'h0, 32'h0, d_rd, d_wr, cyc);
endtask
