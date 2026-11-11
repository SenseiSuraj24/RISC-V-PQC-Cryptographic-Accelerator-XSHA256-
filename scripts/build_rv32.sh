#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$SCRIPT_DIR/tools/riscv-toolchain/bin:$PATH"

CC=${CC:-riscv32-unknown-elf-gcc}
OBJCOPY=${OBJCOPY:-riscv32-unknown-elf-objcopy}
OBJDUMP=${OBJDUMP:-riscv32-unknown-elf-objdump}

mkdir -p build

echo "=== Compiling RISC-V RV32I Firmware ==="
$CC -march=rv32i -mabi=ilp32 \
    -O2 -ffreestanding -nostdlib \
    -I"$SCRIPT_DIR/software/sha256_rv32" \
    -I"$SCRIPT_DIR/software/zknh" \
    -I"$SCRIPT_DIR/software/slh_dsa" \
    -T "$SCRIPT_DIR/software/sha256_rv32/linker.ld" \
    -o "$SCRIPT_DIR/build/sha256.elf" \
    "$SCRIPT_DIR/software/sha256_rv32/start.S" \
    "$SCRIPT_DIR/software/sha256_rv32/main.c" \
    "$SCRIPT_DIR/software/zknh/benchmark.c" \
    "$SCRIPT_DIR/software/slh_dsa/benchmark.c" \
    -lgcc

# Generate disassembly for architecture analysis
$OBJDUMP -d "$SCRIPT_DIR/build/sha256.elf" > "$SCRIPT_DIR/build/sha256.dump"

# Generate Verilog hexadecimal memory initialization file
# Using python script to generate 32-bit aligned hex for Verilog $readmemh
python3 - << 'EOF'
import sys, subprocess

elf_path = "build/sha256.elf"
bin_path = "build/firmware.bin"
hex_path = "build/firmware.hex"

subprocess.run(["riscv32-unknown-elf-objcopy", "-O", "binary", elf_path, bin_path], check=True)

with open(bin_path, "rb") as f:
    data = f.read()

# Pad to multiple of 4 bytes
if len(data) % 4 != 0:
    data += b'\x00' * (4 - (len(data) % 4))

with open(hex_path, "w") as f:
    for i in range(0, len(data), 4):
        # 32-bit little endian word written as 8 hex chars
        word = (data[i+3] << 24) | (data[i+2] << 16) | (data[i+1] << 8) | data[i]
        f.write(f"{word:08x}\n")

print(f"Generated {hex_path} ({len(data)} bytes, {len(data)//4} 32-bit words)")
EOF

echo "Built build/sha256.elf and build/firmware.hex"
