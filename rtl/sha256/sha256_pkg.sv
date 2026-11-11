`ifndef SHA256_PKG_SV
`define SHA256_PKG_SV

package sha256_pkg;

    // Standard SHA-256 initial hash values (IV)
    localparam logic [31:0] SHA256_H0 = 32'h6a09e667;
    localparam logic [31:0] SHA256_H1 = 32'hbb67ae85;
    localparam logic [31:0] SHA256_H2 = 32'h3c6ef372;
    localparam logic [31:0] SHA256_H3 = 32'ha54ff53a;
    localparam logic [31:0] SHA256_H4 = 32'h510e527f;
    localparam logic [31:0] SHA256_H5 = 32'h9b05688c;
    localparam logic [31:0] SHA256_H6 = 32'h1f83d9ab;
    localparam logic [31:0] SHA256_H7 = 32'h5be0cd19;

    // Right rotate helper function
    function automatic [31:0] rotr(input [31:0] x, input integer n);
    begin
        rotr = (x >> n) | (x << (32 - n));
    end
    endfunction

    // Ch(x, y, z) = (x & y) ^ (~x & z)
    function automatic [31:0] ch(input [31:0] x, input [31:0] y, input [31:0] z);
    begin
        ch = (x & y) ^ ((~x) & z);
    end
    endfunction

    // Maj(x, y, z) = (x & y) ^ (x & z) ^ (y & z)
    function automatic [31:0] maj(input [31:0] x, input [31:0] y, input [31:0] z);
    begin
        maj = (x & y) ^ (x & z) ^ (y & z);
    end
    endfunction

    // Sigma0(x) = ROTR^2(x) ^ ROTR^13(x) ^ ROTR^22(x)
    function automatic [31:0] sigma0(input [31:0] x);
    begin
        sigma0 = rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
    end
    endfunction

    // Sigma1(x) = ROTR^6(x) ^ ROTR^11(x) ^ ROTR^25(x)
    function automatic [31:0] sigma1(input [31:0] x);
    begin
        sigma1 = rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
    end
    endfunction

    // sigma0(x) = ROTR^7(x) ^ ROTR^18(x) ^ (x >> 3)
    function automatic [31:0] sig0(input [31:0] x);
    begin
        sig0 = rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
    end
    endfunction

    // sigma1(x) = ROTR^17(x) ^ ROTR^19(x) ^ (x >> 10)
    function automatic [31:0] sig1(input [31:0] x);
    begin
        sig1 = rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);
    end
    endfunction

endpackage

`endif
