#!/bin/bash
# ============================================================
# Competition Deployment Script Generator
# ============================================================
# Generates all 6 deployment packages (primary + secondary for each tier)
# Run from project root: bash competition/generate-all-deployments.sh
# ============================================================

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ ADS Competition Deployment Generator - CCDC 2026          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Create output directory
mkdir -p competition/deployments
echo "[*] Output directory: competition/deployments/"
echo ""

# ============================================================
# TIER 1: Domain Controllers (Full Stealth)
# ============================================================
echo "═══════════════════════════════════════════════════════════"
echo " TIER 1: Domain Controllers (Full Stealth)"
echo "═══════════════════════════════════════════════════════════"

echo "[*] Generating dc-primary deployment..."
pwsh src/ADS-OneLiner.ps1 \
  -PayloadFile competition/payloads/dc-primary.ps1 \
  -Encrypt -Randomize -ZeroWidthStreams \
  -UseDeepPlacement -AttachToExisting \
  -CreateDecoys 3 -InstanceCount 3 \
  -OutputFile competition/deployments/dc-primary.txt \
  -ManifestDir competition/deployments/manifests

echo "[*] Generating dc-secondary deployment..."
pwsh src/ADS-OneLiner.ps1 \
  -PayloadFile competition/payloads/dc-secondary.ps1 \
  -Encrypt -Randomize -ZeroWidthStreams \
  -UseDeepPlacement -AttachToExisting \
  -CreateDecoys 3 -InstanceCount 3 \
  -OutputFile competition/deployments/dc-secondary.txt \
  -ManifestDir competition/deployments/manifests

echo ""

# ============================================================
# TIER 2: Windows Servers (Medium Stealth)
# ============================================================
echo "═══════════════════════════════════════════════════════════"
echo " TIER 2: Windows Servers (Medium Stealth)"
echo "═══════════════════════════════════════════════════════════"

echo "[*] Generating server-primary deployment..."
pwsh src/ADS-OneLiner.ps1 \
  -PayloadFile competition/payloads/server-primary.ps1 \
  -Encrypt -Randomize -InstanceCount 2 \
  -OutputFile competition/deployments/server-primary.txt \
  -ManifestDir competition/deployments/manifests

echo "[*] Generating server-secondary deployment..."
pwsh src/ADS-OneLiner.ps1 \
  -PayloadFile competition/payloads/server-secondary.ps1 \
  -Encrypt -Randomize -InstanceCount 2 \
  -OutputFile competition/deployments/server-secondary.txt \
  -ManifestDir competition/deployments/manifests

echo ""

# ============================================================
# TIER 3: Workstations (Rapid)
# ============================================================
echo "═══════════════════════════════════════════════════════════"
echo " TIER 3: Workstations (Rapid)"
echo "═══════════════════════════════════════════════════════════"

echo "[*] Generating workstation-primary deployment..."
pwsh src/ADS-OneLiner.ps1 \
  -PayloadFile competition/payloads/workstation-primary.ps1 \
  -Encrypt -Randomize \
  -OutputFile competition/deployments/workstation-primary.txt \
  -ManifestDir competition/deployments/manifests

echo "[*] Generating workstation-secondary deployment..."
pwsh src/ADS-OneLiner.ps1 \
  -PayloadFile competition/payloads/workstation-secondary.ps1 \
  -Encrypt -Randomize \
  -OutputFile competition/deployments/workstation-secondary.txt \
  -ManifestDir competition/deployments/manifests

echo ""

# ============================================================
# TIER 4: Fallback (Maximum Speed - Emergency Only)
# ============================================================
echo "═══════════════════════════════════════════════════════════"
echo " TIER 4: Fallback (Emergency - No Encryption)"
echo "═══════════════════════════════════════════════════════════"

echo "[*] Generating fallback deployment..."
pwsh src/ADS-OneLiner.ps1 \
  -PayloadFile competition/payloads/workstation-primary.ps1 \
  -OutputFile competition/deployments/fallback.txt \
  -ManifestDir competition/deployments/manifests

echo ""

# ============================================================
# SUMMARY
# ============================================================
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║ GENERATION COMPLETE                                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "✓ 6 primary deployment packages generated"
echo "✓ 1 fallback package generated"
echo "✓ Manifests saved to: competition/deployments/manifests/"
echo ""
echo "DEPLOYMENT FILES:"
echo "  - competition/deployments/dc-primary.txt"
echo "  - competition/deployments/dc-secondary.txt"
echo "  - competition/deployments/server-primary.txt"
echo "  - competition/deployments/server-secondary.txt"
echo "  - competition/deployments/workstation-primary.txt"
echo "  - competition/deployments/workstation-secondary.txt"
echo "  - competition/deployments/fallback.txt"
echo ""
echo "NEXT STEPS:"
echo "  1. Review deployment files in competition/deployments/"
echo "  2. Start HTTP server: python3 -m http.server 8080"
echo "  3. Copy base64 one-liners from .txt files"
echo "  4. Paste into PowerShell on Windows targets"
echo ""
echo "READY FOR CCDC 2026!"
echo ""
