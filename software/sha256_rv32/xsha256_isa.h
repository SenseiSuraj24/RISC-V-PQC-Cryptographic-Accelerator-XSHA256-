#ifndef XSHA256_ISA_H
#define XSHA256_ISA_H

#include <stdint.h>

// CUSTOM-0 opcode: 0x0B (7'b0001011)
// funct3 encodings:
//   000 = sha256.init
//   001 = sha256.load (rs1 = word)
//   010 = sha256.round
//   011 = sha256.getstate (rs1 = index, rd = state)
//   100 = sha256.compress (autonomous 64 rounds)

#define XSHA256_OPCODE 0x0B
#define XSHA256_F3_INIT     0x0
#define XSHA256_F3_LOAD     0x1
#define XSHA256_F3_ROUND    0x2
#define XSHA256_F3_GETSTATE 0x3
#define XSHA256_F3_COMPRESS 0x4

static inline void xsha256_init(void) {
    asm volatile (
        ".insn r 0x0B, 0x0, 0x00, x0, x0, x0"
    );
}

static inline void xsha256_load(uint32_t word) {
    asm volatile (
        ".insn r 0x0B, 0x1, 0x00, x0, %0, x0"
        : : "r"(word)
    );
}

static inline void xsha256_round(void) {
    asm volatile (
        ".insn r 0x0B, 0x2, 0x00, x0, x0, x0"
    );
}

static inline uint32_t xsha256_getstate(uint32_t index) {
    uint32_t val;
    asm volatile (
        ".insn r 0x0B, 0x3, 0x00, %0, %1, x0"
        : "=r"(val) : "r"(index)
    );
    return val;
}

static inline void xsha256_compress(void) {
    asm volatile (
        ".insn r 0x0B, 0x4, 0x00, x0, x0, x0"
    );
}

#endif // XSHA256_ISA_H

