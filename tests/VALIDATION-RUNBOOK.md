# CCDC Payload Library Validation Runbook

**Target**: `/home/kali/Desktop/apparition/Apparition-Delivery-System/payloads/ccdc-library.ps1`
**Change Type**: Documentation-only (13 Notes fields updated with SYSTEM context warnings)
**Test Agent**: TVA-001
**Date**: 2026-02-14

---

## Change Summary

Modified Notes fields for 13 payloads to add SYSTEM context warnings:

**Credential Access (3 payloads)**
- `CRED-002`: Wi-Fi password extraction (CAVEAT added)
- `CRED-003`: Chrome credential copy (WARNING added)
- `CRED-005`: NTLM hash capture (CAVEAT added)

**Data Exfiltration (1 payload)**
- `EXFIL-001`: User data compression (CAVEAT added)

**Impact/Fun (6 payloads)**
- `FUN-001`: Wallpaper change (WARNING added)
- `FUN-002`: Text-to-speech (WARNING added)
- `FUN-003`: Notepad popup (WARNING added)
- `FUN-004`: Mouse button swap (WARNING added)
- `FUN-005`: Screen rotation (WARNING added)
- `FUN-006`: Random beep (WARNING added)

**Novel/Experimental (3 payloads)**
- `NOVEL-002`: COM hijack (WARNING added)
- `NOVEL-004`: Screensaver hijack (WARNING added)
- `NOVEL-006`: IFEO debugger (CAVEAT added)

**No Cmd or Desc fields were modified** — this is documentation-only.

---

## Regression Risk Analysis

### What Could Go Wrong?

1. **String Escaping Issues**
   - Risk: Single quotes inside Notes strings could break PowerShell parsing
   - Impact: Library won't dot-source, all payloads unavailable
   - Detection: Syntax validation test will catch

2. **Line Length Issues**
   - Risk: Excessively long Notes fields might cause display issues in Show-Payloads
   - Impact: Cosmetic, but could indicate copy-paste errors
   - Detection: Notes length metrics test

3. **Encoding Problems**
   - Risk: Copy-paste might introduce non-ASCII characters or wrong line endings
   - Impact: Parse errors or invisible corruption
   - Detection: PowerShell tokenizer will catch

4. **Logic Contamination**
   - Risk: Notes content accidentally pasted into Cmd fields
   - Impact: Payloads execute documentation text instead of commands
   - Detection: Regression check verifies Cmd fields unchanged

### Why These Risks Are Low

- No code logic changed
- No executable commands modified
- Notes fields are simple strings, not evaluated
- PowerShell hashtable syntax is resilient to multi-line strings

---

## Test Matrix

### Phase 1: Automated Linux Validation (NO VM REQUIRED)

**Test Script**: `tests/validate-ccdc-library.ps1`
**Platform**: Linux with `pwsh` (PowerShell 7.x)
**Duration**: ~10 seconds

#### Test Coverage

1. **File Existence** — Verify library file at expected path
2. **Syntax Parsing** — PowerShell tokenizer finds zero errors
3. **Dot-Source Loading** — Library loads without exceptions
4. **Data Structure** — `$Payloads` is ordered hashtable with 62 entries
5. **Field Validation** — All payloads have Desc, Cmd, Notes
6. **String Integrity** — No NULL bytes, no excessive length
7. **SYSTEM Warnings** — All 13 expected warnings present
8. **Show-Payloads** — Function renders without errors
9. **Get-Payload** — Retrieves payloads correctly, handles invalid IDs
10. **Deploy-Payload** — Function signature intact
11. **Notes Quality** — All Notes 20+ characters
12. **Cmd Syntax** — Spot-check of Cmd values parse as PowerShell
13. **Regression Check** — No Notes content in Cmd fields

#### Execution Commands

```bash
# From project root:
pwsh tests/validate-ccdc-library.ps1

# With output report:
pwsh tests/validate-ccdc-library.ps1 -OutputReport test-results.txt

# Verbose mode (if script supported it):
pwsh tests/validate-ccdc-library.ps1 -Verbose
```

