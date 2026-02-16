#!/bin/bash
# tests/preflight-naming-validation.sh
# Pre-flight validation: Verify obfuscation tiers produce correct naming styles
# Checks manifest files for tier-specific naming conventions

set -e  # Exit on first error

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ Pre-Flight: Naming Convention Validation                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "❌ FAIL: jq is not installed (required for JSON parsing)"
  echo "Install: sudo apt-get install jq"
  exit 1
fi

# Find the 4 most recent manifests (one per tier)
mapfile -t manifests < <(find ./manifests -name "manifest-*.json" -mmin -5 2>/dev/null | sort -r | head -4)

if [ ${#manifests[@]} -lt 4 ]; then
  echo "❌ FAIL: Expected 4 recent manifests, found ${#manifests[@]}"
  echo "Run preflight-obfuscate-oneliner.sh first to generate manifests."
  exit 1
fi

echo "[*] Validating naming conventions from manifests..."

# Test None tier: hardcoded legacy names
echo ""
echo "[*] Testing None tier naming..."
manifest_none=$(echo "${manifests[@]}" | tr ' ' '\n' | while read f; do
  tier=$(jq -r '.ObfuscationLevel' "$f" 2>/dev/null)
  if [ "$tier" = "None" ]; then echo "$f"; break; fi
done)

if [ -z "$manifest_none" ]; then
  echo "❌ FAIL: No manifest found for None tier"
  exit 1
fi

ghk_none=$(jq -r '.GHKFunctionName' "$manifest_none")
dec_none=$(jq -r '.DecFunctionName' "$manifest_none")
task_none=$(jq -r '.TaskName' "$manifest_none")
suffix_none=$(jq -r '.TaskSuffix' "$manifest_none")

if [ "$ghk_none" != "GHK" ]; then
  echo "❌ FAIL: None tier GHKFunctionName should be 'GHK', got '$ghk_none'"
  exit 1
fi
if [ "$dec_none" != "Dec" ]; then
  echo "❌ FAIL: None tier DecFunctionName should be 'Dec', got '$dec_none'"
  exit 1
fi
if [ "$task_none" != "SystemOptimization" ]; then
  echo "❌ FAIL: None tier TaskName should be 'SystemOptimization', got '$task_none'"
  exit 1
fi
if [ "$suffix_none" != "_Companion" ]; then
  echo "❌ FAIL: None tier TaskSuffix should be '_Companion', got '$suffix_none'"
  exit 1
fi
echo "✓ PASS: None tier naming (hardcoded legacy)"

# Test Basic tier: static legitimate names
echo ""
echo "[*] Testing Basic tier naming..."
manifest_basic=$(echo "${manifests[@]}" | tr ' ' '\n' | while read f; do
  tier=$(jq -r '.ObfuscationLevel' "$f" 2>/dev/null)
  if [ "$tier" = "Basic" ]; then echo "$f"; break; fi
done)

if [ -z "$manifest_basic" ]; then
  echo "❌ FAIL: No manifest found for Basic tier"
  exit 1
fi

ghk_basic=$(jq -r '.GHKFunctionName' "$manifest_basic")
dec_basic=$(jq -r '.DecFunctionName' "$manifest_basic")

if [ "$ghk_basic" != "Get-HostKey" ]; then
  echo "❌ FAIL: Basic tier GHKFunctionName should be 'Get-HostKey', got '$ghk_basic'"
  exit 1
fi
if [ "$dec_basic" != "Unprotect-Data" ]; then
  echo "❌ FAIL: Basic tier DecFunctionName should be 'Unprotect-Data', got '$dec_basic'"
  exit 1
fi
echo "✓ PASS: Basic tier naming (static legitimate)"

# Test Advanced tier: random verb-noun, no zero-width
echo ""
echo "[*] Testing Advanced tier naming..."
manifest_adv=$(echo "${manifests[@]}" | tr ' ' '\n' | while read f; do
  tier=$(jq -r '.ObfuscationLevel' "$f" 2>/dev/null)
  if [ "$tier" = "Advanced" ]; then echo "$f"; break; fi
done)

if [ -z "$manifest_adv" ]; then
  echo "❌ FAIL: No manifest found for Advanced tier"
  exit 1
fi

ghk_adv=$(jq -r '.GHKFunctionName' "$manifest_adv")
dec_adv=$(jq -r '.DecFunctionName' "$manifest_adv")
task_adv=$(jq -r '.TaskName' "$manifest_adv")

# Verb-Noun format: starts with uppercase letter, contains hyphen, no special chars
if ! echo "$ghk_adv" | grep -Pq '^[A-Z][a-z]+-[A-Z][a-zA-Z]+$'; then
  echo "❌ FAIL: Advanced tier GHKFunctionName should be Verb-Noun format, got '$ghk_adv'"
  exit 1
fi
if ! echo "$dec_adv" | grep -Pq '^[A-Z][a-z]+-[A-Z][a-zA-Z]+$'; then
  echo "❌ FAIL: Advanced tier DecFunctionName should be Verb-Noun format, got '$dec_adv'"
  exit 1
fi
# Task name should be from legitimate word list (alphanumeric only, no ZW chars)
if echo "$task_adv" | grep -Pq '[^\x00-\x7F]'; then
  echo "⚠️  WARN: Advanced tier TaskName contains non-ASCII chars: '$task_adv'"
  echo "    Expected ASCII-only for Advanced tier (Paranoid adds ZW chars)"
fi
echo "✓ PASS: Advanced tier naming (random Verb-Noun)"

# Test Paranoid tier: random verb-noun in functions, ZW in task name (maybe)
echo ""
echo "[*] Testing Paranoid tier naming..."
manifest_para=$(echo "${manifests[@]}" | tr ' ' '\n' | while read f; do
  tier=$(jq -r '.ObfuscationLevel' "$f" 2>/dev/null)
  if [ "$tier" = "Paranoid" ]; then echo "$f"; break; fi
done)

if [ -z "$manifest_para" ]; then
  echo "❌ FAIL: No manifest found for Paranoid tier"
  exit 1
fi

ghk_para=$(jq -r '.GHKFunctionName' "$manifest_para")
dec_para=$(jq -r '.DecFunctionName' "$manifest_para")
task_para=$(jq -r '.TaskName' "$manifest_para")

# Functions should still be Verb-Noun (NO zero-width chars in function names)
if ! echo "$ghk_para" | grep -Pq '^[A-Z][a-z]+-[A-Z][a-zA-Z]+$'; then
  echo "❌ FAIL: Paranoid tier GHKFunctionName should be Verb-Noun (no ZW), got '$ghk_para'"
  exit 1
fi
if ! echo "$dec_para" | grep -Pq '^[A-Z][a-z]+-[A-Z][a-zA-Z]+$'; then
  echo "❌ FAIL: Paranoid tier DecFunctionName should be Verb-Noun (no ZW), got '$dec_para'"
  exit 1
fi

# Task name MAY contain zero-width chars (random injection)
# Check manifest for codepoints field
codepoints=$(jq -r '.Codepoints' "$manifest_para")
if echo "$codepoints" | grep -q "U+200B\|U+200C\|U+200D\|U+200E\|U+200F\|U+FEFF"; then
  echo "✓ INFO: Paranoid tier TaskName contains zero-width codepoints"
else
  echo "⚠️  INFO: Paranoid tier TaskName does not contain ZW chars (random injection may not have triggered)"
fi

echo "✓ PASS: Paranoid tier naming (functions clean, task may have ZW)"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ ALL NAMING VALIDATION TESTS PASSED                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

exit 0
