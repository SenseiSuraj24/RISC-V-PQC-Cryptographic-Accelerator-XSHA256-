// Standard SHA-256 initial hash values (IV)
localparam [31:0] SHA256_H0 = 32'h6a09e667;
localparam [31:0] SHA256_H1 = 32'hbb67ae85;
localparam [31:0] SHA256_H2 = 32'h3c6ef372;
localparam [31:0] SHA256_H3 = 32'ha54ff53a;
localparam [31:0] SHA256_H4 = 32'h510e527f;
localparam [31:0] SHA256_H5 = 32'h9b05688c;
localparam [31:0] SHA256_H6 = 32'h1f83d9ab;
localparam [31:0] SHA256_H7 = 32'h5be0cd19;

// Inlined bitwise rotation and SHA-256 primitives
`define ROTR(x, n)   (((x) >> (n)) | ((x) << (32 - (n))))
`define CH(x, y, z)  (((x) & (y)) ^ (~(x) & (z)))
`define MAJ(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
`define SIGMA0(x)    (`ROTR(x, 2) ^ `ROTR(x, 13) ^ `ROTR(x, 22))
`define SIGMA1(x)    (`ROTR(x, 6) ^ `ROTR(x, 11) ^ `ROTR(x, 25))
`define SIG0(x)      (`ROTR(x, 7) ^ `ROTR(x, 18) ^ ((x) >> 3))
`define SIG1(x)      (`ROTR(x, 17) ^ `ROTR(x, 19) ^ ((x) >> 10))
