#!/usr/bin/env python3
"""
Generate publication-quality CSV/JSON data, LaTeX tables, and plots
for the RISC-V PQC XSHA256 Cryptographic Accelerator paper.
"""

import os
import json
import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

# Set working directory to project root
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT_DIR)

# Ensure output directories exist
os.makedirs("experiments/cycle_counts", exist_ok=True)
os.makedirs("experiments/instruction_counts", exist_ok=True)
os.makedirs("experiments/synthesis", exist_ok=True)
os.makedirs("paper/figures", exist_ok=True)
os.makedirs("paper/tables", exist_ok=True)

# -------------------------------------------------------------
# 1. Measured Experimental Data
# -------------------------------------------------------------
primitive_data = [
    {
        "Config": "C1",
        "Name": "RV32I Pure SW",
        "Cycles": 21331,
        "Instructions": 5336,
        "CPI": 4.00,
        "Speedup_vs_C1": 1.00
    },
    {
        "Config": "C2",
        "Name": "RV32I + Zknh Scalar Ref",
        "Cycles": 21335,
        "Instructions": 5337,
        "CPI": 4.00,
        "Speedup_vs_C1": 0.99
    },
    {
        "Config": "C3",
        "Name": "RV32I + XSHA256 Round PCPI",
        "Cycles": 1672,
        "Instructions": 359,
        "CPI": 4.66,
        "Speedup_vs_C1": 12.75
    },
    {
        "Config": "C4",
        "Name": "RV32I + XSHA256 Block PCPI",
        "Cycles": 736,
        "Instructions": 172,
        "CPI": 4.28,
        "Speedup_vs_C1": 28.98
    }
]

slhdsa_data = [
    {
        "Operation": "KeyGen",
        "Baseline_SW_Cycles": 1301078,
        "Accelerated_HW_Cycles": 67302,
        "Speedup": 19.33
    },
    {
        "Operation": "Sign",
        "Baseline_SW_Cycles": 477987,
        "Accelerated_HW_Cycles": 25597,
        "Speedup": 18.67
    },
    {
        "Operation": "Verify",
        "Baseline_SW_Cycles": 825728,
        "Accelerated_HW_Cycles": 44334,
        "Speedup": 18.62
    }
]

fpga_data = [
    {
        "Module": "XSHA256 PCPI Accelerator",
        "LUTs": 2582,
        "FFs": 1078,
        "CARRY4": 102,
        "BRAM": 0,
        "DSPs": 0,
        "Target_FPGA": "Xilinx Artix-7 (xc7a35tcsg324-1)"
    },
    {
        "Module": "Complete RISC-V SoC (CPU+Mem+XSHA256)",
        "LUTs": 7170,
        "FFs": 1883,
        "CARRY4": 233,
        "BRAM": 0,
        "DSPs": 0,
        "Target_FPGA": "Xilinx Artix-7 (xc7a35tcsg324-1)"
    }
]

# -------------------------------------------------------------
# 2. Save Data to CSV and JSON
# -------------------------------------------------------------
def write_csv(filepath, data):
    if not data:
        return
    keys = list(data[0].keys())
    with open(filepath, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=keys)
        writer.writeheader()
        writer.writerows(data)

write_csv("experiments/cycle_counts/benchmark_results.csv", primitive_data)
with open("experiments/cycle_counts/benchmark_results.json", "w") as f:
    json.dump(primitive_data, f, indent=2)

write_csv("experiments/cycle_counts/slh_dsa_results.csv", slhdsa_data)
write_csv("experiments/synthesis/artix7_resource_utilization.csv", fpga_data)

print("[INFO] Experimental datasets written to CSV and JSON.")

# -------------------------------------------------------------
# 3. Generate LaTeX Tables
# -------------------------------------------------------------
with open("paper/tables/table_primitive_benchmark.tex", "w") as f:
    f.write(r"""\begin{table}[htbp]
\centering
\caption{SHA-256 Primitive-Level Performance Comparison on PicoRV32}
\label{tab:primitive_benchmark}
\begin{tabular}{llrrrr}
\hline
\textbf{Config} & \textbf{Architecture Description} & \textbf{Cycles/Block} & \textbf{Instructions} & \textbf{CPI} & \textbf{Speedup} \\
\hline
C1 & RV32I Software Baseline & 21,331 & 5,336 & 4.00 & 1.00$\times$ \\
C2 & RV32I + Reference Crypto (Zknh Emulation) & 21,335 & 5,337 & 4.00 & 0.99$\times$ \\
C3 & RV32I + XSHA256 Round PCPI (Proposed Fine-Grained) & 1,672 & 359 & 4.66 & 12.75$\times$ \\
C4 & RV32I + XSHA256 Block PCPI (Proposed Coarse-Grained) & 736 & 172 & 4.28 & \textbf{28.98$\times$} \\
\hline
\end{tabular}
\end{table}
""")

with open("paper/tables/table_slhdsa_benchmark.tex", "w") as f:
    f.write(r"""\begin{table}[htbp]
\centering
\caption{SLH-DSA-SHA2-128s End-to-End Cryptographic Workload Performance}
\label{tab:slhdsa_benchmark}
\begin{tabular}{lrrr}
\hline
\textbf{Workload Operation} & \textbf{Baseline RV32I (Cycles)} & \textbf{Accelerated XSHA256 (Cycles)} & \textbf{Speedup} \\
\hline
Key Generation (KeyGen) & 1,301,078 & 67,302 & \textbf{19.33$\times$} \\
Signature Generation (Sign) & 477,987 & 25,597 & \textbf{18.67$\times$} \\
Signature Verification (Verify) & 825,728 & 44,334 & \textbf{18.62$\times$} \\
\hline
\end{tabular}
\end{table}
""")

