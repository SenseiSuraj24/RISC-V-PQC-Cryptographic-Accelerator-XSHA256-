#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$SCRIPT_DIR/tools/oss-cad-suite/bin:$PATH"

mkdir -p build

echo "=== Compiling SoC Simulation with Icarus Verilog ==="
iverilog -g2012 -I"$SCRIPT_DIR/rtl/sha256" -o "$SCRIPT_DIR/build/soc_sim" \
    "$SCRIPT_DIR/rtl/sha256/sha256_constants.sv" \
    "$SCRIPT_DIR/rtl/sha256/sha256_round.sv" \
    "$SCRIPT_DIR/rtl/sha256/sha256_schedule.sv" \
    "$SCRIPT_DIR/rtl/sha256/sha256_core.sv" \
    "$SCRIPT_DIR/rtl/pcpi/xsha256_pcpi.sv" \
    "$SCRIPT_DIR/rtl/soc/cycle_counter.sv" \
    "$SCRIPT_DIR/rtl/soc/instruction_memory.sv" \
    "$SCRIPT_DIR/rtl/soc/data_memory.sv" \
    "$SCRIPT_DIR/external/picorv32/picorv32.v" \
    "$SCRIPT_DIR/rtl/cpu/picorv32_wrapper.v" \
    "$SCRIPT_DIR/rtl/soc/riscv_soc.sv" \
    "$SCRIPT_DIR/testbench/soc/tb_riscv_soc.sv"

echo "=== Running SoC Simulation ==="
vvp "$SCRIPT_DIR/build/soc_sim" +firmware="$SCRIPT_DIR/build/firmware.hex"