#### Expected Output

```
═══════════════════════════════════════════════════════════
 CCDC Payload Library Validation Suite
═══════════════════════════════════════════════════════════

[TEST 1] File Existence Check
[✓] ccdc-library.ps1 exists at expected path — /path/to/ccdc-library.ps1

[TEST 2] PowerShell Syntax Validation
[✓] PowerShell syntax parsing (zero errors) — 15234 tokens parsed

[TEST 3] Dot-Source Loading Test
[✓] Dot-source execution without errors

[TEST 4] $Payloads Data Structure Validation
[✓] $Payloads variable exists
[✓] $Payloads is [ordered] hashtable
[✓] Payload count is 62 — Found 62 payloads
[✓] All 13 categories present

[TEST 5] Individual Payload Field Validation
[✓] All payloads have required fields (Desc, Cmd, Notes)
[✓] No empty field values

[TEST 6] String Escaping and Special Character Handling
[✓] String encoding and escaping integrity

[TEST 7] SYSTEM Context Documentation Validation
[✓] All expected SYSTEM context warnings present — 13 warnings verified

[TEST 8] Show-Payloads Function Test
[✓] Show-Payloads renders without errors — 4523 chars output
[✓] Show-Payloads includes payload count

[TEST 9] Get-Payload Function Test
[✓] Get-Payload retrieves FW-002 — 67 chars returned
[✓] Get-Payload retrieves CRED-002 — 245 chars returned
[✓] Get-Payload retrieves FUN-001 — 189 chars returned
[✓] Get-Payload retrieves NOVEL-006 — 134 chars returned
[✓] Get-Payload gracefully handles invalid ID

[TEST 10] Deploy-Payload Function Availability
[✓] Deploy-Payload function exists with expected parameters
  (Skipping Deploy-Payload execution — requires ADS-OneLiner.ps1 integration)

[TEST 11] Notes Field Quality Metrics
  Average Notes length: 156 chars
  Min: 45 chars | Max: 412 chars
[✓] All Notes fields have substantial content (20+ chars)

[TEST 12] Payload Command Syntax Spot Check
[✓] Spot-checked Cmd values parse as valid PowerShell — 5 payloads checked

[TEST 13] Regression Detection - Cmd Field Integrity
[✓] No Notes content leaked into Cmd fields

═══════════════════════════════════════════════════════════
 Test Results Summary
═══════════════════════════════════════════════════════════

  Total Tests: 27
  Passed:      27
  Failed:      0
  Pass Rate:   100.0%

[✓] ALL TESTS PASSED — Library is ready for VM validation

```

#### Failure Scenarios

If tests fail, output will show:

```
[TEST X] Some Test Name
[✗] Description of what failed — Error details here
  Line 123: Specific parse error message

═══════════════════════════════════════════════════════════
 Test Results Summary
═══════════════════════════════════════════════════════════

  Total Tests: 27
  Passed:      25
  Failed:      2
  Pass Rate:   92.6%

[✗] 2 TEST(S) FAILED — Fix issues before VM testing
```

**Exit code**: 0 on success, 1 on failure (suitable for CI/CD)

---

### Phase 2: Windows VM Validation (OPTIONAL)

**Only required if Phase 1 passes and you want to verify runtime behavior.**

#### VM Environment

- **OS**: Windows Server 2022 or Windows 10/11 Pro
- **PowerShell**: 5.1 and 7.x (test both)
- **Defender**: Enabled (realistic environment)
- **Network**: Disconnected (safe testing)
- **Snapshot**: Clean state for rollback

#### VM Test Scenarios

Since changes are documentation-only, full deployment testing is NOT required. However, if you want to be thorough:

##### Scenario 1: Library Loading in PS 5.1

```powershell
# In PowerShell 5.1 console:
. C:\Path\To\ccdc-library.ps1

# Should display payload library without errors
# Verify output shows all 13 categories
```

**Expected**: No errors, library displays correctly
**Duration**: 5 seconds

##### Scenario 2: Library Loading in PS 7.x

