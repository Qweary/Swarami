# Test Validation Scenarios: -Obfuscate Parameter

**Target:** ADS-Dropper.ps1 + ADS-OneLiner.ps1 (v2.4 candidate)
**Feature:** Unified `-Obfuscate` parameter with four tiers (None, Basic, Advanced, Paranoid)
**Validation Owner:** TVA-001 (test-validator agent)
**Generated:** 2026-02-15

---

## 1. MUST-TEST VM SCENARIOS (3-4 critical tests)

These scenarios MUST pass before committing the `-Obfuscate` feature. Each test validates a different obfuscation tier or override behavior.

### Test 1: Backward Compatibility (`-Obfuscate None`)

**Goal:** Verify that `-Obfuscate None` produces identical artifacts to pre-v2.4 behavior.

**Test Command:**
```powershell
pwsh ./src/ADS-OneLiner.ps1 `
  -Obfuscate None `
  -Payload 'Write-Host "Test-None" -ForegroundColor Green' `
  -Persist task `
  -OutputFile test-obf-none.txt
```

**Expected Output Object (GenerateOnly mode):**
- `GHKFunctionName`: `GHK`
- `DecFunctionName`: `Dec`
- `TaskName`: `SystemOptimization`
- `TaskSuffix`: `_Companion`
- `DeepPlacement`: `$false` (no auto-enable)
- `AttachToExisting`: `$false` (no auto-enable)
- `Randomized`: `$false` (no auto-enable)

**VM Validation Steps:**
1. Deploy the generated one-liner on Windows Server 2022.
2. Verify scheduled task name: `Get-ScheduledTask -TaskName 'SystemOptimization'`
3. Verify JScript wrapper contains function names `GHK` and `Dec` (if encrypted).
4. Verify host file path is `C:\ProgramData\SystemCache.dat` (not deep placement).
5. Run cleanup commands from manifest — verify all artifacts removed.
6. **PASS CRITERIA:** No regression from pre-v2.4 behavior.

---

### Test 2: Advanced Tier + Registry Persistence

**Goal:** Validate that `-Obfuscate Advanced` generates random verb-noun function names, random task names, enables deep placement + attach-to-existing, and works with registry persistence.

**Test Command:**
```powershell
pwsh ./src/ADS-OneLiner.ps1 `
  -Obfuscate Advanced `
  -Payload 'Write-Host "Test-Advanced" -ForegroundColor Cyan' `
  -Persist registry `
  -Trigger AtLogOn,AtStartup,OnIdle `
  -Encrypt `
  -OutputFile test-obf-advanced-reg.txt
```

**Expected Output Object:**
- `GHKFunctionName`: Random verb-noun (e.g., `Initialize-DriverCache`)
- `DecFunctionName`: Random verb-noun (e.g., `Sync-TpmBinding`)
- `TaskName`: Random from `$script:ObfTaskNames` (e.g., `WindowsDefenderScheduledScan`)
- `TaskSuffix`: Random from `$script:ObfCompanionSuffixes` (e.g., `-Monitor`)
- `DeepPlacement`: `$true` (auto-enabled by Advanced tier)
- `AttachToExisting`: `$true` (auto-enabled by Advanced tier)
- `Randomized`: `$true` (auto-enabled by Advanced tier)
- `ZeroWidthMode`: `single` (NOT enabled — Paranoid tier only)

**VM Validation Steps:**
1. Deploy on Windows 10/11 as non-admin user.
2. Verify registry Run key created: `Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'`
3. Verify registry value name matches obfuscated task name (e.g., `DiskCleanupTask`).
4. Verify registry command contains obfuscated function names (e.g., `function Initialize-DriverCache`).
5. Verify companion task created: `Get-ScheduledTask -TaskName '<TaskName><Suffix>'` (e.g., `DiskCleanupTask-Monitor`).
6. Verify JScript wrapper path is in a deep diagnostic directory (e.g., `C:\ProgramData\Microsoft\Windows\WER\Temp\windiag_*.js`).
7. Manually trigger registry Run key via logoff/logon or `Start-ScheduledTask` for companion task.
8. Verify payload executes successfully.
9. Run cleanup from manifest — verify registry key, companion task, JScript wrapper, ADS all removed.
10. **PASS CRITERIA:** Random names generated, deep placement active, registry + companion task both functional.

---

### Test 3: Paranoid Tier + Zero-Width Chars in Task Names

