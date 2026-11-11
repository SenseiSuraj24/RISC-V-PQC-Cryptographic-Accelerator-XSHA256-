# XSHA256 Custom Instruction Set Architecture (ISA) Specification

## 1. Overview
The XSHA256 extension is a private cryptographic instruction set extension for RISC-V RV32I cores (specifically targeting PicoRV32 via the Pico Co-Processor Interface, PCPI).
It accelerates the SHA-256 cryptographic hash function (NIST FIPS 180-4) by executing the SHA-256 message schedule expansion and compression datapath in dedicated hardware.

All instructions use the standard RISC-V `custom-0` opcode space (`opcode = 7'b0001011` / `0x0B`).

## 2. Canonical Instruction Encoding Table

| Instruction | opcode (6:0) | funct3 (14:12) | funct7 (31:25) | rs1 (19:15) | rs2 (24:20) | rd (11:7) | Accelerator Latency | Hardware Action |
|:------------|:-------------|:---------------|:---------------|:------------|:------------|:----------|:--------------------|:----------------|
| `sha256.init` | `0001011` (0x0B) | `000` | `0000000` | reserved (x0) | reserved (x0) | reserved (x0) | 1 cycle | Resets internal A..H registers to FIPS 180-4 standard IV ($H^{(0)}$) or resets accumulators. Clears round counter ($t=0$) and rolling buffer index. |
| `sha256.load` | `0001011` (0x0B) | `001` | `0000000` | $rs1$ = 32-bit word | reserved (x0) | reserved (x0) | 1 cycle | Stores 32-bit big-endian message word into the 16-word circular message schedule buffer $W[load\_idx]$ and increments $load\_idx$. |
| `sha256.round` | `0001011` (0x0B) | `010` | `0000000` | reserved (x0) | reserved (x0) | reserved (x0) | 1 cycle | Computes $W[t]$ (rolling schedule expansion for $t \ge 16$), applies round constants $K[t]$, executes single compression round on $A..H$, and increments round counter $t$. On $t=63$, accumulates into hash state. |
| `sha256.getstate` | `0001011` (0x0B) | `011` | `0000000` | $rs1[2:0]$ = index | reserved (x0) | $rd$ = state word | 1 cycle | Copies 32-bit state word $H[rs1[2:0]]$ (0 for H0/A through 7 for H7/H) into general-purpose register $rd$. |
| `sha256.compress` | `0001011` (0x0B) | `100` | `0000000` | reserved (x0) | reserved (x0) | reserved (x0) | 64 cycles | Autonomous block compression: hardware asserts `pcpi_wait` and executes all 64 rounds sequentially in 64 clock cycles, performing block accumulation on completion. |

## 3. R-Type Instruction Format

```text
 31         25 24     20 19     15 14   12 11      7 6            0
+-------------+---------+---------+------+---------+---------------+
|   funct7    |   rs2   |   rs1   |funct3|   rd    | custom-0      |
|   0000000   |  00000  |  src1   |000.. |  dest   | 0001011 (0x0B)|
+-------------+---------+---------+------+---------+---------------+
```

## 4. Architectural Notes
- The rolling message buffer uses 16 32-bit registers ($W[0..15]$).
- For $t \ge 16$, the schedule calculation:
  $$W[t] = \sigma_1(W[(t-2)\pmod{16}]) + W[(t-7)\pmod{16}] + \sigma_0(W[(t-15)\pmod{16}]) + W[(t-16)\pmod{16}]$$
  reads four historical entries and updates $W[t \pmod{16}]$ after round $t$ evaluation, preserving required context.
- Software is freed from calculating the 48 extended words in software, drastically reducing instruction count and memory register pressure.

