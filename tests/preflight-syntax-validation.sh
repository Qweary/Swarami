#!/bin/bash
# tests/preflight-syntax-validation.sh
# Pre-flight validation: PowerShell syntax check for generated readable scripts
# Uses PSParser::Tokenize() to catch syntax errors before VM testing

set -e  # Exit on first error

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ Pre-Flight: Syntax Validation (PSParser)                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

for tier in None Basic Advanced Paranoid; do
  echo "[*] Validating syntax: $tier tier..."

  # Extract readable script from output file (between "OPTION 2" markers)
  # Use awk to extract the script block
  awk '
    /OPTION 2: Readable Multi-Line Commands/ { capture=1; skip=3; next }
    /╔═══════════════════════════════════════════════════════════╗/ && capture { exit }
    capture && skip > 0 { skip--; next }
    capture { print }
  ' "test-oneliner-$tier.txt" > "test-script-$tier.ps1"

  # Verify extraction succeeded (file should not be empty)
  if [ ! -s "test-script-$tier.ps1" ]; then
    echo "❌ FAIL: Could not extract readable script for $tier"
    echo "Output file content:"
    cat "test-oneliner-$tier.txt"
    exit 1
  fi

  # Use PowerShell's PSParser to tokenize (catches syntax errors)
  pwsh -NoProfile -Command "
    \$ErrorActionPreference = 'Stop'

    \$script = Get-Content 'test-script-$tier.ps1' -Raw
    \$tokens = \$null
    \$errors = \$null

    try {
      [System.Management.Automation.PSParser]::Tokenize(\$script, [ref]\$errors) | Out-Null
    } catch {
      Write-Error \"Tokenization failed: \$_\"
      exit 1
    }

    if (\$errors.Count -gt 0) {
      Write-Error 'Syntax errors detected in generated script:'
      \$errors | ForEach-Object {
        Write-Error \"  Line \$(\$_.Token.StartLine): \$(\$_.Message)\"
      }
      exit 1
    }

    Write-Output 'PASS'
  " 2>&1 | tee /tmp/syntax-$tier.log

  if ! grep -q "PASS" /tmp/syntax-$tier.log; then
    echo "❌ FAIL: Syntax validation failed for $tier"
    echo "Generated script:"
    cat "test-script-$tier.ps1"
    exit 1
  fi

  echo "✓ PASS: $tier tier syntax valid"
done

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ ALL SYNTAX VALIDATION TESTS PASSED                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

exit 0