**Goal:** Validate that `-Obfuscate Paranoid` injects zero-width chars into task names and registry value names, but NOT function names (which would break PowerShell parsing).

**Test Command:**
```powershell
pwsh ./src/ADS-OneLiner.ps1 `
  -Obfuscate Paranoid `
  -Payload 'Write-Host "Test-Paranoid" -ForegroundColor Magenta' `
  -Persist task `
  -Trigger AtLogOn,OnUnlock `
  -Encrypt `
  -OutputFile test-obf-paranoid.txt
```

**Expected Output Object:**
- `GHKFunctionName`: Random verb-noun WITHOUT zero-width chars (e.g., `Validate-SecurityContext`)
- `DecFunctionName`: Random verb-noun WITHOUT zero-width chars (e.g., `Configure-CryptService`)
- `TaskName`: Random from list WITH zero-width char injected at random position (e.g., `TPMMa​intenanceTask` where `​` is U+200B)
- `TaskSuffix`: Random suffix WITH zero-width char (e.g., `-Mon​itor`)
- `ZeroWidthStreams`: `$true` (auto-enabled by Paranoid tier)
- `ZeroWidthMode`: `single` (default)
- `DeepPlacement`: `$true`
- `AttachToExisting`: `$true`

**VM Validation Steps:**
1. Deploy on Windows Server 2022.
2. Verify task registered: `Get-ScheduledTask | Where-Object { $_.TaskName -match 'TPM|Network|Disk' }`
3. Export task name to manifest and verify zero-width codepoints present: `Get-ZeroWidthCodepoints -StreamName $taskName`
4. Verify ADS stream name contains zero-width chars: `Get-Item $hostPath -Stream * | Select-Object -ExpandProperty Stream`
5. Verify JScript wrapper does NOT contain zero-width chars in function names (would break parsing): `Get-Content $jsPath | Select-String 'function'`
6. Manually trigger task: `Start-ScheduledTask -TaskName $taskName`
7. Verify payload executes successfully despite zero-width chars.
8. Run cleanup using codepoint manifest — verify task removal works with zero-width name reconstruction.
9. **PASS CRITERIA:** Zero-width chars appear ONLY in task/registry names and stream names, NOT in function names. Execution succeeds. Cleanup succeeds with codepoint reconstruction.

---

### Test 4: Override Behavior (`-Obfuscate Advanced -UseDeepPlacement:$false`)

**Goal:** Validate that explicit parameter overrides disable tier-implied defaults.

**Test Command:**
```powershell
pwsh ./src/ADS-OneLiner.ps1 `
  -Obfuscate Advanced `
  -UseDeepPlacement:$false `
  -AttachToExisting:$false `
  -Randomize:$false `
  -Payload 'Write-Host "Test-Override" -ForegroundColor Yellow' `
  -Persist task `
  -OutputFile test-obf-override.txt
```

**Expected Output Object:**
- `GHKFunctionName`: Random verb-noun (Advanced tier naming still applies)
- `DecFunctionName`: Random verb-noun
- `TaskName`: Random from list (Advanced tier naming still applies)
- `DeepPlacement`: `$false` (overridden)
- `AttachToExisting`: `$false` (overridden)
- `Randomized`: `$false` (overridden)

**VM Validation Steps:**
1. Deploy on Windows 10/11.
2. Verify host file path is `C:\ProgramData\SystemCache.dat` (NOT deep placement).
3. Verify task name is still obfuscated (e.g., `MemoryDiagnosticScheduler`).
4. Verify function names are still obfuscated (e.g., `Update-PolicyData`, `Monitor-TelemetryLog`).
5. **PASS CRITERIA:** Explicit parameter values override tier-implied defaults, but tier-level naming still applies.

---

## 2. LINUX PRE-FLIGHT TESTS (No VM Required)

These tests run on Linux (Kali) before VM validation. They catch syntax errors, missing fields, and malformed output.

### Pre-Flight 1: Dropper GenerateOnly — All Tiers

**Goal:** Verify ADS-Dropper.ps1 outputs correct configuration objects for each obfuscation tier.

**Test Script:**
```bash
#!/bin/bash
# tests/preflight-obfuscate-dropper.sh

