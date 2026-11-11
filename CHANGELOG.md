# Changelog

All notable changes and architectural decisions for the RISC-V PQC XSHA256 project are documented in this file.

## [v1.0-final] - 2026-11-05
### Added
- Complete integration of SLH-DSA-SHA2-128s WOTS+ chaining, keygen, signing, verification, and negative verification tests.
- End-to-end PQC speedup measurements: 19.33x (KeyGen), 18.67x (Sign), 18.62x (Verify).
- Full scientific manuscript draft (`paper/manuscript/paper.tex` and `paper/manuscript/paper.md`).
- Automated data generation, CSV/JSON outputs, and publication plots in `paper/figures/`.
- Full project documentation in `README.md`.

## [v0.5-fpga] - 2026-11-05
### Added
- Digilent Arty A7 (AMD/Xilinx Artix-7 XC7A35TCSG324-1) constraints (`fpga/artix7/constraints/arty_a7.xdc`).
- Vivado non-project batch synthesis and implementation script (`fpga/artix7/vivado/synth.tcl`).
- Open-source Artix-7 synthesis and resource mapping using Yosys (`scripts/synth_yosys.sh`).
- Verified zero BRAM and zero DSP utilization; accelerator requires only 2,582 LUTs and 1,078 FFs (12.4% of Artix-7 device).

## [v0.4-pcpi] - 2026-11-05
### Added
- Pico Co-Processor Interface (PCPI) module (`rtl/pcpi/xsha256_pcpi.sv`).
- Custom-0 opcode space decoding (opcode 0x0B).
- Dedicated PCPI testbench (`testbench/pcpi/tb_xsha256_pcpi.sv`) verifying handshake and custom instruction decode.
- Support for autonomous block-level `sha256.compress` instruction with `pcpi_wait` handshaking.

## [v0.3-sha-rtl] - 2026-11-05
### Added
- Synthesizable SHA-256 round datapath (`rtl/sha256/sha256_round.sv`).
- 16-word rolling message schedule expansion generator (`rtl/sha256/sha256_schedule.sv`).
- Round constants lookup unit (`rtl/sha256/sha256_constants.sv`).
- Standalone SHA-256 core FSM (`rtl/sha256/sha256_core.sv`).
- Standalone testbench (`testbench/sha256/tb_sha256_core.sv`) verifying against NIST FIPS 180-4 test vectors.

## [v0.2-sha-sw] - 2026-11-05
### Added
- Portable C SHA-256 reference implementation (`software/sha256_c/`).
- Verified against NIST vectors ("abc", empty string, 56-byte multi-block).

## [v0.1-rv32i] - 2026-11-05
### Added
- Development environment and cross-compilation toolchain setup.
- PicoRV32 submodule tracking.
- Bare-metal RV32I startup code and linker script (`software/sha256_rv32/start.S`, `linker.ld`).
- 64-bit hardware cycle counter and MMIO simulation test harness.

