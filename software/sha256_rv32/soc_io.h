#ifndef SOC_IO_H
#define SOC_IO_H

#include <stdint.h>

#define MMIO_CYCLE_LO   (*(volatile uint32_t *)0x80000000)
#define MMIO_CYCLE_HI   (*(volatile uint32_t *)0x80000004)
#define MMIO_INSN_LO    (*(volatile uint32_t *)0x80000008)
#define MMIO_INSN_HI    (*(volatile uint32_t *)0x8000000C)
#define MMIO_SIM_CTRL   (*(volatile uint32_t *)0x80000010)
#define MMIO_CONSOLE    (*(volatile uint32_t *)0x80000014)

static inline uint64_t get_cycles(void) {
    uint32_t hi, lo, hi2;
    do {
        hi = MMIO_CYCLE_HI;
        lo = MMIO_CYCLE_LO;
        hi2 = MMIO_CYCLE_HI;
    } while (hi != hi2);
    return ((uint64_t)hi << 32) | lo;
}

static inline uint64_t get_instructions(void) {
    uint32_t hi, lo, hi2;
    do {
        hi = MMIO_INSN_HI;
        lo = MMIO_INSN_LO;
        hi2 = MMIO_INSN_HI;
    } while (hi != hi2);
    return ((uint64_t)hi << 32) | lo;
}

static inline void soc_putchar(char c) {
    MMIO_CONSOLE = (uint32_t)(uint8_t)c;
}

static inline void soc_puts(const char *str) {
    while (*str) {
        soc_putchar(*str++);
    }
}

static inline void soc_print_hex(uint32_t val, int digits) {
    const char hex_chars[] = "0123456789abcdef";
    for (int i = (digits - 1) * 4; i >= 0; i -= 4) {
        soc_putchar(hex_chars[(val >> i) & 0xf]);
    }
}

static inline void soc_print_dec(uint64_t val) {
    char buf[24];
    int idx = 0;
    if (val == 0) {
        soc_putchar('0');
        return;
    }
    while (val > 0) {
        buf[idx++] = '0' + (val % 10);
        val /= 10;
    }
    for (int i = idx - 1; i >= 0; i--) {
        soc_putchar(buf[i]);
    }
}

static inline void soc_sim_finish(int pass) {
    MMIO_SIM_CTRL = pass ? 0x1 : 0x2;
}

#endif // SOC_IO_H

