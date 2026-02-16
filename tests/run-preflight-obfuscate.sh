#!/bin/bash
# tests/run-preflight-obfuscate.sh
# Master test runner for -Obfuscate parameter pre-flight validation
# Runs all automated Linux-side tests before VM validation

set -e  # Exit on first error

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ OBFUSCATE PARAMETER: PRE-FLIGHT TEST SUITE               ║"
echo "║ ADS v2.4 Candidate Validation                            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Running automated tests on Linux (no Windows VM required)"
echo "Estimated time: 2-3 minutes"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test 1: Dropper GenerateOnly for all tiers
echo "═══════════════════════════════════════════════════════════"
echo "TEST 1/4: Dropper GenerateOnly Mode"
echo "═══════════════════════════════════════════════════════════"
bash "$SCRIPT_DIR/preflight-obfuscate-dropper.sh"

# Test 2: OneLiner output generation for all tiers
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "TEST 2/4: OneLiner Output Generation"
echo "═══════════════════════════════════════════════════════════"
bash "$SCRIPT_DIR/preflight-obfuscate-oneliner.sh"

# Test 3: PowerShell syntax validation
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "TEST 3/4: PowerShell Syntax Validation"
echo "═══════════════════════════════════════════════════════════"
bash "$SCRIPT_DIR/preflight-syntax-validation.sh"

# Test 4: Naming convention validation
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "TEST 4/4: Naming Convention Validation"
echo "═══════════════════════════════════════════════════════════"
bash "$SCRIPT_DIR/preflight-naming-validation.sh"

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ ✓ ALL PRE-FLIGHT TESTS PASSED                            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Review generated output files: test-oneliner-*.txt"
echo "  2. Review manifests: ls -lh ./manifests/manifest-*.json"
echo "  3. Proceed to VM validation (tests/VALIDATION-OBFUSCATE.md)"
echo ""
echo "VM must-test scenarios:"
echo "  - Test 1: Backward compatibility (-Obfuscate None)"
echo "  - Test 2: Advanced tier + registry persistence"
echo "  - Test 3: Paranoid tier + zero-width chars"
echo "  - Test 4: Override behavior"
echo ""

exit 0
