#!/bin/bash
# =============================================================================
# run_proofs.sh — Run all 5 XSHA256 instruction proof testbenches
# Usage: bash scripts/run_proofs.sh
# =============================================================================

set -e
cd "$(dirname "$0")/.."

IVERILOG="tools/oss-cad-suite/bin/iverilog"
VVP="tools/oss-cad-suite/bin/vvp"
RTL="rtl/sha256"
PROOF="testbench/proof"

mkdir -p build/proof

RTL_SRCS="$RTL/sha256_constants.sv $RTL/sha256_round.sv $RTL/sha256_schedule.sv $RTL/sha256_core.sv"

PASS=0
FAIL=0
RESULTS=()

run_proof() {
    local name="$1"
    local tb="$2"
    local bin="build/proof/sim_proof_${name}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  PROOF: sha256.${name}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    $IVERILOG -g2012 -I$RTL -o "$bin" $RTL_SRCS "$PROOF/$tb" 2>&1

    output=$($VVP "$bin" 2>&1)
    echo "$output"

    if echo "$output" | grep -q "PASSED"; then
        PASS=$((PASS + 1))
        RESULTS+=("  ✅  sha256.${name}")
    else
        FAIL=$((FAIL + 1))
        RESULTS+=("  ❌  sha256.${name}")
    fi
}

echo "============================================================"
echo "   XSHA256 ISA Extension — Instruction Proof Suite"
echo "   NIST FIPS 180-4 SHA-256 Compliance Verification"
echo "============================================================"

run_proof "init"       "tb_proof_init.sv"
run_proof "load"       "tb_proof_load.sv"
run_proof "round"      "tb_proof_round.sv"
run_proof "getstate"   "tb_proof_getstate.sv"
run_proof "compress"   "tb_proof_compress.sv"

echo ""
echo "============================================================"
echo "   PROOF SUITE SUMMARY"
echo "============================================================"
for r in "${RESULTS[@]}"; do
    echo "$r"
done
echo ""
echo "  PASSED: $PASS / 5"
echo "  FAILED: $FAIL / 5"

if [ "$FAIL" -eq 0 ]; then
    echo ""
    echo "  🎓 ALL PROOFS PASSED — XSHA256 instructions correctly"
    echo "     implement SHA-256 per NIST FIPS 180-4"
fi
echo "============================================================"
