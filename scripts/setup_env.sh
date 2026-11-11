#!/usr/bin/env bash
# Environment setup for RISC-V PQC XSHA256 project
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="$SCRIPT_DIR/tools/riscv-toolchain/bin:$SCRIPT_DIR/tools/oss-cad-suite/bin:$PATH"
export RISCV="$SCRIPT_DIR/tools/riscv-toolchain"
export CC=riscv32-unknown-elf-gcc

echo "=== RISC-V PQC Environment Loaded ==="
echo "RISC-V GCC: $(which riscv32-unknown-elf-gcc 2>/dev/null || echo 'not in PATH')"
echo "Icarus:     $(which iverilog 2>/dev/null || echo 'not in PATH')"
echo "Verilator:  $(which verilator 2>/dev/null || echo 'not in PATH')"
echo "Yosys:      $(which yosys 2>/dev/null || echo 'not in PATH')"

