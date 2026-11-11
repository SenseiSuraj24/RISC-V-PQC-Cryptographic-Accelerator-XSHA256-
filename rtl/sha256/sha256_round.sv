`timescale 1ns / 1ps

module sha256_round (
    input  logic [31:0] a, b, c, d, e, f, g, h,
    input  logic [31:0] w,
    input  logic [31:0] k,
    output logic [31:0] next_a, next_b, next_c, next_d,
    output logic [31:0] next_e, next_f, next_g, next_h
);

    `include "sha256_funcs.vh"

    logic [31:0] s1_e, ch_efg, t1;
    logic [31:0] s0_a, maj_abc, t2;

    always_comb begin
        s1_e    = `SIGMA1(e);
        ch_efg  = `CH(e, f, g);
        t1      = h + s1_e + ch_efg + k + w;

        s0_a    = `SIGMA0(a);
        maj_abc = `MAJ(a, b, c);
        t2      = s0_a + maj_abc;

        next_a  = t1 + t2;
        next_b  = a;
        next_c  = b;
        next_d  = c;
        next_e  = d + t1;
        next_f  = e;
        next_g  = f;
        next_h  = g;
    end

endmodule
