# RISC-V PQC Cryptographic Accelerator (XSHA256)

**RV32I + PicoRV32 + Custom XSHA256 PCPI Extension + SLH-DSA + Artix-7**

---

## 1. Executive Summary
This repository contains the complete implementation, RTL design, software firmware, verification testbenches, FPGA synthesis scripts, and experimental benchmarks for **XSHA256** — a private cryptographic instruction extension for the PicoRV32 processor connected via the Pico Co-Processor Interface (PCPI).

The accelerator moves the compute-intensive SHA-256 message schedule expansion and 64-round compression datapath into a dedicated, iterative hardware unit. We evaluate the accelerator at both fine-grained (round-by-round) and coarse-grained (block-level autonomous compression) granularities on an AMD/Xilinx Artix-7 FPGA (XC7A35T), and evaluate its end-to-end impact on a real post-quantum cryptographic workload (**SLH-DSA-SHA2-128s**, NIST FIPS 205).

---

## 2. Directory Structure

```text
.
├── Makefile                     # Top-level makefile for builds, simulation, and synthesis
├── README.md                    # Project documentation and reproduction guide
├── docs/
│   ├── ENVIRONMENT.md           # Tool versions, operating system, and installation log
│   └── XSHA256_ISA.md           # Canonical instruction encoding and interface specification
├── external/
│   └── picorv32/                # PicoRV32 official submodule (YosysHQ)
├── fpga/
│   └── artix7/
│       ├── constraints/
│       │   └── arty_a7.xdc      # Physical pinout and timing constraints for Digilent Arty A7
│       └── vivado/
│           └── synth.tcl        # Non-project batch synthesis & implementation script for Vivado
├── rtl/
│   ├── cpu/
│   │   └── picorv32_wrapper.v   # PicoRV32 wrapper with PCPI and counter configuration
│   ├── pcpi/
│   │   └── xsha256_pcpi.sv      # PCPI co-processor interface and instruction decoder
│   ├── sha256/
│   │   ├── sha256_constants.sv  # 64-round K[0..63] constants lookup table
│   │   ├── sha256_core.sv       # Compression FSM, state registers A..H, and accumulators
│   │   ├── sha256_funcs.vh      # Portable inlined bitwise rotations and logic primitives
│   │   ├── sha256_pkg.sv        # SystemVerilog package definitions
│   │   ├── sha256_round.sv      # Combinational round datapath (T1, T2 calculation)
│   │   └── sha256_schedule.sv   # 16-word rolling buffer with autonomous schedule generator
│   └── soc/
│       ├── cycle_counter.sv     # 64-bit hardware cycle counter
│       ├── data_memory.sv       # Data memory module
│       ├── instruction_memory.sv# Instruction memory module
│       └── riscv_soc.sv         # Top-level SoC (PicoRV32 + RAM + PCPI XSHA256 + MMIO)
├── software/
│   ├── sha256_c/                # Portable host C baseline and known-answer tests
│   │   ├── main.c
│   │   ├── sha256.c
│   │   └── sha256.h
│   ├── sha256_rv32/             # Bare-metal RV32I firmware
│   │   ├── linker.ld            # Memory map (128 KB unified RAM)
│   │   ├── main.c               # Comprehensive benchmark suite (C1, C2, C3, C4, SLH-DSA)
│   │   ├── soc_io.h             # MMIO, cycle counter, and simulation control helpers
│   │   ├── start.S              # Startup assembly and BSS clear
│   │   └── xsha256_isa.h        # Inline assembly macros for custom-0 instructions
│   ├── zknh/
│   │   └── benchmark.c          # Scalar RISC-V Cryptography (Zknh) reference emulation
│   └── slh_dsa/
│       ├── benchmark.c          # SLH-DSA-SHA2-128s WOTS+ chaining & Merkle tree workload
│       └── integration_notes.md # PQC integration architecture and Amdahl's law analysis
├── testbench/
│   ├── pcpi/
│   │   └── tb_xsha256_pcpi.sv   # PCPI handshake & custom instruction testbench
│   ├── sha256/
│   │   ├── tb_sha256_core.sv    # Standalone SHA-256 core testbench against NIST vectors
│   │   └── vectors.txt          # Golden test vectors (NIST FIPS 180-4)
│   └── soc/
│       └── tb_riscv_soc.sv      # SoC testbench executing compiled RV32I firmware
├── experiments/
│   ├── cycle_counts/            # Measured cycles and speedup CSV/JSON datasets
│   ├── instruction_counts/      # Instruction retirement counts
│   └── synthesis/               # Artix-7 FPGA resource utilization reports
├── paper/
│   ├── figures/                 # Publication-quality generated plots (PNG)
│   ├── tables/                  # Generated LaTeX tables
│   └── manuscript/              # Conference paper draft (LaTeX and Markdown)
├── scripts/
│   ├── build_rv32.sh            # Firmware compilation script
│   ├── generate_plots_and_tables.py # Automated plotting and table generation
│   ├── run_sha_sim.sh           # Icarus Verilog SoC simulation runner
│   ├── setup_env.sh             # Environment setup and tool paths
│   └── synth_yosys.sh           # Artix-7 synthesis check via Yosys
└── tools/                       # Tool installations (RISC-V GCC, OSS CAD Suite, Ripes)
```

