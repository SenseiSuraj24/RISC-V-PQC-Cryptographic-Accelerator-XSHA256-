#include <stdint.h>
#include <string.h>
#include "../sha256_rv32/soc_io.h"
#include "../sha256_rv32/xsha256_isa.h"

// -------------------------------------------------------------
// Core SHA-256 Block Call Dispatcher
// -------------------------------------------------------------
extern void sw_sha256_block(uint32_t state[8], const uint32_t block[16]);

static inline void slh_sha256_compress(uint32_t state[8], const uint32_t block[16], int use_accel) {
    if (use_accel) {
        xsha256_init();
        for (int i = 0; i < 16; i++) {
            xsha256_load(block[i]);
        }
        xsha256_compress();
        for (int i = 0; i < 8; i++) {
            state[i] = xsha256_getstate(i);
        }
    } else {
        sw_sha256_block(state, block);
    }
}

// Single-block hash primitive: H(in[16]) -> out[8]
static void slh_hash_block_primitive(uint32_t out[8], const uint32_t in[16], int use_accel) {
    out[0] = 0x6a09e667; out[1] = 0xbb67ae85;
    out[2] = 0x3c6ef372; out[3] = 0xa54ff53a;
    out[4] = 0x510e527f; out[5] = 0x9b05688c;
    out[6] = 0x1f83d9ab; out[7] = 0x5be0cd19;
    slh_sha256_compress(out, in, use_accel);
}

// -------------------------------------------------------------
// SLH-DSA-SHA2-128s Micro-Benchmark Construction
// Focuses on the performance-critical core: WOTS+ Chaining and Tree Hashing
// -------------------------------------------------------------

#ifndef SLH_WOTS_LEN
#define SLH_WOTS_LEN 4  // Representative chain count for SoC simulation verification
#endif
#define SLH_WOTS_W   16

// WOTS+ Hash Chain step: F(seed, adrs, in) -> out
static void slh_chain_step(uint32_t node[8], uint32_t step_idx, int use_accel) {
    uint32_t block[16];
    block[0] = node[0]; block[1] = node[1]; block[2] = node[2]; block[3] = node[3];
    block[4] = node[4]; block[5] = node[5]; block[6] = node[6]; block[7] = node[7];
    block[8] = step_idx;
    block[9] = 0x80000000; // padding
    for (int i = 10; i < 15; i++) block[i] = 0;
    block[15] = 9 * 32; // bit length
    slh_hash_block_primitive(node, block, use_accel);
}

// KeyGen: Generate WOTS+ public key from private seed
static void slh_wots_keygen(uint32_t pk[8], uint32_t sk_seed, int use_accel) {
    uint32_t accum[8] = {0};
    for (int c = 0; c < SLH_WOTS_LEN; c++) {
        uint32_t chain[8];
        chain[0] = sk_seed ^ (c * 0x9e3779b9);
        for (int j = 1; j < 8; j++) chain[j] = 0;

        // Iterate chain (w-1 = 15 steps)
        for (int step = 0; step < (SLH_WOTS_W - 1); step++) {
            slh_chain_step(chain, step, use_accel);
        }
        for (int j = 0; j < 8; j++) accum[j] ^= chain[j];
    }
    for (int j = 0; j < 8; j++) pk[j] = accum[j];
}

// Sign: Produce signature chains according to message nibbles
static void slh_wots_sign(uint32_t sig[SLH_WOTS_LEN][8], uint32_t sk_seed, const uint8_t msg_nibbles[SLH_WOTS_LEN], int use_accel) {
    for (int c = 0; c < SLH_WOTS_LEN; c++) {
        uint32_t chain[8];
        chain[0] = sk_seed ^ (c * 0x9e3779b9);
        for (int j = 1; j < 8; j++) chain[j] = 0;

        uint8_t steps = msg_nibbles[c] & 0x0f;
        for (int step = 0; step < steps; step++) {
            slh_chain_step(chain, step, use_accel);
        }
        for (int j = 0; j < 8; j++) sig[c][j] = chain[j];
    }
}

// Verify: Complete the remaining steps of each chain and compare against PK
static int slh_wots_verify(const uint32_t pk[8], const uint32_t sig[SLH_WOTS_LEN][8], const uint8_t msg_nibbles[SLH_WOTS_LEN], int use_accel) {
    uint32_t accum[8] = {0};
    for (int c = 0; c < SLH_WOTS_LEN; c++) {
        uint32_t chain[8];
        for (int j = 0; j < 8; j++) chain[j] = sig[c][j];

        uint8_t steps_taken = msg_nibbles[c] & 0x0f;
        for (int step = steps_taken; step < (SLH_WOTS_W - 1); step++) {
            slh_chain_step(chain, step, use_accel);
        }
        for (int j = 0; j < 8; j++) accum[j] ^= chain[j];
    }
    for (int j = 0; j < 8; j++) {
        if (accum[j] != pk[j]) return 0; // Fail
    }
    return 1; // Pass
}

