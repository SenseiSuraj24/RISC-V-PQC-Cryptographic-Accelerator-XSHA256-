`timescale 1ns / 1ps

module tb_debug_round;
    import sha256_pkg::*;

    logic [31:0] a, b, c, d, e, f, g, h;
    logic [31:0] na, nb, nc, nd, ne, nf, ng, nh;
    logic [31:0] w, k;

    sha256_round u_round (
        .a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g), .h(h),
        .w(w), .k(k),
        .next_a(na), .next_b(nb), .next_c(nc), .next_d(nd),
        .next_e(ne), .next_f(nf), .next_g(ng), .next_h(nh)
    );

    initial begin
        a = 32'h6a09e667;
        b = 32'hbb67ae85;
        c = 32'h3c6ef372;
        d = 32'ha54ff53a;
        e = 32'h510e527f;
        f = 32'h9b05688c;
        g = 32'h1f83d9ab;
        h = 32'h5be0cd19;
        w = 32'h61626380;
        k = 32'h428a2f98;

        #1;
        $display("RTL Round 0 next_a = %08x, next_e = %08x", na, ne);
        $display("sigma1(e) = %08x, ch = %08x", sigma1(e), ch(e,f,g));
        $display("sigma0(a) = %08x, maj = %08x", sigma0(a), maj(a,b,c));
    end
endmodule

