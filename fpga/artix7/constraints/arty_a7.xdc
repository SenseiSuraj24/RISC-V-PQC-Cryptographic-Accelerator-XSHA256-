## Digilent Arty A7 (Xilinx Artix-7 XC7A35T-1CSG324C) Constraints
## XSHA256 Cryptographic Accelerator SoC

## Clock signal (100 MHz onboard oscillator)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports { clk }];

## Reset Button (Active Low resetn on Button 0)
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { resetn }];

## Status LEDs
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { trap }];        # LED 0: CPU Trap (Red/Alert)
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { sim_finish }]; # LED 1: Execution Finished
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { sim_pass }];   # LED 2: Benchmark Passed (Green)

## UART / Serial Console
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }];
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { uart_rx }];

