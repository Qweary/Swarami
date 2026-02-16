#!/bin/bash
#
# Quick validation wrapper for ccdc-library.ps1 changes
# Runs automated tests and displays pass/fail status
#
# Usage:
#   ./tests/quick-validate.sh
#   bash tests/quick-validate.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Quick Validation: CCDC Payload Library"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Project root: $PROJECT_ROOT"
echo "Test script: $SCRIPT_DIR/validate-ccdc-library.ps1"
echo ""

# Check if pwsh is available
if ! command -v pwsh &> /dev/null; then
    echo "ERROR: pwsh (PowerShell 7.x) not found"
    echo "Install: sudo apt install powershell -y"
    exit 1
fi

echo "PowerShell version:"
pwsh -NoProfile -Command '$PSVersionTable.PSVersion | Format-Table'
echo ""

# Run validation script
cd "$PROJECT_ROOT"
pwsh -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/validate-ccdc-library.ps1"

# Capture exit code
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "════════════════════════════════════════════════════════════"
    echo "  ✓ VALIDATION PASSED — Library is safe to use"
    echo "════════════════════════════════════════════════════════════"
else
    echo "════════════════════════════════════════════════════════════"
    echo "  ✗ VALIDATION FAILED — Fix issues before deployment"
    echo "════════════════════════════════════════════════════════════"
fi
echo ""

exit $EXIT_CODE