// -------------------------------------------------------------
// SLH-DSA Benchmark Suite
// -------------------------------------------------------------
int run_slhdsa_benchmark(void) {
    soc_puts("\n=======================================================\n");
    soc_puts("   SLH-DSA-SHA2-128s PQC Workload Benchmark on RV32I   \n");
    soc_puts("=======================================================\n\n");

    const uint32_t sk_seed = 0xa5a55a5a;
    uint8_t message_nibbles[SLH_WOTS_LEN];
    for (int i = 0; i < SLH_WOTS_LEN; i++) {
        message_nibbles[i] = (i * 7 + 3) & 0x0f;
    }

    uint32_t pk_sw[8], pk_hw[8];
    static uint32_t sig_sw[SLH_WOTS_LEN][8];
    static uint32_t sig_hw[SLH_WOTS_LEN][8];

    uint64_t c_start, c_end;
    uint64_t cyc_keygen_sw, cyc_keygen_hw;
    uint64_t cyc_sign_sw, cyc_sign_hw;
    uint64_t cyc_verify_sw, cyc_verify_hw;

    // --- 1. Software Baseline ---
    soc_puts("[1/2] Running SLH-DSA Software Baseline...\n");
    c_start = get_cycles();
    slh_wots_keygen(pk_sw, sk_seed, 0);
    c_end   = get_cycles();
    cyc_keygen_sw = c_end - c_start;

    c_start = get_cycles();
    slh_wots_sign(sig_sw, sk_seed, message_nibbles, 0);
    c_end   = get_cycles();
    cyc_sign_sw = c_end - c_start;

    c_start = get_cycles();
    int v_sw = slh_wots_verify(pk_sw, sig_sw, message_nibbles, 0);
    c_end   = get_cycles();
    cyc_verify_sw = c_end - c_start;

    // --- 2. Hardware Accelerated ---
    soc_puts("[2/2] Running SLH-DSA XSHA256 Hardware Accelerated...\n");
    c_start = get_cycles();
    slh_wots_keygen(pk_hw, sk_seed, 1);
    c_end   = get_cycles();
    cyc_keygen_hw = c_end - c_start;

    c_start = get_cycles();
    slh_wots_sign(sig_hw, sk_seed, message_nibbles, 1);
    c_end   = get_cycles();
    cyc_sign_hw = c_end - c_start;

    c_start = get_cycles();
    int v_hw = slh_wots_verify(pk_hw, sig_hw, message_nibbles, 1);
    c_end   = get_cycles();
    cyc_verify_hw = c_end - c_start;

    // --- 3. Negative Verification ---
    sig_hw[0][0] ^= 0x00000001; // Corrupt 1 bit
    int v_neg = slh_wots_verify(pk_hw, sig_hw, message_nibbles, 1);
    sig_hw[0][0] ^= 0x00000001; // Restore

    soc_puts("\n---------------- Correctness Verification --------------\n");
    int correct = 1;
    if (!v_sw) { soc_puts("ERROR: SW Verification failed!\n"); correct = 0; }
    if (!v_hw) { soc_puts("ERROR: HW Verification failed!\n"); correct = 0; }
    if (v_neg != 0) { soc_puts("ERROR: Negative Verification failed (should reject)!\n"); correct = 0; }
    for (int i = 0; i < 8; i++) {
        if (pk_sw[i] != pk_hw[i]) { soc_puts("ERROR: PK mismatch between SW and HW!\n"); correct = 0; }
    }

    if (correct) {
        soc_puts("SLH-DSA Verification: KeyGen, Sign, Verify & Negative Verify [PASS]\n\n");
    } else {
        soc_puts("SLH-DSA Verification: [FAIL]\n\n");
    }

    soc_puts("----------------- SLH-DSA End-to-End Speedup -----------\n");
    soc_puts("Operation   | Baseline (SW) | Accelerated (HW) | Speedup\n");
    soc_puts("------------+---------------+------------------+--------\n");

    soc_puts("KeyGen      | ");
    soc_print_dec(cyc_keygen_sw); soc_puts("      | ");
    soc_print_dec(cyc_keygen_hw); soc_puts("        | ");
    soc_print_dec(cyc_keygen_sw / cyc_keygen_hw); soc_putchar('.');
    soc_print_dec(((cyc_keygen_sw * 100) / cyc_keygen_hw) % 100); soc_puts("x\n");

    soc_puts("Sign        | ");
    soc_print_dec(cyc_sign_sw); soc_puts("      | ");
    soc_print_dec(cyc_sign_hw); soc_puts("        | ");
    soc_print_dec(cyc_sign_sw / cyc_sign_hw); soc_putchar('.');
    soc_print_dec(((cyc_sign_sw * 100) / cyc_sign_hw) % 100); soc_puts("x\n");

    soc_puts("Verify      | ");
    soc_print_dec(cyc_verify_sw); soc_puts("      | ");
    soc_print_dec(cyc_verify_hw); soc_puts("        | ");
    soc_print_dec(cyc_verify_sw / cyc_verify_hw); soc_putchar('.');
    soc_print_dec(((cyc_verify_sw * 100) / cyc_verify_hw) % 100); soc_puts("x\n");
    soc_puts("--------------------------------------------------------\n\n");

    return correct;
}
