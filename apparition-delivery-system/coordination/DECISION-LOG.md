# Decision Log — Apparition Delivery System

Purpose: Permanent record of architectural decisions, technique choices, and things we tried that didn't work.
Append-only. Never delete entries. Invaluable for the swarm to avoid re-litigating settled questions.

---

## [2026-02-17] Compression Strategy — GZip Chosen, Detection Risk Identified

**Decision:** Implement GZip compression in ADS-OneLiner.ps1 before base64 encoding
**Outcome:** 50%+ payload size reduction achieved (16,800 → ~8,800 chars in testing)
**Problem discovered:** GZip+IEX decompression stub triggers `PShellCobStager.A`
**Current status:** Compression implemented but decompression stub needs evasion redesign before production use
**Do not:** Re-implement vanilla GZipStream → IEX pattern — it will be detected

---

## [2026-02-17] Switch Parameters → Bool Parameters

**Decision:** Changed `[switch]` to `[bool]` for UseDeepPlacement, AttachToExisting, Randomize
**Reason:** PowerShell switch parameter binding fails when called from bash with `-Param:$false` syntax
**Outcome:** Resolved. Bool parameters accept `$false`, `$true`, `0`, `1` from any shell
**Affected files:** ADS-Dropper.ps1, ADS-OneLiner.ps1

---

## [2026-02-17] Test 2 Root Cause — Hardcoded Snapshot Path

**Decision:** Fixed all test files to use `$PSScriptRoot\..\src\ADS-Dropper.ps1`
**Root cause:** Tests had hardcoded path to Snapshot1 development environment
**Lesson:** Test files must never contain absolute paths — always relative via `$PSScriptRoot`

---

## [2026-02-11] JScript Wrapper — Why Not PowerShell Directly

**Decision:** Use `wscript.exe //B //E:JScript` wrapper instead of calling powershell.exe directly from task
**Reason:** `-WindowStyle Hidden` does NOT reliably hide windows when launched from Task Scheduler — scheduler creates new session with different window management
**Alternative rejected:** Direct powershell.exe task action (visible window, unreliable)
**Outcome:** JScript with `shell.Run(cmd, 0, false)` provides true zero-visibility execution

---

## [2026-02-11] RepetitionDuration Requirement

**Decision:** Always include `-RepetitionDuration (New-TimeSpan -Days 9999)` with `-RepetitionInterval`
**Reason:** On Windows Server 2019+ and Win10 20H2+, RepetitionInterval without RepetitionDuration causes task to repeat only once
**Discovery:** Found during testing when periodic trigger appeared to work but only fired one time
**Implementation:** Hard-coded into task creation logic, not optional

---

## [2026-02-11] Hardware-Derived Encryption Keys

**Decision:** AES key derived from COMPUTERNAME + WMI UUID + baseboard serial, SHA-256 hashed
**Reason:** Prevents offline analysis — payload can't be decrypted without matching hardware profile
**Tradeoff:** Key derivation fails if VM snapshot is restored to different state
**Status:** Implemented. Encryption feature currently needs AV evasion work before production use.

---

## [Template]

## [YYYY-MM-DD] <Decision Title>

**Decision:** <what was decided>
**Reason:** <why this approach over alternatives>
**Alternatives rejected:** <what else was considered and why it lost>
**Outcome:** <result>
**Do not:** <anti-pattern to avoid repeating>
