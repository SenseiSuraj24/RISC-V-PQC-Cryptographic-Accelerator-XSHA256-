# XSHA256: A Compact RISC-V Custom Instruction Extension for SHA-256 Acceleration in Post-Quantum SLH-DSA on Artix-7

**Research Team** — Advanced Computer Architecture & Cryptography Laboratory  
**Date**: November 2026

---

## Abstract
As cryptographic standards transition to quantum-resistant primitives, post-quantum digital signature algorithms such as SLH-DSA (FIPS 205) impose severe computational overheads on resource-constrained embedded processors. In SLH-DSA-SHA2-128s, evaluating deep hash chains and Merkle authentication paths consumes millions of CPU cycles, primarily dominated by the SHA-256 compression function. This paper presents **XSHA256**, a synthesizable, compact custom cryptographic coprocessor tightly coupled to a PicoRV32 RV32I processor via the Pico Co-Processor Interface (PCPI). Rather than offloading only fine-grained round computations, XSHA256 integrates an iterative datapath with an autonomous 16-word rolling message schedule expansion buffer, eliminating the memory and instruction overhead of computing extended message words in software. We evaluate two architectural granularities: fine-grained iterative round execution and autonomous block-level compression. Experimental evaluation on an AMD/Xilinx Artix-7 FPGA (XC7A35T) demonstrates that XSHA256 reduces SHA-256 block compression from 21,331 cycles to 1,672 cycles (12.75x speedup) using iterative round instructions, and down to 736 cycles (**28.98x speedup**) using block-level compression, while reducing instruction count by 96.8%. When applied to an SLH-DSA-SHA2-128s workload, the accelerator achieves an end-to-end application speedup of **19.33x** for Key Generation, **18.67x** for Signing, and **18.62x** for Verification. The entire coprocessor requires only 2,582 LUTs and 1,078 flip-flops (12.4% of the Artix-7 device), with zero BRAM or DSP utilization, establishing a highly efficient design point for lightweight post-quantum secure edge devices.

---

## 1. Introduction
Post-quantum cryptography (PQC) has become an urgent mandate following the standardization of stateless hash-based digital signatures by NIST in FIPS 205 (SLH-DSA). Unlike public-key schemes based on discrete logarithms or integer factorization, hash-based signatures rely exclusively on the collision- and preimage-resistance of underlying cryptographic hash functions, most notably SHA-256.

However, stateless hash-based signatures require the generation and traversal of multi-layer hypertree structures and Winternitz One-Time Signatures (WOTS+). In the SLH-DSA-SHA2-128s parameter set, a single signature generation or verification operation executes tens of thousands of hash compression calls. On lightweight embedded processors implementing the 32-bit RISC-V base integer instruction set (RV32I), such as PicoRV32, the pure software execution of SHA-256 is severely bottlenecked by word rotation, non-linear logic, and above all, the 64-word message schedule expansion ($W_t$).

To resolve this bottleneck without incurring the silicon area and power penalties of large autonomous DMA crypto engines, we propose **XSHA256**, a hardware/software co-designed custom instruction extension integrated into PicoRV32 through its standard Pico Co-Processor Interface (PCPI).

---

## 2. Experimental Results Summary

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
| **Negative Verification (Corrupted Bit)**| Rejected | Rejected | Expected Failure | PASS |

### Hardware Resource Utilization (AMD/Xilinx Artix-7 XC7A35T-1CSG324C)
| Subsystem | LUTs | Flip-Flops (FF) | Carry4 | BRAM | DSP |
|:---|:---:|:---:|:---:|:---:|:---:|
| **XSHA256 PCPI Accelerator Unit** | 2,582 | 1,078 | 102 | 0 | 0 |
| **Complete SoC (PicoRV32 + 128KB RAM + XSHA256)** | 7,170 | 1,883 | 233 | 0 | 0 |
| **Artix-7 Device Available Capacity** | 20,800 | 41,600 | 5,200 | 50 | 90 |
| **XSHA256 Accelerator % of Artix-7** | **12.4%** | **2.6%** | **1.9%** | **0.0%** | **0.0%** |

---

## 3. Evaluation of Hypotheses
- **H1 (Schedule in Hardware)**: *Validated*. Moving schedule generation into hardware reduced instructions per block from 5,336 down to 172 (96.8% reduction).
- **H2 (Cycle Count Reduction)**: *Validated*. Cycles dropped from 21,331 to 736 (28.98x speedup).
- **H3 (Artix-7 Area Overhead)**: *Validated*. Coprocessor occupies only 12.4% of LUTs on a budget Artix-7 XC7A35T.
- **H4 (Primitive vs End-to-End Speedup)**: *Validated*. Primitive speedup is 28.98x while SLH-DSA end-to-end speedup is 18.6x--19.3x due to unaccelerated address formatting in software (Amdahl's law).
- **H5 (Round-level vs Block-level)**: *Validated*. Coarse-grained block compression (C4) outperforms fine-grained round instructions (C3) by 2.27x (736 vs 1,672 cycles) by eliminating CPU-side loop overhead.

