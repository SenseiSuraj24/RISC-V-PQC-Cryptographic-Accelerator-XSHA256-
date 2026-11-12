SHELL := /bin/bash

.PHONY: all software sim tb_sha tb_pcpi synth plots pdf clean test proof help

all: software sim

help:
	@echo "=========================================================="
	@echo "  RISC-V PQC XSHA256 Cryptographic Accelerator Makefile   "
	@echo "=========================================================="
	@echo "  make software : Compile RV32I bare-metal firmware"
	@echo "  make sim      : Run full PicoRV32 SoC simulation"
	@echo "  make tb_sha   : Run standalone SHA-256 RTL core testbench"
	@echo "  make tb_pcpi  : Run standalone PCPI interface testbench"
	@echo "  make proof    : Run per-instruction FIPS 180-4 proof suite"
	@echo "  make synth    : Run Artix-7 FPGA synthesis using Yosys"
	@echo "  make plots    : Generate CSVs, LaTeX tables, and plots"
	@echo "  make pdf      : Generate complete presentation & defense PDF"
	@echo "  make clean    : Remove build artifacts"

software:
	bash scripts/build_rv32.sh

sim: software
	bash scripts/run_sha_sim.sh

tb_sha:
	mkdir -p build
	tools/oss-cad-suite/bin/iverilog -g2012 -Irtl/sha256 -o build/sim_sha256 \
		rtl/sha256/sha256_constants.sv \
		rtl/sha256/sha256_round.sv \
		rtl/sha256/sha256_schedule.sv \
		rtl/sha256/sha256_core.sv \
		testbench/sha256/tb_sha256_core.sv
	tools/oss-cad-suite/bin/vvp build/sim_sha256

tb_pcpi:
	mkdir -p build
	tools/oss-cad-suite/bin/iverilog -g2012 -Irtl/sha256 -o build/sim_pcpi \
		rtl/sha256/sha256_constants.sv \
		rtl/sha256/sha256_round.sv \
		rtl/sha256/sha256_schedule.sv \
		rtl/sha256/sha256_core.sv \
		rtl/pcpi/xsha256_pcpi.sv \
		testbench/pcpi/tb_xsha256_pcpi.sv
	tools/oss-cad-suite/bin/vvp build/sim_pcpi

synth:
	bash scripts/synth_yosys.sh

plots:
	python3 scripts/generate_plots_and_tables.py

pdf:
	python3 scripts/generate_presentation_pdf.py

proof:
	bash scripts/run_proofs.sh

test: proof tb_sha tb_pcpi sim

clean:
	rm -rf build/*.elf build/*.bin build/*.hex build/*.dump build/*sim*
