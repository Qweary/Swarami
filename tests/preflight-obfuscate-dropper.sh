#!/bin/bash
# tests/preflight-obfuscate-dropper.sh
# Pre-flight validation: ADS-Dropper.ps1 GenerateOnly mode for all -Obfuscate tiers
# Runs on Linux without Windows VM requirement

set -e  # Exit on first error

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ Pre-Flight: ADS-Dropper.ps1 -GenerateOnly (All Tiers)    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

for tier in None Basic Advanced Paranoid; do
  echo "[*] Testing -Obfuscate $tier..."

  result=$(pwsh -NoProfile -Command "
    \$ErrorActionPreference = 'Stop'

    # Call Dropper in GenerateOnly mode
    \$config = ./src/ADS-Dropper.ps1 \
      -Obfuscate $tier \
      -Payload 'Test-Payload' \
      -GenerateOnly

    # Validate required fields exist
    if (-not \$config.GHKFunctionName) { throw 'Missing GHKFunctionName' }
    if (-not \$config.DecFunctionName) { throw 'Missing DecFunctionName' }
    if (-not \$config.TaskName) { throw 'Missing TaskName' }
    if (-not \$config.TaskSuffix) { throw 'Missing TaskSuffix' }
    if (-not \$config.ObfuscationLevel) { throw 'Missing ObfuscationLevel' }

    # Validate ObfuscationLevel matches input
    if (\$config.ObfuscationLevel -ne '$tier') {
      throw \"ObfuscationLevel mismatch: expected '$tier', got \$(\$config.ObfuscationLevel)\"
    }

    # Validate naming conventions per tier
    switch ('$tier') {
      'None' {
        if (\$config.GHKFunctionName -ne 'GHK') { throw 'None tier: GHK should be hardcoded' }
        if (\$config.DecFunctionName -ne 'Dec') { throw 'None tier: Dec should be hardcoded' }
        if (\$config.TaskName -ne 'SystemOptimization') { throw 'None tier: TaskName should be hardcoded' }
        if (\$config.TaskSuffix -ne '_Companion') { throw 'None tier: TaskSuffix should be hardcoded' }
      }
      'Basic' {
        if (\$config.GHKFunctionName -ne 'Get-HostKey') { throw 'Basic tier: GHK should be Get-HostKey' }
        if (\$config.DecFunctionName -ne 'Unprotect-Data') { throw 'Basic tier: Dec should be Unprotect-Data' }
      }
      'Advanced' {
        # Should be Verb-Noun format
        if (\$config.GHKFunctionName -notmatch '^[A-Z][a-z]+-[A-Z]') { throw 'Advanced tier: GHK should be Verb-Noun' }
        if (\$config.DecFunctionName -notmatch '^[A-Z][a-z]+-[A-Z]') { throw 'Advanced tier: Dec should be Verb-Noun' }
      }
      'Paranoid' {
        # Functions should still be Verb-Noun (no ZW chars in function names)
        if (\$config.GHKFunctionName -notmatch '^[A-Z][a-z]+-[A-Z]') { throw 'Paranoid tier: GHK should be Verb-Noun' }
        if (\$config.DecFunctionName -notmatch '^[A-Z][a-z]+-[A-Z]') { throw 'Paranoid tier: Dec should be Verb-Noun' }
        # ZeroWidthStreams should be auto-enabled
        if (-not \$config.ZeroWidthMode) { throw 'Paranoid tier: ZeroWidthMode should be set' }
      }
    }

    # Validate tier-implied defaults
    if ('$tier' -in @('Advanced', 'Paranoid')) {
      if (-not \$config.DeepPlacement) { throw '$tier tier: DeepPlacement should be auto-enabled' }
      if (-not \$config.AttachToExisting) { throw '$tier tier: AttachToExisting should be auto-enabled' }
      if (-not \$config.Randomized) { throw '$tier tier: Randomized should be auto-enabled' }
    }

    Write-Output 'PASS'
  " 2>&1)

  if [[ "$result" != *"PASS"* ]]; then
    echo "❌ FAIL: $tier tier"
    echo "$result"
    exit 1
  fi

  echo "✓ PASS: $tier tier"
done

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ ALL DROPPER GENERATEONLY TESTS PASSED                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

exit 0
