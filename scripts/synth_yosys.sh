#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$SCRIPT_DIR/tools/oss-cad-suite/bin:$PATH"

mkdir -p "$SCRIPT_DIR/experiments/synthesis"

echo "=== Running Artix-7 Synthesis for Standalone XSHA256 Accelerator ==="
yosys -p "
verilog_defines -D_SYNTHESIS_
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/sha256/sha256_constants.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/sha256/sha256_round.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/sha256/sha256_schedule.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/sha256/sha256_core.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/pcpi/xsha256_pcpi.sv
synth_xilinx -family xc7 -top xsha256_pcpi
stat
" > "$SCRIPT_DIR/experiments/synthesis/xsha256_artix7_utilization.rpt"

echo "=== Running Artix-7 Synthesis for Complete RISC-V SoC ==="
yosys -p "
verilog_defines -D_SYNTHESIS_
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/sha256/sha256_constants.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/sha256/sha256_round.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/sha256/sha256_schedule.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/sha256/sha256_core.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/pcpi/xsha256_pcpi.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/soc/cycle_counter.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/soc/instruction_memory.sv
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/soc/data_memory.sv
read_verilog     $SCRIPT_DIR/external/picorv32/picorv32.v
read_verilog     $SCRIPT_DIR/rtl/cpu/picorv32_wrapper.v
read_verilog -I$SCRIPT_DIR/rtl/sha256 -sv $SCRIPT_DIR/rtl/soc/riscv_soc.sv
synth_xilinx -family xc7 -top riscv_soc
stat
" > "$SCRIPT_DIR/experiments/synthesis/soc_artix7_utilization.rpt"

echo "Artix-7 synthesis complete. Reports saved in experiments/synthesis/"
