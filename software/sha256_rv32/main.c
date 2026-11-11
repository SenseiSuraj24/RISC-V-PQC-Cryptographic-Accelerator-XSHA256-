#include <stdint.h>
#include <stddef.h>
#include "soc_io.h"
#include "xsha256_isa.h"

// -------------------------------------------------------------
// Pure Software SHA-256 Baseline Implementation (RV32I)
// -------------------------------------------------------------
#define ROTRIGHT(a,b) (((a) >> (b)) | ((a) << (32-(b))))
#define CH(x,y,z)  (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x)     (ROTRIGHT(x,2) ^ ROTRIGHT(x,13) ^ ROTRIGHT(x,22))
#define EP1(x)     (ROTRIGHT(x,6) ^ ROTRIGHT(x,11) ^ ROTRIGHT(x,25))
#define SIG0(x)    (ROTRIGHT(x,7) ^ ROTRIGHT(x,18) ^ ((x) >> 3))
#define SIG1(x)    (ROTRIGHT(x,17) ^ ROTRIGHT(x,19) ^ ((x) >> 10))

static const uint32_t k_table[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

void sw_sha256_block(uint32_t state[8], const uint32_t block[16]) {
    uint32_t a, b, c, d, e, f, g, h, t1, t2;
    uint32_t m[64];
    int i;

    for (i = 0; i < 16; ++i)
        m[i] = block[i];
    for (; i < 64; ++i)
        m[i] = SIG1(m[i - 2]) + m[i - 7] + SIG0(m[i - 15]) + m[i - 16];

    a = state[0]; b = state[1]; c = state[2]; d = state[3];
    e = state[4]; f = state[5]; g = state[6]; h = state[7];

    for (i = 0; i < 64; ++i) {
        t1 = h + EP1(e) + CH(e, f, g) + k_table[i] + m[i];
        t2 = EP0(a) + MAJ(a, b, c);
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }

    state[0] += a; state[1] += b; state[2] += c; state[3] += d;
    state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

// -------------------------------------------------------------
// C2: Reference Crypto (Zknh)
// -------------------------------------------------------------
extern void zknh_sha256_block(uint32_t state[8], const uint32_t block[16]);

// -------------------------------------------------------------
// XSHA256 Custom Instruction Acceleration Implementations
// -------------------------------------------------------------

// C3: Fine-grained round instructions
void hw_xsha256_round_block(uint32_t state[8], const uint32_t block[16]) {
    xsha256_init();
    for (int i = 0; i < 16; i++) {
        xsha256_load(block[i]);
    }
    for (int i = 0; i < 64; i++) {
        xsha256_round();
    }
    for (int i = 0; i < 8; i++) {
        state[i] = xsha256_getstate(i);
    }
}

// C4: Block-level compression instruction
void hw_xsha256_compress_block(uint32_t state[8], const uint32_t block[16]) {
    xsha256_init();
    for (int i = 0; i < 16; i++) {
        xsha256_load(block[i]);
    }
    xsha256_compress();
    for (int i = 0; i < 8; i++) {
        state[i] = xsha256_getstate(i);
    }
}

// SLH-DSA post-quantum signature benchmark
extern int run_slhdsa_benchmark(void);

// -------------------------------------------------------------
// Main Benchmark Program
// -------------------------------------------------------------
int main(void) {
    soc_puts("\n=======================================================\n");
    soc_puts("   RISC-V PQC XSHA256 Cryptographic Benchmark (RV32I)\n");
    soc_puts("=======================================================\n\n");

    // Standard test vector: "abc" padded block
    const uint32_t block_abc[16] = {
        0x61626380, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000018
    };

    const uint32_t golden_digest[8] = {
        0xba7816bf, 0x8f01cfea, 0x414140de, 0x5dae2223,
        0xb00361a3, 0x96177a9c, 0xb410ff61, 0xf20015ad
    };

    uint32_t state_c1[8] = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    };
    uint32_t state_c2[8] = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    };
    uint32_t state_c3[8];
    uint32_t state_c4[8];

    uint64_t cyc_start, cyc_end;
    uint64_t insn_start, insn_end;
    uint64_t cyc_c1, cyc_c2, cyc_c3, cyc_c4;
    uint64_t insn_c1, insn_c2, insn_c3, insn_c4;

    // --- Benchmark C1: Pure RV32I Software Baseline ---
    soc_puts("[1/4] Benchmarking C1 (RV32I Software Baseline)...\n");
    insn_start = get_instructions();
    cyc_start  = get_cycles();
    sw_sha256_block(state_c1, block_abc);
    cyc_end    = get_cycles();
    insn_end   = get_instructions();
    cyc_c1  = cyc_end - cyc_start;
    insn_c1 = insn_end - insn_start;

    // --- Benchmark C2: RV32I + Zknh Scalar Cryptography ---
    soc_puts("[2/4] Benchmarking C2 (RV32I + Zknh Scalar Reference)...\n");
    insn_start = get_instructions();
    cyc_start  = get_cycles();
    zknh_sha256_block(state_c2, block_abc);
    cyc_end    = get_cycles();
    insn_end   = get_instructions();
    cyc_c2  = cyc_end - cyc_start;
    insn_c2 = insn_end - insn_start;

    // --- Benchmark C3: RV32I + XSHA256 Round-Level Custom Instructions ---
    soc_puts("[3/4] Benchmarking C3 (RV32I + XSHA256 Round PCPI)...\n");
    insn_start = get_instructions();
    cyc_start  = get_cycles();
    hw_xsha256_round_block(state_c3, block_abc);
    cyc_end    = get_cycles();
    insn_end   = get_instructions();
    cyc_c3  = cyc_end - cyc_start;
    insn_c3 = insn_end - insn_start;

    // --- Benchmark C4: RV32I + XSHA256 Block-Level Compression ---
    soc_puts("[4/4] Benchmarking C4 (RV32I + XSHA256 Block PCPI)...\n");
    insn_start = get_instructions();
    cyc_start  = get_cycles();
    hw_xsha256_compress_block(state_c4, block_abc);
    cyc_end    = get_cycles();
    insn_end   = get_instructions();
    cyc_c4  = cyc_end - cyc_start;
    insn_c4 = insn_end - insn_start;

    // --- Verify Correctness ---
    soc_puts("\n----------------- Correctness Check -----------------\n");
    int pass = 1;
    for (int i = 0; i < 8; i++) {
        if (state_c1[i] != golden_digest[i]) pass = 0;
        if (state_c2[i] != golden_digest[i]) pass = 0;
        if (state_c3[i] != golden_digest[i]) pass = 0;
        if (state_c4[i] != golden_digest[i]) pass = 0;
    }

    soc_puts("Golden Digest: ");
    for (int i = 0; i < 8; i++) soc_print_hex(golden_digest[i], 8);
    soc_puts("\nC1 SW  Digest: ");
    for (int i = 0; i < 8; i++) soc_print_hex(state_c1[i], 8);
    soc_puts("\nC2 Ref Digest: ");
    for (int i = 0; i < 8; i++) soc_print_hex(state_c2[i], 8);
    soc_puts("\nC3 HW  Digest: ");
    for (int i = 0; i < 8; i++) soc_print_hex(state_c3[i], 8);
    soc_puts("\nC4 HW  Digest: ");
    for (int i = 0; i < 8; i++) soc_print_hex(state_c4[i], 8);
    soc_puts("\n");

    if (pass) {
        soc_puts("STATUS: ALL CONFIGURATIONS VERIFIED CORRECT [PASS]\n\n");
    } else {
        soc_puts("STATUS: DIGEST MISMATCH DETECTED [FAIL]\n\n");
    }

    // --- Print Performance Metrics Table ---
    soc_puts("---------------- Performance Summary ----------------\n");
    soc_puts("Configuration       | CPU Cycles | Instructions | Speedup (vs C1)\n");
    soc_puts("--------------------+------------+--------------+----------------\n");

    soc_puts("C1 (RV32I SW)       | ");
    soc_print_dec(cyc_c1); soc_puts("      | ");
    soc_print_dec(insn_c1); soc_puts("         | 1.00x\n");

    soc_puts("C2 (RV32I + Zknh)   | ");
    soc_print_dec(cyc_c2); soc_puts("      | ");
    soc_print_dec(insn_c2); soc_puts("         | ");
    soc_print_dec(cyc_c1 / cyc_c2); soc_putchar('.');
    soc_print_dec(((cyc_c1 * 100) / cyc_c2) % 100); soc_puts("x\n");

    soc_puts("C3 (XSHA256 Round)  | ");
    soc_print_dec(cyc_c3); soc_puts("        | ");
    soc_print_dec(insn_c3); soc_puts("          | ");
    soc_print_dec(cyc_c1 / cyc_c3); soc_putchar('.');
    soc_print_dec(((cyc_c1 * 100) / cyc_c3) % 100); soc_puts("x\n");

    soc_puts("C4 (XSHA256 Block)  | ");
    soc_print_dec(cyc_c4); soc_puts("        | ");
    soc_print_dec(insn_c4); soc_puts("           | ");
    soc_print_dec(cyc_c1 / cyc_c4); soc_putchar('.');
    soc_print_dec(((cyc_c1 * 100) / cyc_c4) % 100); soc_puts("x\n");
    soc_puts("-----------------------------------------------------\n");

    // --- Run SLH-DSA Post-Quantum Cryptographic Benchmark ---
    int slh_ok = run_slhdsa_benchmark();
    if (!slh_ok) pass = 0;

    soc_sim_finish(pass);
    return 0;
}