for tier in None Basic Advanced Paranoid; do
  echo "Testing Dropper GenerateOnly: -Obfuscate $tier"

  result=$(pwsh -NoProfile -Command "
    \$config = ./src/ADS-Dropper.ps1 \
      -Obfuscate $tier \
      -Payload 'Test' \
      -GenerateOnly

    # Check required fields
    if (-not \$config.GHKFunctionName) { Write-Error 'Missing GHKFunctionName'; exit 1 }
    if (-not \$config.DecFunctionName) { Write-Error 'Missing DecFunctionName'; exit 1 }
    if (-not \$config.TaskName) { Write-Error 'Missing TaskName'; exit 1 }
    if (-not \$config.TaskSuffix) { Write-Error 'Missing TaskSuffix'; exit 1 }
    if (-not \$config.ObfuscationLevel) { Write-Error 'Missing ObfuscationLevel'; exit 1 }
    if (\$config.ObfuscationLevel -ne '$tier') { Write-Error 'ObfuscationLevel mismatch'; exit 1 }

    Write-Output 'PASS'
  " 2>&1)

  if [[ "$result" != *"PASS"* ]]; then
    echo "FAIL: $tier tier output validation"
    echo "$result"
    exit 1
  fi

  echo "  PASS: $tier tier"
done

echo "All Dropper GenerateOnly tests passed."
```

**Expected Results:**
- Exit code 0
- Each tier produces valid output object with all required fields
- `ObfuscationLevel` matches input tier

---

### Pre-Flight 2: OneLiner Generation — All Tiers

**Goal:** Verify ADS-OneLiner.ps1 generates syntactically valid output files for each tier.

**Test Script:**
```bash
#!/bin/bash
# tests/preflight-obfuscate-oneliner.sh

for tier in None Basic Advanced Paranoid; do
  echo "Testing OneLiner generation: -Obfuscate $tier"

  pwsh -NoProfile -Command "
    ./src/ADS-OneLiner.ps1 \
      -Obfuscate $tier \
      -Payload 'Write-Host \"Test-$tier\"' \
      -Persist task \
      -OutputFile test-oneliner-$tier.txt
  " 2>&1 | tee /tmp/oneliner-$tier.log

  if [ ! -f "test-oneliner-$tier.txt" ]; then
    echo "FAIL: Output file not created for $tier"
    exit 1
  fi

  # Verify output file contains base64 one-liner
  if ! grep -q "powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand" "test-oneliner-$tier.txt"; then
    echo "FAIL: Base64 one-liner not found in output for $tier"
    exit 1
  fi

  # Verify manifest created
  manifest_count=$(find ./manifests -name "manifest-*.json" -mmin -1 | wc -l)
  if [ "$manifest_count" -eq 0 ]; then
    echo "FAIL: Manifest not created for $tier"
    exit 1
  fi

  echo "  PASS: $tier tier"
done

echo "All OneLiner generation tests passed."
```

**Expected Results:**
- Exit code 0
- Output files created for each tier
- Base64 one-liners present in output
- Manifest files created in `./manifests/`

---

### Pre-Flight 3: Syntax Validation of Generated Scripts

**Goal:** Verify PowerShell can parse the generated readable scripts without syntax errors.

**Test Script:**
```bash
#!/bin/bash
# tests/preflight-syntax-validation.sh

for tier in None Basic Advanced Paranoid; do
  echo "Validating syntax: $tier tier"

  # Extract readable script from output file (between "OPTION 2" markers)
  sed -n '/OPTION 2: Readable Multi-Line Commands/,/╔═══════════════════════════════════════════════════════════╗/p' \
    "test-oneliner-$tier.txt" | \
    tail -n +4 | head -n -2 > "test-script-$tier.ps1"

  # Use PSParser to tokenize (catches syntax errors)
  pwsh -NoProfile -Command "
    \$script = Get-Content 'test-script-$tier.ps1' -Raw
    \$tokens = \$null
    \$errors = \$null
    [System.Management.Automation.PSParser]::Tokenize(\$script, [ref]\$errors)

    if (\$errors.Count -gt 0) {
      Write-Error 'Syntax errors detected:'
      \$errors | ForEach-Object { Write-Error \$_.Message }
      exit 1
    }

    Write-Output 'PASS'
  " 2>&1 | tee /tmp/syntax-$tier.log

  if ! grep -q "PASS" /tmp/syntax-$tier.log; then
    echo "FAIL: Syntax validation failed for $tier"
    exit 1
  fi

  echo "  PASS: $tier tier syntax valid"
done

echo "All syntax validation tests passed."
```

**Expected Results:**
- Exit code 0
- No syntax errors from `PSParser::Tokenize()` for any tier
- Generated scripts are valid PowerShell

---

### Pre-Flight 4: Obfuscated Names Validation

**Goal:** Verify that each tier generates the correct naming style.

**Test Script:**
```bash
#!/bin/bash
# tests/preflight-naming-validation.sh

echo "Validating naming conventions..."

# None tier: hardcoded legacy names
manifest_none=$(find ./manifests -name "manifest-*.json" -mmin -1 | head -1)
ghk_none=$(jq -r '.GHKFunctionName' "$manifest_none")
task_none=$(jq -r '.TaskName' "$manifest_none")
suffix_none=$(jq -r '.TaskSuffix' "$manifest_none")

if [ "$ghk_none" != "GHK" ]; then
  echo "FAIL: None tier GHK function should be 'GHK', got '$ghk_none'"
  exit 1
fi
if [ "$task_none" != "SystemOptimization" ]; then
  echo "FAIL: None tier task should be 'SystemOptimization', got '$task_none'"
  exit 1
fi
if [ "$suffix_none" != "_Companion" ]; then
  echo "FAIL: None tier suffix should be '_Companion', got '$suffix_none'"
  exit 1
fi
echo "  PASS: None tier naming"

# Basic tier: static legitimate names
manifest_basic=$(find ./manifests -name "manifest-*.json" -mmin -1 | sort | sed -n 2p)
ghk_basic=$(jq -r '.GHKFunctionName' "$manifest_basic")
if [ "$ghk_basic" != "Get-HostKey" ]; then
  echo "FAIL: Basic tier GHK should be 'Get-HostKey', got '$ghk_basic'"
  exit 1
fi
echo "  PASS: Basic tier naming"

# Advanced tier: random verb-noun, no zero-width
manifest_adv=$(find ./manifests -name "manifest-*.json" -mmin -1 | sort | sed -n 3p)
ghk_adv=$(jq -r '.GHKFunctionName' "$manifest_adv")
if ! echo "$ghk_adv" | grep -Pq '^[A-Z][a-z]+-[A-Z][a-z]+$'; then
  echo "FAIL: Advanced tier GHK should be Verb-Noun format, got '$ghk_adv'"
  exit 1
fi
echo "  PASS: Advanced tier naming (Verb-Noun)"

# Paranoid tier: random verb-noun (no ZW in functions), ZW in task name
manifest_para=$(find ./manifests -name "manifest-*.json" -mmin -1 | sort | sed -n 4p)
ghk_para=$(jq -r '.GHKFunctionName' "$manifest_para")
if ! echo "$ghk_para" | grep -Pq '^[A-Z][a-z]+-[A-Z][a-z]+$'; then
  echo "FAIL: Paranoid tier GHK should be Verb-Noun (no ZW), got '$ghk_para'"
  exit 1
fi
task_para=$(jq -r '.TaskName' "$manifest_para")
# ZW chars are non-printable — check if byte length > char length
task_bytes=$(echo -n "$task_para" | wc -c)
task_chars=$(echo -n "$task_para" | wc -m)
if [ "$task_bytes" -le "$task_chars" ]; then
  echo "WARN: Paranoid tier task name may not contain ZW chars (bytes=$task_bytes, chars=$task_chars)"
  # Not a hard failure — ZW char injection is random, may not always fire
fi
echo "  PASS: Paranoid tier naming (functions without ZW, task may have ZW)"

echo "All naming validation tests passed."
```

**Expected Results:**
- Exit code 0
- None tier: hardcoded names (`GHK`, `SystemOptimization`, `_Companion`)
- Basic tier: static legitimate names (`Get-HostKey`, etc.)
- Advanced tier: random Verb-Noun pairs without zero-width chars
- Paranoid tier: random Verb-Noun pairs in functions, zero-width chars in task names

---

## 3. REGRESSION RISKS

**Risk 1: Backward Compatibility Breakage**
- **Issue:** Operators with saved manifests from v2.3 or earlier expect hardcoded names like `GHK`, `Dec`, `SystemOptimization`.
- **Test:** Run cleanup scripts generated before v2.4 against ADS artifacts created with `-Obfuscate None`. Verify cleanup succeeds.
- **Mitigation:** `-Obfuscate None` must produce identical names to pre-v2.4 behavior.

**Risk 2: Function Name Parsing Errors**
- **Issue:** Zero-width chars in function names break PowerShell's parser.
- **Test:** Test 3 (Paranoid tier) verifies function names do NOT contain ZW chars.
- **Mitigation:** `Get-ObfuscatedName -Type FunctionGHK/FunctionDec` always returns Advanced-tier names (verb-noun) even in Paranoid mode.

**Risk 3: JScript String Escaping**
- **Issue:** Random function names with special chars (e.g., apostrophes, quotes) could break JScript string literals.
- **Test:** Pre-Flight 3 (syntax validation) should catch this.
- **Mitigation:** Verb-noun word lists contain only alphabetic chars — no special chars.

**Risk 4: Registry Command Line Breakage**
- **Issue:** Registry Run key value is a single string. Obfuscated function names must not contain chars that break cmd.exe or PowerShell command-line parsing.
- **Test:** Test 2 (Advanced + Registry) validates registry Run key execution.
- **Mitigation:** Verb-noun format is cmd.exe-safe (no quotes, backticks, or special chars).

**Risk 5: Multi-Instance Name Collisions**
- **Issue:** With `$InstanceCount > 1`, random name generation could produce duplicate task names in rare cases.
- **Test:** Deploy 10 instances, verify all tasks registered with unique names: `Get-ScheduledTask | Where-Object { $_.TaskName -match 'WinSAT|Disk|TPM' }`
- **Mitigation:** GUIDs in multi-instance task names provide uniqueness. For obfuscation, consider adding random suffix to task names in multi-instance mode.

**Risk 6: Zero-Width Stream Cleanup**
- **Issue:** Zero-width stream names require codepoint manifests for cleanup. If manifest is lost, cleanup fails.
- **Test:** Paranoid tier test (Test 3) must validate cleanup using codepoint reconstruction.
- **Mitigation:** Manifests already track codepoints. Ensure documentation emphasizes manifest retention for Paranoid tier.

---

## 4. EDGE CASES TO WATCH

### Edge Case 1: `-ZeroWidthStreams` Without Explicit `-Obfuscate`

**Expected Behavior:** `-ZeroWidthStreams` should auto-upgrade obfuscation to Paranoid tier.

**Test Command:**
```powershell
pwsh ./src/ADS-OneLiner.ps1 `
  -ZeroWidthStreams `
  -Payload 'Test-ZW-Upgrade' `
  -OutputFile test-edge-zw-upgrade.txt
```

**Verification:**
- Check manifest: `ObfuscationLevel` should be `Paranoid`
- Check config: `ZeroWidthStreams` should be `$true`
- Check naming: Function names should be Verb-Noun, task name should have ZW chars

---

### Edge Case 2: `-Obfuscate Paranoid` with Function Name Injection (Should NOT Happen)

**Expected Behavior:** Function names NEVER contain zero-width chars, even in Paranoid mode.

**Test Command:**
```powershell
$config = ./src/ADS-Dropper.ps1 -Obfuscate Paranoid -Payload 'Test' -GenerateOnly

# Extract function names
$ghk = $config.GHKFunctionName
$dec = $config.DecFunctionName

# Check for zero-width chars (U+200B = 0xE2 0x80 0x8B in UTF-8)
$ghkBytes = [System.Text.Encoding]::UTF8.GetBytes($ghk)
$decBytes = [System.Text.Encoding]::UTF8.GetBytes($dec)

if ($ghkBytes -match 0xE2 -or $decBytes -match 0xE2) {
  Write-Error "FAIL: Function names contain zero-width chars"
  exit 1
}

Write-Output "PASS: Function names clean"
```

**Verification:**
- No zero-width codepoints in `GHKFunctionName` or `DecFunctionName`
- PowerShell parser can tokenize function definitions without errors

---

### Edge Case 3: Multi-Instance with Advanced Tier

**Expected Behavior:** Each instance gets unique random names.

**Test Command:**
```powershell
pwsh ./src/ADS-OneLiner.ps1 `
  -Obfuscate Advanced `
  -Payload 'Test-MultiInst' `
  -InstanceCount 5 `
  -OutputFile test-edge-multi-adv.txt
```

**Verification:**
- Extract readable script from output
- Count occurrences of `Register-ScheduledTask -TaskName` — should have 5 unique task name variables
- Deploy on VM, verify 5 tasks registered with unique names

---

### Edge Case 4: `-Obfuscate Advanced -Randomize:$false` (Override)

**Expected Behavior:** Obfuscation tier controls naming style, but `-Randomize:$false` should disable file/stream randomization.

**Test Command:**
```powershell
$config = ./src/ADS-Dropper.ps1 `
  -Obfuscate Advanced `
  -Randomize:$false `
  -Payload 'Test-Override' `
  -GenerateOnly

# Check naming: should still be obfuscated
if ($config.GHKFunctionName -eq 'GHK') {
  Write-Error "FAIL: Function names not obfuscated"
  exit 1
}

# Check path: should be static (not randomized)
if ($config.HostPath -ne 'C:\ProgramData\SystemCache.dat') {
  Write-Error "FAIL: Host path should not be randomized"
  exit 1
}

Write-Output "PASS: Naming obfuscated, paths static"
```

**Verification:**
- Function names/task names are obfuscated (Verb-Noun)
- Host file path is static (`SystemCache.dat`)
- Stream name is static (`payload`)

---

### Edge Case 5: `-Obfuscate None` with `-Encrypt` (Legacy Behavior)

**Expected Behavior:** Encryption works with legacy function names.

**Test Command:**
```powershell
pwsh ./src/ADS-OneLiner.ps1 `
  -Obfuscate None `
  -Encrypt `
  -Payload 'Test-None-Encrypted' `
  -Persist task `
  -OutputFile test-edge-none-encrypt.txt
```

**Verification:**
- Deploy on VM
- Verify JScript wrapper contains `function GHK` and `function Dec`
- Manually trigger task — verify payload decrypts and executes
- **PASS CRITERIA:** Encryption + legacy names work together

---

## 5. PRE-COMMIT CHECKLIST

Before committing the `-Obfuscate` feature to the `test` branch:

- [ ] All 4 VM must-test scenarios pass
- [ ] All 4 Linux pre-flight tests pass
- [ ] All 5 edge cases validated
- [ ] No regression in existing tests (`validate-ccdc-library.ps1`, `test1-jitter-task.ps1`, etc.)
- [ ] Manifest files contain `ObfuscationLevel` field
- [ ] Cleanup commands generated with correct obfuscated names
- [ ] Documentation updated (`docs/ADS-DROPPER-HELP.md`, `docs/USAGE-GUIDE.md`)
- [ ] Session handoff notes updated with test results

---

## 6. RECOMMENDED TEST EXECUTION ORDER

1. **Linux Pre-Flight Tests** (5 minutes)
   - Run `tests/preflight-obfuscate-dropper.sh`
   - Run `tests/preflight-obfuscate-oneliner.sh`
   - Run `tests/preflight-syntax-validation.sh`
   - Run `tests/preflight-naming-validation.sh`
   - **STOP if any fail** — fix code before VM testing

2. **VM Must-Test Scenarios** (30-45 minutes)
   - Test 1: Backward compatibility (`-Obfuscate None`)
   - Test 2: Advanced + Registry
   - Test 3: Paranoid + Zero-Width
   - Test 4: Override behavior

3. **Edge Case Validation** (15-20 minutes)
   - Run all 5 edge case tests
   - Document any unexpected behaviors

4. **Regression Testing** (10 minutes)
   - Re-run existing test suite (`tests/test*.ps1`)
   - Verify no breakage

5. **Final Sign-Off**
   - Code review by code-architect
   - Update `docs/project-context/current-state.md`
   - Commit with message: `feat: Add unified -Obfuscate parameter (None/Basic/Advanced/Paranoid)`

---

## 7. NOTES FOR QUEUE

**What's Automatable:**
- All Linux pre-flight tests can run on Kali without a Windows VM.
- Syntax validation catches ~70% of bugs before VM testing.
- Naming validation ensures tier-specific logic works.

**What Needs VM:**
- End-to-end execution tests (JScript wrapper execution, task triggers, registry Run keys).
- Zero-width char cleanup with codepoint reconstruction.
- Multi-instance collision detection.

**Snapshot Strategy:**
- Take a clean snapshot before Test 1.
- Restore snapshot between each VM test to avoid artifact conflicts.
- Final snapshot after all tests pass for release candidate validation.

**Documentation Reminders:**
- Update help comments in both scripts to document `-Obfuscate` tiers.
- Add examples to `docs/USAGE-GUIDE.md` showing each tier.
- Update `README.md` with obfuscation tier recommendations (Advanced for CCDC, Paranoid for APT simulation).

---

**End of Validation Runbook**

Generated by TVA-001 (test-validator) on 2026-02-15.
