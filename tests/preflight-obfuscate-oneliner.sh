#!/bin/bash
# tests/preflight-obfuscate-oneliner.sh
# Pre-flight validation: ADS-OneLiner.ps1 output generation for all -Obfuscate tiers
# Runs on Linux without Windows VM requirement

set -e  # Exit on first error

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ Pre-Flight: ADS-OneLiner.ps1 Output Generation           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Clean previous test outputs
rm -f test-oneliner-*.txt
rm -f test-script-*.ps1

for tier in None Basic Advanced Paranoid; do
  echo "[*] Testing OneLiner generation: -Obfuscate $tier..."

  pwsh -NoProfile -Command "
    \$ErrorActionPreference = 'Stop'

    ./src/ADS-OneLiner.ps1 \
      -Obfuscate $tier \
      -Payload 'Write-Host \"Test-$tier\" -ForegroundColor Green' \
      -Persist task \
      -OutputFile test-oneliner-$tier.txt
  " 2>&1 | tee /tmp/oneliner-$tier.log

  # Validate output file exists
  if [ ! -f "test-oneliner-$tier.txt" ]; then
    echo "❌ FAIL: Output file not created for $tier"
    exit 1
  fi

  # Validate base64 one-liner present
  if ! grep -q "powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand" "test-oneliner-$tier.txt"; then
    echo "❌ FAIL: Base64 one-liner not found in output for $tier"
    cat "test-oneliner-$tier.txt"
    exit 1
  fi

  # Validate manifest created (should be in ./manifests/ directory)
  manifest_count=$(find ./manifests -name "manifest-*.json" -mmin -1 2>/dev/null | wc -l)
  if [ "$manifest_count" -eq 0 ]; then
    echo "❌ FAIL: Manifest not created for $tier (checked ./manifests/)"
    exit 1
  fi

  # Validate readable script present (OPTION 2 section)
  if ! grep -q "OPTION 2: Readable Multi-Line Commands" "test-oneliner-$tier.txt"; then
    echo "❌ FAIL: Readable script section not found in output for $tier"
    exit 1
  fi

  echo "✓ PASS: $tier tier output generated"
done

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ ALL ONELINER GENERATION TESTS PASSED                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

exit 0
