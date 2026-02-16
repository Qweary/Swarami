# Current State

**Last Updated:** 2026-02-15 (Session 4)
**Version:** v2.3 + unified `-Obfuscate` parameter (uncommitted, pending VM validation)
**Branch:** test (1 commit ahead of origin/test, plus uncommitted `-Obfuscate` implementation)

## Core Scripts

- `src/ADS-Dropper.ps1` — ~1220 lines. Core engine with new `-Obfuscate` parameter (None/Basic/Advanced/Paranoid), `Get-ObfuscatedName` function with word lists, timestamp anti-forensics in `Write-ADSPayload`. GenerateOnly mode returns expanded config with GHKFunctionName, DecFunctionName, TaskSuffix, ObfuscationLevel fields.
- `src/ADS-OneLiner.ps1` — ~1100 lines. Command generator with `-Obfuscate` parameter, tier-implied defaults, config-driven function names in all code generation paths (helper functions, JScript wrappers, registry commands, cleanup section).
- `payloads/ccdc-library.ps1` — 656 lines, 13 categories, 69 payloads. 13 payloads have SYSTEM context warnings.

## What Works (VM-Validated in v2.3)

- Full deployment pipeline: OneLiner generates one-liners that deploy ADS + JScript wrapper + scheduled task
- AES-256 encryption with hardware-derived keys
- Zero-width Unicode stream names (U+200B, U+200C, U+FEFF)
- JScript wrapper for true hidden execution from Task Scheduler
- Dual-layer AMSI bypass (XOR fragment splitting)
- Deep placement in WER/Cache directories
- Attach-to-existing-file mode
- Decoy stream creation
- Multi-instance deployment (up to 20)
- Manifest generation for cleanup
- Registry persistence with companion task
- Configurable triggers (AtLogOn, AtStartup, OnIdle, OnUnlock)
- Jitter with correct ISO 8601 format

## What's New (Implemented, NOT yet VM-validated)

- **Unified `-Obfuscate` parameter** with 4 tiers (None/Basic/Advanced/Paranoid)
- **Default tier: Advanced** — auto-enables DeepPlacement, AttachToExisting, Randomize
- **Paranoid tier** — adds ZeroWidthStreams (ZW chars in task/stream/registry names, NOT function names)
- **Word-list randomization** — task names from real Windows service names, function names as Verb-Noun pairs, companion suffixes randomized
- **Tier overrides** — individual switches like `-UseDeepPlacement:$false` override tier defaults via `$PSBoundParameters.ContainsKey()`
- **Backward compat** — `-ZeroWidthStreams` without `-Obfuscate` auto-upgrades to Paranoid; `-Obfuscate None` produces identical output to pre-change behavior
- **Timestamp anti-forensics** — `Write-ADSPayload` saves/restores CreationTime, LastWriteTime, LastAccessTime after ADS creation
- **BUG-007 RESOLVED** — `_Companion` suffix replaced with randomized suffixes from word list
- **BUG-008 RESOLVED** — `GHK`/`Dec` function names replaced with tier-appropriate names

## Known Issues

See `docs/project-context/active-bugs.md` for full list. Key items:
- BUG-009: Multi-instance cleanup only covers first instance (partially improved)
- OneLiner-generated code not yet tested end-to-end on Windows with `-Obfuscate`
- Pre-existing PS 5.1 parser warning at line ~153 in OneLiner (cosmetic, not runtime)

## Test Status

- **Pre-commit review: APPROVED** (code-architect, 0 critical issues)
- **Pre-flight test suite generated** — 5 bash scripts for Linux validation
- **Comprehensive test suite created** — `tests/COMPREHENSIVE-TEST-SUITE.md` with 10 Linux pre-flight tests + 9 VM scenarios
- **VM Quick Reference** — `tests/VM-TEST-OBFUSCATE-QUICKREF.md` for rapid VM validation
- **NOT YET RUN:** Pre-flight scripts and VM tests pending Queue execution
- **Windows VM tests (v2.3 baseline): 7/7 PASS** (before `-Obfuscate` changes)

## Competition Readiness

Full CCDC 2026 competition package in `competition/` directory. Note: competition package was generated before `-Obfuscate` parameter — may need regeneration with new defaults.
