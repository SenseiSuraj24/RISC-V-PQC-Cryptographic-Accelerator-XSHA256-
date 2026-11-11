# Post-Quantum Cryptography Integration Notes: SLH-DSA-SHA2-128s

## 1. Overview
SLH-DSA (Stateless Hash-Based Digital Signature Algorithm), standardized in NIST FIPS 205 (formerly SPHINCS+), is a quantum-resistant digital signature scheme relying entirely on the security of cryptographic hash functions.
The parameter set **SLH-DSA-SHA2-128s** (small signature size at NIST Security Category 1) uses SHA-256 for all underlying hash computations.

## 2. Parameter Set Definition (NIST FIPS 205)
- **Security Parameter ($n$)**: 16 bytes (128 bits)
- **Total Tree Height ($h$)**: 63
- **Number of Tree Layers ($d$)**: 7
- **Subtree Height ($h' = h/d$)**: 9
- **Winternitz Parameter ($w$)**: 16 ($log_2(w) = 4$)
- **FORS Trees ($k$)**: 14
- **FORS Leaves ($t$)**: $2^{12} = 4096$
- **Public Key Size ($PK$)**: 32 bytes ($PK.seed$ [16B] + $PK.root$ [16B])
- **Secret Key Size ($SK$)**: 64 bytes ($SK.seed$ [16B] + $SK.prf$ [16B] + $PK.seed$ [16B] + $PK.root$ [16B])
- **Signature Size**: 7,856 bytes

## 3. Cryptographic Hash Primitives & Call Sites
All operations in SLH-DSA-SHA2-128s decompose into calls to three functions:
1. **$PRF(PK.seed, SK.seed, ADRS)$**:
   Pseudorandom key generation function used to derive secret values in WOTS+ and FORS.
   - Call pattern: Computes $SHA\text{-}256(PK.seed \parallel ADRS \parallel SK.seed)$.
   - Block length: 2 SHA-256 blocks (64B + 32B padded).
2. **$F(PK.seed, ADRS, M_1)$**:
   Single-block compression function used along WOTS+ hash chains.
   - Call pattern: Evaluates one SHA-256 compression per chain step.
   - Dominates signing and verification execution time!
3. **$H(PK.seed, ADRS, M_1 \parallel M_2)$**:
   Two-to-one tree hash function used to build Merkle subtrees and FORS roots.
   - Block length: 2 SHA-256 compression blocks.
4. **$H_{msg}(R, PK.seed, PK.root, M)$**:
   Randomized message hash producing the leaf and tree indices and FORS message digest.

## 4. Hardware/Software Co-Design Abstraction Layer
The application layer isolates cryptographic hashing through:
```c
void picoslh_hash_block(uint32_t state[8], const uint32_t block[16], int use_accel);
```
- When `use_accel == 0`: Executes software SHA-256 compression loop on RV32I.
- When `use_accel == 1`: Dispatches block loading and issues custom `sha256.compress` instruction over PCPI.

## 5. Acceleration Scope & Amdahl's Law
- **Accelerated Operations**:
  - WOTS+ chaining steps ($F$)
  - Merkle subtree hashing ($H$)
  - Secret key derivation ($PRF$)
- **Remaining Software Operations**:
  - Address structure ($ADRS$) manipulation and byte-swapping
  - Tree traversal and index calculation logic
  - Buffer copying and memory formatting
As predicted by hypothesis H4:
The primitive-level speedup (~29.5x on raw SHA-256 block compression) translates to an expected application-level speedup between 3x and 8x for end-to-end signature operations depending on memory bandwidth and tree indexing overhead.