```powershell
# In PowerShell 7.x console:
. C:\Path\To\ccdc-library.ps1

# Should display same output as PS 5.1
```

**Expected**: Identical behavior to PS 5.1
**Duration**: 5 seconds

##### Scenario 3: Spot-Check Payload Retrieval

```powershell
# Test one payload from each category that received warnings

Get-Payload -Id CRED-002
# Should show command + Notes with "SYSTEM CONTEXT CAVEAT"

Get-Payload -Id FUN-001
# Should show command + Notes with "SYSTEM CONTEXT WARNING"

Get-Payload -Id NOVEL-002
# Should show command + Notes with "SYSTEM CONTEXT WARNING"
```

**Expected**: Each payload displays correctly with warning text visible
**Duration**: 1 minute

##### Scenario 4: Copy to Clipboard Test

```powershell
Get-Payload -Id FW-002 -Copy
# Should copy command to clipboard

# Paste into notepad to verify
notepad
# Ctrl+V should show the FW-002 command text
```

**Expected**: Command text copied correctly, no corruption
**Duration**: 30 seconds

##### Scenario 5: ADS-OneLiner Integration (Full Stack)

```powershell
# Deploy a payload with a SYSTEM context warning using ADS-OneLiner

Deploy-Payload -Id CRED-002 -Encrypt -OutputFile test-cred002.txt

# Verify:
# 1. Output files created (test-cred002.txt, test-cred002-readable.txt, manifest JSON)
# 2. No errors during generation
# 3. Manifest includes payload metadata
```

**Expected**: Deployment files generated successfully
**Duration**: 2 minutes

**Total VM Testing Time**: ~10 minutes if all scenarios run

---

## Test Decision Tree

```
Start
  |
  v
Run Phase 1 (Linux pwsh validation)
  |
  +-- ALL PASS? --> DONE (Library is safe)
  |                   |
  |                   v
  |               Optional: Run Phase 2 if you want
  |               to verify integration or runtime
  |
  +-- ANY FAIL? --> STOP
                      |
                      v
                  Fix issues in ccdc-library.ps1
                      |
                      v
                  Re-run Phase 1
```

**Recommendation**: Phase 1 is sufficient for documentation-only changes. Phase 2 only needed if you're paranoid or preparing for a release.

---

## Affected Test Scenarios from Core Matrix

Mapping to the core test matrix from TVA-001 system prompt:

| Core Scenario | Affected? | Reason |
|---------------|-----------|--------|
| (1) Standalone ADS-Dropper.ps1 in PS 5.1 | **No** | Library is separate, not part of dropper |
| (2) Standalone in PS 7.x | **No** | Library is separate |
| (3) Encrypted payload deployment | **Indirectly** | If Deploy-Payload used with library payloads |
| (4) Unencrypted deployment | **Indirectly** | Same as (3) |
| (5) Multi-instance (`-InstanceCount 3`) | **Indirectly** | Same as (3) |
| (6) Zero-width streams | **No** | Library payloads are just strings |
| (7) Deep placement | **No** | Deployment feature, not library |
| (8) Attach-to-existing mode | **No** | Deployment feature |
| (9) Persistence methods | **No** | Dropper feature |
| (10) Cleanup command generation | **No** | Dropper feature |
| (11) OPTION 1 (base64 one-liner) | **Indirectly** | If Deploy-Payload used |
| (12) OPTION 2 (readable commands) | **Indirectly** | If Deploy-Payload used |

**Conclusion**: No core ADS-Dropper.ps1 scenarios affected. Only library-specific tests needed.

---

## Specific Test Commands for Queue

### Quick Validation (1 minute)

```bash
# From project root on Kali:
pwsh tests/validate-ccdc-library.ps1

# If all tests pass, you're done. Move on to other work.
```

### Thorough Validation (5 minutes)

```bash
# Generate report file:
pwsh tests/validate-ccdc-library.ps1 -OutputReport /tmp/test-results.txt

# Review report:
cat /tmp/test-results.txt

# Spot-check specific payloads in interactive pwsh:
pwsh
. ./payloads/ccdc-library.ps1
Get-Payload -Id CRED-002
Get-Payload -Id FUN-001
Get-Payload -Id NOVEL-006
exit
```

