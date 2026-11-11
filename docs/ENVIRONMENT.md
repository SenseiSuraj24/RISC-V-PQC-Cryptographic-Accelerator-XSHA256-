# Environment Specification and Tool Versions

This document records the exact tool versions and development environment used for the RISC-V PQC XSHA256 Cryptographic Accelerator project.

## 1. Operating System
- **OS**: Linux x86_64 (Ubuntu 22.04 LTS / Linux kernel 6.8)
- **Local Workspace**: `/home/senseisuraj/Desktop/COD_J` (symlinked as `~/riscv-pqc`)

## 2. Compilers and Toolchains
- **Host GCC**: 11.4.0 (`/usr/bin/gcc`)
- **RISC-V Cross Compiler**: xPack GNU RISC-V Embedded GCC 15.2.0 (`riscv32-unknown-elf-gcc`, `riscv-none-elf-gcc`)
  - Target Architecture: `rv32i`
  - Target ABI: `ilp32`
  - Multilib Support: Verified
- **Python**: Python 3.10.12 with `numpy` 1.26.4, `pandas` 2.3.3, `matplotlib` 3.5.1

## 3. Simulation & Synthesis Tools
- **Icarus Verilog**: v14.0 (devel) (IEEE 1364-2005 & SystemVerilog support via `-g2012`)
- **Verilator**: 5.055 devel
- **Yosys**: 0.70+336 (for open-source synthesis sanity check and FPGA resource estimation)
- **GTKWave**: v3.3.121
- **Ripes**: v2.3.1 Linux AppImage (located in `tools/ripes/Ripes-v2.3.1-linux-x86_64.AppImage`)

## 4. Hardware Core Submodules
- **PicoRV32**: Upstream commit from `https://github.com/YosysHQ/picorv32.git` located in `external/picorv32`.

## 5. Environment Activation
Source the environment script before running builds or simulations:
```bash
source scripts/setup_env.sh
```

