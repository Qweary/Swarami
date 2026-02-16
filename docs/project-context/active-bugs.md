# Active Bugs & Issues

Last Updated: 2026-02-15

## Fixed in v2.3 (This Session)

### ~~BUG-001: Version Number Inconsistency~~ FIXED
All versions aligned to v2.3 across Dropper, OneLiner, CLAUDE.md.

### ~~BUG-002: Stale Help Text in Dropper~~ FIXED
Show-Help rewritten. All .EXAMPLE/.PARAMETER/.DESCRIPTION blocks updated. Removed volroot/reg/array references.

### ~~BUG-003: Trigger Type Mismatch~~ FIXED
Both scripts now use `-Trigger` parameter with default `@('AtLogOn','AtStartup')`.

### ~~BUG-004: Registry Persistence Implementation Split~~ FIXED
Full `Create-RegistryPersistence` function in Dropper. OneLiner generates matching code via `Build-TriggerBlock` + registry companion task.

### ~~BUG-006: CLAUDE.md Payload Count Outdated~~ FIXED
Updated from 62 to 69.

### ~~BUG-010: Jitter (RandomDelay) Fails on AtLogOn/AtStartup/OnUnlock Triggers~~ FIXED
**Root Cause:** Task Scheduler CIM classes use different property names per trigger type:
- `MSFT_TaskLogonTrigger` / `MSFT_TaskBootTrigger` use `Delay` (not `RandomDelay`)
- `MSFT_TaskTimeTrigger` (Once/periodic) uses `RandomDelay`
- `MSFT_TaskSessionStateChangeTrigger` uses `Delay` (set during CIM creation)
- `MSFT_TaskIdleTrigger` has NO delay property
Additionally, all delay properties require **ISO 8601 duration strings** (`PT1M`), not `TimeSpan` objects (`00:01:00`). TimeSpan serializes to `HH:MM:SS` which the Task Scheduler XML parser rejects.
**Fix:** Use `Delay` with ISO 8601 strings for event triggers, `RandomDelay` with ISO 8601 for periodic. Fixed in both `ADS-Dropper.ps1` and `ADS-OneLiner.ps1` `Build-TriggerBlock`.

### ~~BUG-005: WMI Persistence~~ REMOVED
Removed `wmi` from `-Persist` ValidateSet in both scripts. WMI event subscriptions have worse detection surface than existing methods (dedicated Sysmon EID 19/20/21, trivial enumeration, autoruns.exe WMI tab). No operational advantage for CCDC — task + registry already provide superior stealth, speed, and survivability.

## Fixed in v2.4 (Session 4 — Unified -Obfuscate)

### ~~BUG-007: _Companion Suffix is Huntable Pattern~~ FIXED
Companion task suffix now randomized from word list (`-Monitor`, `-Handler`, `-Worker`, `-Sync`, `-Cache`, `-Service`, `-Helper`, `-Manager`). Controlled by `-Obfuscate` tier — Advanced+ uses random selection. None tier preserves `_Companion` for backward compat.

### ~~BUG-008: Registry Command Line Contains Signature-Grade Artifacts~~ FIXED
`GHK` and `Dec` function names replaced with tier-appropriate names. None=legacy (`GHK`/`Dec`), Basic=static (`Get-HostKey`/`Unprotect-Data`), Advanced+=randomized Verb-Noun pairs from word list. Applied across JScript wrappers, registry commands, and helper functions in both scripts.

## Open Bugs

### BUG-009: Multi-Instance Cleanup Only Covers First Instance
**Severity:** Medium (cleanup gap)
**File:** src/ADS-OneLiner.ps1
**Description:** When `-InstanceCount > 1` with `-Persist registry`, the cleanup section only references `$($config.TaskName)` from the first instance. Additional instances orphan registry keys + companion tasks. Partially improved (companion suffix now uses config.TaskSuffix) but multi-instance loop still not addressed. Identified by opsec-specialist pre-commit review.
