# XSHA256 Custom Instruction Proof & Verification Specification

This document describes the modular, instruction-level functional and algorithmic equivalence proof suite for the XSHA256 RISC-V `custom-0` (`0x0B`) extension against **NIST FIPS 180-4** (SHA-256).

## 1. Per-Instruction Modular Proof Suite (`testbench/proof/`)

Each custom instruction has its own standalone SystemVerilog proof testbench instantiated directly around the `xsha256_pcpi` co-processor interface (`rtl/pcpi/xsha256_pcpi.sv`) and `sha256_core` (`rtl/sha256/sha256_core.sv`), sharing the pure behavioral NIST FIPS 180-4 golden reference model in `testbench/proof/proof_common.svh`.

| Instruction | Encoding (`32-bit`) | `funct3` | Dedicated Proof File | Properties Proven |
| :--- | :--- | :--- | :--- | :--- |
| `sha256.init` | `0x0000000B` | `000` | `testbench/proof/tb_proof_init.sv` | 1-cycle PCPI handshake (`pcpi_wr=0`); NIST FIPS 180-4 §5.3.3 IV (`6a09e667..5be0cd19`) on reset and mid-execution re-init; clearing of `w_mem[0..15]`, `round_ctr`, `load_count`; isolation against standard RV32I (`ADDI`) & reserved `funct3` |
| `sha256.load` | `0x0005100B` | `001` | `testbench/proof/tb_proof_load.sv` | 1-cycle `pcpi_rs1` capture; sequential big-endian mapping into `w_mem[0..15]`; 4-bit `load_count` wrap-around (`0..15 -> 0`); non-interference with `H0..H7` and `round_ctr`; multi-block overwrite without re-init |
| `sha256.round` | `0x0000200B` | `010` | `testbench/proof/tb_proof_round.sv` | Cycle-by-cycle bit-exact equivalence of `w_cur`, `k_cur`, and all 8 working registers `(a..h)` at every round `t = 0..63` vs behavioral FIPS 180-4 §6.2.2 Step 1–3; Round 0 worked vector (`a=5d6aebcd, e=fa2a4622` for `"abc"`); 768/768 rounds verified across NIST (`"abc"`, `""`), all-zero, all-`0xFFFFFFFF`, and 8 PRNG blocks |
| `sha256.getstate` | `0x0005350B` | `011` | `testbench/proof/tb_proof_getstate.sv` | 1-cycle `pcpi_wr=1` GPR writeback onto `pcpi_rd`; full `0..7` forward & `7..0` reverse readout; non-destructive idempotency; `rs1[31:3]` upper-bit masking safety |
| `sha256.compress` | `0x0000400B` | `100` | `testbench/proof/tb_proof_compress.sv` | Autonomous multi-cycle `pcpi_wait=1` stall over exactly 64 active core rounds (`67` total PCPI handshake cycles); NIST FIPS 180-4 multi-block vectors (`""`, `"abc"`, 448-bit 2-block, 896-bit 2-block); 3-way differential proof (`1x sha256.compress == 64x sha256.round == FIPS 180-4`) across 16 PRNG single-block vectors + 4-block continuous chained stream |

## 2. How to Run the Proofs

Run all 5 per-instruction proofs cleanly:
```bash
make proof
```

Or run any single instruction proof individually (example for `sha256.round`):
```bash
tools/oss-cad-suite/bin/iverilog -g2012 -Irtl/sha256 -Itestbench/proof -o build/proof_round \
    rtl/sha256/sha256_constants.sv rtl/sha256/sha256_round.sv \
    rtl/sha256/sha256_schedule.sv rtl/sha256/sha256_core.sv \
    rtl/pcpi/xsha256_pcpi.sv testbench/proof/tb_proof_round.sv
tools/oss-cad-suite/bin/vvp build/proof_round
```

Full end-to-end verification (RTL unit tests + PCPI + PicoRV32 SoC firmware + SLH-DSA-SHA2-128s):
```bash
make test
```

