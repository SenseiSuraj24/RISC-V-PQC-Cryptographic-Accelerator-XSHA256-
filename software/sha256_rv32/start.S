.section .text.init
.globl _start

_start:
    /* Initialize stack pointer */
    la sp, _stack_top
    /* Initialize global pointer if needed */
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    /* Clear BSS section */
    la t0, _sbss
    la t1, _ebss
bss_clear_loop:
    bge t0, t1, bss_clear_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j bss_clear_loop
bss_clear_done:

    /* Call main */
    call main

    /* Loop forever if main returns */
loop_forever:
    j loop_forever