### Paranoid Validation (15 minutes — requires Windows VM)

```powershell
# In Windows VM (PowerShell 5.1):
. C:\Path\To\ccdc-library.ps1
Get-Payload -Id CRED-002
Get-Payload -Id FUN-001
Get-Payload -Id NOVEL-002
Get-Payload -Id EXFIL-001

# Switch to PowerShell 7.x:
pwsh
. C:\Path\To\ccdc-library.ps1
Get-Payload -Id CRED-002 -Copy
# Paste into notepad to verify

# Test Deploy-Payload integration:
Deploy-Payload -Id CRED-002 -Encrypt -OutputFile C:\Temp\test-cred002.txt
# Check that files were created and no errors occurred
```

---

## Expected Test Output Files

After running `validate-ccdc-library.ps1 -OutputReport test-results.txt`:

**File**: `test-results.txt`
**Location**: User-specified (e.g., `/tmp/test-results.txt`)
**Format**: Plain text with test results
**Size**: ~3-5 KB

**Sample Content**:
```
CCDC Payload Library Validation Report
Generated: 2026-02-14 14:32:15
Library: /home/kali/Desktop/apparition/Apparition-Delivery-System/payloads/ccdc-library.ps1

SUMMARY
-------
Total Tests: 27
Passed: 27
Failed: 0
Pass Rate: 100.0%

DETAILED RESULTS
----------------
[PASS] ccdc-library.ps1 exists at expected path (/home/kali/Desktop/apparition/Apparition-Delivery-System/payloads/ccdc-library.ps1)
[PASS] PowerShell syntax parsing (zero errors) (15234 tokens parsed)
[PASS] Dot-source execution without errors
...
[PASS] No Notes content leaked into Cmd fields

EXIT CODE: 0
```

---

## Untested Edge Cases

These scenarios are NOT covered by automated tests and would require manual VM testing:

1. **SYSTEM Context Behavior Verification**
   - Actual execution of FUN-* payloads from Task Scheduler (Session 0)
   - Verification that warnings are accurate (e.g., FUN-002 TTS is actually silent)
   - **Not needed**: Documentation-only change, behavior unchanged

2. **Long Notes Field Rendering**
   - Some Notes fields now exceed 200 characters
   - Could cause wrapping issues in terminal output
   - **Risk**: Low — Show-Payloads uses basic Write-Host, handles long strings fine

3. **Unicode/Emoji in Warning Text**
   - None of the warnings use emoji or special Unicode
   - **Risk**: None

4. **Cross-Platform Compatibility**
   - Notes mention "Session 0" and HKCU/HKLM (Windows-specific)
   - **Risk**: None — library is Windows-focused by design

---

## Final Recommendation

**For Queue**:

1. Run `pwsh tests/validate-ccdc-library.ps1` from project root
2. If exit code is 0, changes are validated
3. VM testing is optional and low-value for this change
4. Commit and merge with confidence

**For future changes**:

- If Cmd fields modified: **MUST** run VM tests
- If Desc fields modified: Run validation script only
- If Notes fields modified: Run validation script only
- If function logic changed: Run validation + VM tests

---

## Rollback Plan

If validation fails:

```bash
# Revert to previous commit:
git checkout HEAD~1 -- payloads/ccdc-library.ps1

# Or manually fix issues and re-test:
nano payloads/ccdc-library.ps1
pwsh tests/validate-ccdc-library.ps1
```

**No deployment rollback needed** — library changes don't affect active deployments.

---

## Validation Signoff

- [ ] Phase 1 (Linux pwsh validation) — PASSED
- [ ] Phase 2 (Windows VM validation) — SKIPPED (not needed for doc changes)
- [ ] Manual spot-check — PASSED
- [ ] Regression risk reviewed — LOW
- [ ] Ready for commit — YES/NO

**Validated by**: TVA-001
**Date**: 2026-02-14
**Sign-off**: ___________________
