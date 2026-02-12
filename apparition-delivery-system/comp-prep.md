---
description: Generate a full competition deployment package with payloads for each target tier, manifests, and quick-reference guide
---

Generate a competition deployment package for CCDC. Use the `red-team-ops` agent for tactical decisions and the `payload-engineer` agent for payload selection.

Ask Queue for:
- Number and types of expected targets (DCs, servers, workstations)
- C2 callback address (IP:port)
- Any known constraints (specific Windows versions, defensive tools observed)

Then generate:
1. Tier 1 deployment commands (full stealth: encryption, zero-width, decoys, deep placement, multi-instance)
2. Tier 2 deployment commands (medium stealth: encryption, randomization)
3. Tier 3 deployment commands (rapid: minimal features)
4. A fallback deployment command (maximum speed, no stealth features)
5. A quick-reference card with copy-paste commands organized by target tier
6. Recommended payload combinations from ccdc-library.ps1 for each scenario

Save the package to `competition/` directory with the competition date in the filename.