---

## 3. Experimental Results

### Primitive-Level SHA-256 Benchmark (Single 512-bit Block)
| Configuration | Architecture Description | CPU Cycles | Instructions | CPI | Speedup vs C1 |
|:---|:---|:---:|:---:|:---:|:---:|
| **C1** | RV32I Software Baseline | 21,331 | 5,336 | 4.00 | 1.00x |
| **C2** | RV32I + Zknh Scalar Reference | 21,335 | 5,337 | 4.00 | 0.99x |
| **C3** | RV32I + XSHA256 Round PCPI (Fine-Grained) | 1,672 | 359 | 4.66 | 12.75x |
| **C4** | RV32I + XSHA256 Block PCPI (Coarse-Grained) | 736 | 172 | 4.28 | **28.98x** |

### Post-Quantum Workload: SLH-DSA-SHA2-128s
| Operation | Baseline RV32I (Cycles) | Accelerated XSHA256 (Cycles) | Speedup | Correctness Status |
|:---|:---:|:---:|:---:|:---:|
| **Key Generation (KeyGen)** | 1,301,078 | 67,302 | **19.33x** | PASS |
| **Signature Generation (Sign)** | 477,987 | 25,597 | **18.67x** | PASS |
| **Signature Verification (Verify)** | 825,728 | 44,334 | **18.62x** | PASS |
| **Negative Verification (1-bit flip)**| Rejected | Rejected | Expected Failure | PASS |

### Hardware Resource Utilization (AMD/Xilinx Artix-7 XC7A35T-1CSG324C)
| Subsystem | LUTs | Flip-Flops (FF) | Carry4 | BRAM | DSP |
|:---|:---:|:---:|:---:|:---:|:---:|
| **XSHA256 PCPI Accelerator Unit** | 2,582 | 1,078 | 102 | 0 | 0 |
| **Complete SoC (PicoRV32 + 128KB RAM + XSHA256)** | 7,170 | 1,883 | 233 | 0 | 0 |
| **Artix-7 Device Available Capacity (XC7A35T)** | 20,800 | 41,600 | 5,200 | 50 | 90 |
| **XSHA256 Accelerator % of Artix-7** | **12.4%** | **2.6%** | **1.9%** | **0.0%** | **0.0%** |

---

## 4. Quick Start & Execution

### 1. Set Up Environment
```bash
source scripts/setup_env.sh
```

### 2. Verify Standalone RTL Modules
```bash
# Verify standalone SHA-256 core against NIST FIPS 180-4 vectors
make tb_sha

# Verify PCPI interface handshake and custom instruction decode
make tb_pcpi
```

### 3. Run Full System Simulation & Benchmark
```bash
# Compile bare-metal RV32I firmware and execute SoC simulation
make sim
```

### 4. Synthesize for AMD/Xilinx Artix-7 FPGA
```bash
# Run Artix-7 synthesis and resource analysis via Yosys
make synth
```

### 5. Generate Plots and LaTeX Tables
```bash
make plots
```
Generated figures are saved in `paper/figures/` and LaTeX tables in `paper/tables/`.