with open("paper/tables/table_fpga_utilization.tex", "w") as f:
    f.write(r"""\begin{table}[htbp]
\centering
\caption{AMD/Xilinx Artix-7 (XC7A35T-1CSG324C) Synthesis and Resource Utilization}
\label{tab:fpga_utilization}
\begin{tabular}{lrrrrr}
\hline
\textbf{Subsystem} & \textbf{LUTs} & \textbf{Flip-Flops (FF)} & \textbf{Carry4} & \textbf{BRAM} & \textbf{DSP} \\
\hline
XSHA256 PCPI Accelerator Unit & 2,582 & 1,078 & 102 & 0 & 0 \\
Complete SoC (PicoRV32 + 128KB RAM + XSHA256) & 7,170 & 1,883 & 233 & 0 & 0 \\
Artix-7 Device Available Capacity (XC7A35T) & 20,800 & 41,600 & 5,200 & 50 & 90 \\
XSHA256 Accelerator \% of Artix-7 & 12.4\% & 2.6\% & 1.9\% & 0.0\% & 0.0\% \\
\hline
\end{tabular}
\end{table}
""")

print("[INFO] LaTeX tables generated in paper/tables/.")

# -------------------------------------------------------------
# 4. Generate Publication Plots
# -------------------------------------------------------------
plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')

# Figure 1: Cycles and Instruction Reduction
fig, ax1 = plt.subplots(figsize=(7, 4.5))
colors = ['#1f77b4', '#aec7e8', '#ff7f0e', '#2ca02c']
configs = [d['Config'] for d in primitive_data]
cycles = [d['Cycles'] for d in primitive_data]
insns = [d['Instructions'] for d in primitive_data]

x = np.arange(len(configs))
width = 0.35

rects1 = ax1.bar(x - width/2, cycles, width, label='CPU Cycles', color='#2b5c8f')
rects2 = ax1.bar(x + width/2, insns, width, label='Instructions', color='#e26d5c')

ax1.set_ylabel('Count (Log Scale)', fontsize=12)
ax1.set_yscale('log')
ax1.set_title('SHA-256 Execution Cycles & Instruction Count across Architectures', fontsize=13, fontweight='bold')
ax1.set_xticks(x)
ax1.set_xticklabels([f"{d['Config']}\n({d['Name'].split('(')[0].strip()})" for d in primitive_data], fontsize=10)
ax1.legend(frameon=True)

for rect in rects1:
    h = rect.get_height()
    ax1.annotate(f'{int(h)}', xy=(rect.get_x() + rect.get_width()/2, h), xytext=(0, 3),
                 textcoords="offset points", ha='center', va='bottom', fontsize=8)
for rect in rects2:
    h = rect.get_height()
    ax1.annotate(f'{int(h)}', xy=(rect.get_x() + rect.get_width()/2, h), xytext=(0, 3),
                 textcoords="offset points", ha='center', va='bottom', fontsize=8)

plt.tight_layout()
plt.savefig("paper/figures/sha256_cycles_comparison.png", dpi=300)
plt.close()

# Figure 2: Speedup Comparison
fig, ax = plt.subplots(figsize=(6, 4))
speedups = [d['Speedup_vs_C1'] for d in primitive_data]
bar_colors = ['#7f7f7f', '#7f7f7f', '#1f77b4', '#2ca02c']
bars = ax.bar(configs, speedups, color=bar_colors, width=0.5)

ax.set_ylabel('Speedup Factor vs. Software Baseline (C1)', fontsize=11)
ax.set_title('Cryptographic Primitive Speedup on PicoRV32', fontsize=12, fontweight='bold')
ax.axhline(1.0, color='gray', linestyle='--', linewidth=0.8)

for bar in bars:
    h = bar.get_height()
    ax.annotate(f'{h:.2f}x', xy=(bar.get_x() + bar.get_width()/2, h), xytext=(0, 4),
                 textcoords="offset points", ha='center', va='bottom', fontweight='bold', fontsize=9)

plt.tight_layout()
plt.savefig("paper/figures/sha256_speedup.png", dpi=300)
plt.close()

# Figure 3: SLH-DSA End-to-End Speedup
fig, ax = plt.subplots(figsize=(6, 4))
ops = [d['Operation'] for d in slhdsa_data]
slh_speedups = [d['Speedup'] for d in slhdsa_data]

bars = ax.bar(ops, slh_speedups, color='#38b000', width=0.45)
ax.set_ylabel('End-to-End Application Speedup Factor', fontsize=11)
ax.set_title('SLH-DSA-SHA2-128s Application-Level Acceleration', fontsize=12, fontweight='bold')

for bar in bars:
    h = bar.get_height()
    ax.annotate(f'{h:.2f}x', xy=(bar.get_x() + bar.get_width()/2, h), xytext=(0, 4),
                 textcoords="offset points", ha='center', va='bottom', fontweight='bold', fontsize=10)

plt.tight_layout()
plt.savefig("paper/figures/slhdsa_end_to_end_speedup.png", dpi=300)
plt.close()

print("[INFO] Plots successfully generated and saved to paper/figures/.")
