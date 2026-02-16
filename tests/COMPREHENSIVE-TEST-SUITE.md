# COMPREHENSIVE TEST SUITE — Apparition Delivery System v2.3

**Complete validation matrix for `-Obfuscate` parameter + all existing features**

**Generated:** 2026-02-15
**Covers:** ADS-Dropper.ps1 + ADS-OneLiner.ps1 with obfuscation tiers (None/Basic/Advanced/Paranoid)

---

## Table of Contents

1. [Section 1: Linux Pre-Flight Tests (No VM Needed)](#section-1-linux-pre-flight-tests)
2. [Section 2: Windows VM Tests (Copy-Paste PowerShell)](#section-2-windows-vm-tests)
3. [Section 3: Common Verification Commands](#section-3-common-verification-commands)
4. [Section 4: Snapshot Workflow](#section-4-snapshot-workflow)

---

# Section 1: Linux Pre-Flight Tests

**Environment:** Linux/WSL with `pwsh` installed
**Working Directory:** Project root (`Apparition-Delivery-System-WithClaude-Snapshot1`)
**Goal:** Catch syntax errors, parameter validation bugs, and output format issues before VM testing

## 1.1 Dropper GenerateOnly — All Tiers

Test that ADS-Dropper.ps1 generates correct configuration objects for each obfuscation tier.

### Test 1.1.1: None Tier (Backward Compat)

```bash
pwsh ./src/ADS-Dropper.ps1 \
  -Payload 'Write-Host "Test-None" -ForegroundColor Green' \
  -Obfuscate None \
  -GenerateOnly
```

**Expected Output:**
- `HostPath`: `C:\ProgramData\SystemCache.dat`
- `StreamName`: `payload`
- `TaskName`: `SystemOptimization`
- `TaskSuffix`: `_Companion`
- `GHKFunctionName`: `GHK`
- `DecFunctionName`: `Dec`
- `ObfuscationLevel`: `None`
- `DeepPlacement`: `False`
- `AttachToExisting`: `False`
- `Randomized`: `False`

**PASS if:** All fields match expected values (legacy behavior).

---

### Test 1.1.2: Basic Tier

```bash
pwsh ./src/ADS-Dropper.ps1 \
  -Payload 'Write-Host "Test-Basic" -ForegroundColor Cyan' \
  -Obfuscate Basic \
  -GenerateOnly
```

**Expected Output:**
- `GHKFunctionName`: `Get-HostKey` (static, not random)
- `DecFunctionName`: `Unprotect-Data` (static)
- `TaskName`: One of the static names from word list (e.g., `DiskCleanupTask`)
- `TaskSuffix`: One of the static suffixes (e.g., `-Monitor`)
- `ObfuscationLevel`: `Basic`
- `DeepPlacement`: `False` (not implied by Basic)

**PASS if:** Function names are static legitimate-looking names, task name is from word list.

---

### Test 1.1.3: Advanced Tier

```bash
pwsh ./src/ADS-Dropper.ps1 \
  -Payload 'Write-Host "Test-Advanced" -ForegroundColor Yellow' \
  -Obfuscate Advanced \
  -GenerateOnly
```

**Expected Output:**
- `GHKFunctionName`: Verb-Noun format (e.g., `Initialize-DriverCache`)
- `DecFunctionName`: Verb-Noun format (e.g., `Sync-TelemetryLog`)
- `TaskName`: Random from word list (e.g., `TPMMaintenanceTask`)
- `TaskSuffix`: Random from suffix list (e.g., `-Worker`)
- `ObfuscationLevel`: `Advanced`
- `DeepPlacement`: `True` (tier-implied default)
- `AttachToExisting`: `True` (tier-implied default)
- `Randomized`: `True` (tier-implied default)

**PASS if:** Names are randomized, deep placement enabled, all tier defaults active.

---

### Test 1.1.4: Paranoid Tier

```bash
pwsh ./src/ADS-Dropper.ps1 \
  -Payload 'Write-Host "Test-Paranoid" -ForegroundColor Magenta' \
  -Obfuscate Paranoid \
  -GenerateOnly
```

**Expected Output:**
- `GHKFunctionName`: Verb-Noun (no ZW — would break PS parser)
- `DecFunctionName`: Verb-Noun (no ZW)
- `TaskName`: Word-list name WITH zero-width char injected (check codepoints)
- `TaskSuffix`: Suffix WITH zero-width char injected
- `StreamName`: Contains zero-width chars (check `Codepoints` field)
- `ZeroWidthMode`: `single` (default)
- `ObfuscationLevel`: `Paranoid`
- `DeepPlacement`: `True`
- `AttachToExisting`: `True`
- `Randomized`: `True`

**PASS if:** Task name/suffix codepoints contain U+200B or similar, function names clean.

---

## 1.2 Tier + Encrypt

Test that encryption flag works with each tier.

### Test 1.2.1: None + Encrypt

```bash
pwsh ./src/ADS-Dropper.ps1 \
  -Payload 'Write-Host "None-Encrypted"' \
  -Obfuscate None \
  -Encrypt \
  -GenerateOnly
```

**Expected:** `PayloadEncrypted`: `True`, `GHKFunctionName`: `GHK`, `DecFunctionName`: `Dec`

**PASS if:** Encryption enabled, legacy function names used.

---

### Test 1.2.2: Advanced + Encrypt

```bash
pwsh ./src/ADS-Dropper.ps1 \
  -Payload 'Write-Host "Advanced-Encrypted"' \
  -Obfuscate Advanced \
  -Encrypt \
  -GenerateOnly
```

**Expected:** `PayloadEncrypted`: `True`, obfuscated Verb-Noun function names.

---

### Test 1.2.3: Paranoid + Encrypt

```bash
pwsh ./src/ADS-Dropper.ps1 \
  -Payload 'Write-Host "Paranoid-Encrypted"' \
  -Obfuscate Paranoid \
  -Encrypt \
  -GenerateOnly
```

**Expected:** Encryption + zero-width stream + obfuscated functions.

---

## 1.3 Tier + Randomize Explicit

Test that explicit `-Randomize` doesn't break tier-implied defaults.

```bash
pwsh ./src/ADS-Dropper.ps1 \
  -Payload 'Write-Host "Randomize-Test"' \
  -Obfuscate Advanced \
  -Randomize \
  -GenerateOnly
```

**Expected:** Should succeed (Randomize is tier-implied but explicit is fine).

**PASS if:** No errors, output shows `Randomized: True`.

---

## 1.4 Tier + Override Switches

Test that explicit overrides disable tier-implied defaults.

```bash
pwsh ./src/ADS-Dropper.ps1 \
  -Payload 'Write-Host "Override-Test"' \
  -Obfuscate Advanced \
  -UseDeepPlacement:$false \
  -AttachToExisting:$false \
  -Randomize:$false \
  -GenerateOnly
```

**Expected:**
- `ObfuscationLevel`: `Advanced`
- `DeepPlacement`: `False` (overridden)
- `AttachToExisting`: `False` (overridden)
- `Randomized`: `False` (overridden)
- Function names still obfuscated (Verb-Noun)

**PASS if:** Overrides respected, obfuscation level still applied to function names.

---

## 1.5 Backward Compat: -ZeroWidthStreams Auto-Upgrade

Test that `-ZeroWidthStreams` without explicit `-Obfuscate` upgrades to Paranoid.

```bash
pwsh ./src/ADS-Dropper.ps1 \
  -Payload 'Write-Host "ZW-Compat"' \
  -ZeroWidthStreams \
  -GenerateOnly
```

**Expected:**
- `ObfuscationLevel`: `Paranoid` (auto-upgraded)
- `StreamName`: Contains zero-width chars
- Task name has ZW injection

**PASS if:** Tier upgraded to Paranoid, all Paranoid features active.

---

## 1.6 OneLiner Generation — All Tiers with All Persist Modes

Test that ADS-OneLiner.ps1 generates valid output files for each combination.

### Test 1.6.1: None + Task

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate None \
  -Payload 'Write-Host "OneLiner-None-Task" -ForegroundColor Green' \
  -Persist task \
  -OutputFile /tmp/test-none-task.txt
```

**Verify Output:**
```bash
grep -q 'SystemOptimization' /tmp/test-none-task.txt && echo "PASS: Task name found" || echo "FAIL"
grep -q 'function GHK' /tmp/test-none-task.txt && echo "PASS: Legacy function found" || echo "FAIL"
grep -q 'C:\\ProgramData\\SystemCache.dat' /tmp/test-none-task.txt && echo "PASS: Default path" || echo "FAIL"
```

**PASS if:** All three checks pass.

---

### Test 1.6.2: Advanced + Registry + Encrypt

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "OneLiner-Advanced-Registry" -ForegroundColor Cyan' \
  -Persist registry \
  -Encrypt \
  -OutputFile /tmp/test-adv-reg.txt
```

**Verify Output:**
```bash
grep -q 'HKCU.*Run' /tmp/test-adv-reg.txt && echo "PASS: Registry persistence" || echo "FAIL"
grep -qE 'function (Initialize|Sync|Update)-(DriverCache|NetworkProfile|PolicyData)' /tmp/test-adv-reg.txt && echo "PASS: Obfuscated functions" || echo "FAIL"
grep -q 'FromBase64String' /tmp/test-adv-reg.txt && echo "PASS: Encryption" || echo "FAIL"
```

**PASS if:** Registry keys, obfuscated names, encryption all present.

---

### Test 1.6.3: Paranoid + Task + Encrypt + Triggers

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Paranoid \
  -Payload 'Write-Host "OneLiner-Paranoid" -ForegroundColor Magenta' \
  -Persist task \
  -Encrypt \
  -Trigger AtLogOn,OnUnlock \
  -OutputFile /tmp/test-paranoid.txt
```

**Verify Output:**
```bash
grep -q 'StateChange.*8' /tmp/test-paranoid.txt && echo "PASS: OnUnlock trigger" || echo "FAIL"
grep -q 'AtLogOn' /tmp/test-paranoid.txt && echo "PASS: AtLogOn trigger" || echo "FAIL"
cat /tmp/test-paranoid.txt | grep -c 'OPTION 1' && echo "PASS: One-liner format"
```

**PASS if:** Triggers correct, both output formats present.

---

## 1.7 OneLiner + Jitter

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "Jitter-Test"' \
  -Persist task \
  -JitterPercent 25 \
  -PeriodicMinutes 10 \
  -OutputFile /tmp/test-jitter.txt
```

**Verify:**
```bash
grep -q 'PT.*M' /tmp/test-jitter.txt && echo "PASS: Jitter delay ISO 8601 format"
grep -q 'Jitter.*25' /tmp/test-jitter.txt && echo "PASS: Jitter percent in summary"
```

**PASS if:** ISO 8601 delay strings present, jitter mentioned in config summary.

---

## 1.8 OneLiner + Multi-Instance

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "Multi-Instance"' \
  -Persist task \
  -InstanceCount 3 \
  -OutputFile /tmp/test-multi.txt
```

**Verify:**
```bash
grep -c 'for.*_instanceCount' /tmp/test-multi.txt
grep -q 'Instances: 3' /tmp/test-multi.txt && echo "PASS: Instance count in summary"
```

**PASS if:** Loop construct present, instance count documented.

---

## 1.9 OneLiner + Decoys

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "Decoys"' \
  -Persist task \
  -Encrypt \
  -CreateDecoys 3 \
  -OutputFile /tmp/test-decoy.txt
```

**Verify:**
```bash
grep -c 'Zone.Identifier\|Summary\|Comments' /tmp/test-decoy.txt
grep -q 'Decoys: 3' /tmp/test-decoy.txt && echo "PASS: Decoy count"
```

**PASS if:** Decoy streams created, count documented.

---

## 1.10 OneLiner + All Triggers

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "All-Triggers"' \
  -Persist task \
  -Trigger AtLogOn,AtStartup,OnUnlock,OnIdle \
  -OutputFile /tmp/test-triggers.txt
```

**Verify:**
```bash
grep -q 'AtLogOn' /tmp/test-triggers.txt && echo "PASS: AtLogOn"
grep -q 'AtStartup' /tmp/test-triggers.txt && echo "PASS: AtStartup"
grep -q 'StateChange.*8' /tmp/test-triggers.txt && echo "PASS: OnUnlock"
grep -q 'MSFT_TaskIdleTrigger' /tmp/test-triggers.txt && echo "PASS: OnIdle"
```

**PASS if:** All four trigger types present in output.

---

# Section 2: Windows VM Tests

**Environment:** Windows Server 2022 or Windows 10/11 Pro
**Requirements:** PowerShell 5.1+, admin rights (for most tests), snapshot capability
**Workflow:** Restore clean snapshot between each test

---

## VM Test 1: Obfuscate None + Task Persist (Backward Compat Baseline)

**Goal:** Verify legacy behavior with `-Obfuscate None`.

### Generate (on Linux):

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate None \
  -Payload 'Write-Host "VM-Test-1-None-Task" -ForegroundColor Green; "Test1-Pass" | Out-File C:\test1-marker.txt -Force' \
  -Persist task \
  -OutputFile /tmp/vm-test1.txt
```

### Deploy (on Windows VM):

1. Open PowerShell as Administrator
2. Copy **OPTION 1** (base64 one-liner) from `/tmp/vm-test1.txt`
3. Paste into PowerShell and press Enter

### Verify (on Windows VM):

```powershell
# Check scheduled task
Get-ScheduledTask -TaskName 'SystemOptimization'

# Check ADS
Get-Item 'C:\ProgramData\SystemCache.dat' -Stream *

# Check JScript wrapper (if encrypted)
Get-ChildItem 'C:\ProgramData' -Filter '*.js'

# Check task triggers
$task = Get-ScheduledTask -TaskName 'SystemOptimization'
$task.Triggers | ForEach-Object { Write-Host "$($_.CimClass.CimClassName)" }

# Execute task manually
Start-ScheduledTask -TaskName 'SystemOptimization'
Start-Sleep -Seconds 3

# Check marker
Get-Content C:\test1-marker.txt
```

### PASS Criteria:

- Task name = `SystemOptimization`
- Host file = `C:\ProgramData\SystemCache.dat`
- Stream name = `payload`
- JScript wrapper contains `function GHK` and `function Dec` (if encrypted)
- Marker file contains `Test1-Pass`

### Cleanup:

```powershell
Unregister-ScheduledTask -TaskName 'SystemOptimization' -Confirm:$false
Remove-Item 'C:\ProgramData\SystemCache.dat' -Force
Remove-Item 'C:\test1-marker.txt' -Force
Get-ChildItem 'C:\ProgramData' -Filter '*.js' | Remove-Item -Force
```

---

## VM Test 2: Obfuscate Advanced + Task Persist + Encrypt (New Default)

**Goal:** Validate Advanced tier with encryption and deep placement.

### Generate (on Linux):

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "VM-Test-2-Advanced-Encrypted" -ForegroundColor Cyan; "Test2-Pass" | Out-File C:\test2-marker.txt -Force' \
  -Persist task \
  -Encrypt \
  -OutputFile /tmp/vm-test2.txt
```

### Deploy (on Windows VM):

Copy OPTION 1 from `/tmp/vm-test2.txt`, paste into PowerShell (admin).

### Verify (on Windows VM):

```powershell
# Find task (name is obfuscated)
Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM|Network|Memory|Defender' }

# Store task name
$tn = (Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM|Network' })[0].TaskName

# Check host file location (should be in deep directory)
Get-ChildItem 'C:\ProgramData\Microsoft\Windows\WER' -Recurse -Filter '*.dat' -EA 0
Get-ChildItem 'C:\ProgramData\Microsoft\Diagnosis' -Recurse -Filter '*.etl' -EA 0

# Check JScript wrapper contains obfuscated function names
$js = Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' | Select-Object -First 1
Get-Content $js.FullName -Raw | Select-String 'function (Initialize|Sync|Update|Monitor|Process)-(DriverCache|NetworkProfile|TelemetryLog|ComponentStatus)'

# Execute task
Start-ScheduledTask -TaskName $tn
Start-Sleep -Seconds 3

# Check marker
Get-Content C:\test2-marker.txt
```

### PASS Criteria:

- Task name is obfuscated (from word list)
- Function names are Verb-Noun format
- Host file is in deep diagnostic directory OR attached to existing file
- Encryption present (JScript has `FromBase64String`)
- Marker file created with correct content

### Cleanup:

```powershell
# Get task name from manifest or search
$tn = (Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM|Network' })[0].TaskName
Unregister-ScheduledTask -TaskName $tn -Confirm:$false

# Clean up ADS and JScript (paths from runtime)
# Host path will vary — check manifest or use pattern matching
Get-ChildItem 'C:\ProgramData\Microsoft\Windows\WER' -Recurse -Filter '*.dat' -EA 0 | Remove-Item -Force
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' -EA 0 | Remove-Item -Force
Remove-Item 'C:\test2-marker.txt' -Force
```

---

## VM Test 3: Obfuscate Advanced + Registry Persist + Encrypt + All Triggers

**Goal:** Test registry Run keys + companion task with all trigger types.

### Generate (on Linux):

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "VM-Test-3-Registry" -ForegroundColor Yellow; "Test3-Pass" | Out-File C:\test3-marker.txt -Force' \
  -Persist registry \
  -Encrypt \
  -Trigger AtLogOn,AtStartup,OnIdle,OnUnlock \
  -OutputFile /tmp/vm-test3.txt
```

### Deploy (on Windows VM):

Copy OPTION 1 from `/tmp/vm-test3.txt`, paste into PowerShell (admin).

### Verify (on Windows VM):

```powershell
# Check registry Run keys
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' | Format-List

# If admin, check HKLM too
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -EA 0 | Format-List

# Find companion task (name from manifest: <TaskName>-Monitor or similar suffix)
Get-ScheduledTask | Where-Object { $_.TaskName -match 'Monitor|Worker|Helper|Service|Handler' }

# Store companion task name
$ctn = (Get-ScheduledTask | Where-Object { $_.TaskName -match 'Monitor|Worker' })[0].TaskName

# Check companion task triggers
$ct = Get-ScheduledTask -TaskName $ctn
$ct.Triggers | ForEach-Object {
  Write-Host "$($_.CimClass.CimClassName) - Delay: $($_.Delay) - RandomDelay: $($_.RandomDelay)"
}

# Execute via registry Run command (logoff/logon) or trigger companion task
Start-ScheduledTask -TaskName $ctn
Start-Sleep -Seconds 3

# Check marker
Get-Content C:\test3-marker.txt
```

### PASS Criteria:

- HKCU Run key exists with obfuscated value name
- HKLM Run key exists if admin
- Companion task created with obfuscated name
- All four trigger types present in companion task (AtLogOn, AtStartup, OnIdle, OnUnlock)
- Marker file created

### Cleanup:

```powershell
# Get value name from manifest or search
$vn = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run').PSObject.Properties.Name | Where-Object { $_ -match 'Disk|TPM|Network' }
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $vn -EA 0
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $vn -EA 0

# Companion task
$ctn = (Get-ScheduledTask | Where-Object { $_.TaskName -match 'Monitor|Worker' })[0].TaskName
Unregister-ScheduledTask -TaskName $ctn -Confirm:$false -EA 0

# Clean up ADS and JScript
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' -EA 0 | Remove-Item -Force
Remove-Item 'C:\test3-marker.txt' -Force
```

---

## VM Test 4: Obfuscate Paranoid + Task Persist + Encrypt

**Goal:** Validate zero-width stream names + task name injection.

### Generate (on Linux):

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Paranoid \
  -Payload 'Write-Host "VM-Test-4-Paranoid" -ForegroundColor Magenta; "Test4-Pass" | Out-File C:\test4-marker.txt -Force' \
  -Persist task \
  -Encrypt \
  -OutputFile /tmp/vm-test4.txt
```

### Deploy (on Windows VM):

Copy OPTION 1 from `/tmp/vm-test4.txt`, paste into PowerShell (admin).

### Verify (on Windows VM):

```powershell
# Find task (will have zero-width chars in name)
Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM|Network|Defender' }

# Store task name and inspect codepoints
$task = Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM' } | Select-Object -First 1
$tn = $task.TaskName
$codepoints = ($tn.ToCharArray() | ForEach-Object { "U+{0:X4}" -f [int]$_ }) -join ' '
Write-Host "Task name codepoints: $codepoints"

# Check for zero-width characters (U+200B, U+200C, U+200D, U+FEFF, etc.)
if ($codepoints -match 'U\+200[BCD]|U\+FEFF|U\+061C|U\+180E|U\+2060') {
  Write-Host "PASS: Zero-width char detected in task name" -ForegroundColor Green
} else {
  Write-Host "FAIL: No zero-width char in task name" -ForegroundColor Red
}

# Check ADS stream name (get from manifest or runtime detection)
# Host path will be in deep directory
$hp = Get-ChildItem 'C:\ProgramData\Microsoft\Windows\WER' -Recurse -File | Select-Object -First 1 | Select-Object -ExpandProperty FullName
Get-Item $hp -Stream * | Where-Object { $_.Stream -ne ':$DATA' }

# Execute task
Start-ScheduledTask -TaskName $tn
Start-Sleep -Seconds 3

# Check marker
Get-Content C:\test4-marker.txt
```

### PASS Criteria:

- Task name contains zero-width Unicode character (verify via codepoints)
- Stream name contains zero-width characters (from manifest)
- Function names in JScript are clean Verb-Noun (no ZW)
- Marker file created

### Cleanup:

```powershell
# Unregister task using exact name (including ZW chars)
Unregister-ScheduledTask -TaskName $tn -Confirm:$false

# Clean up ADS using codepoint reconstruction from manifest
# Example: $sn = -join @([char]0x200B, [char]0x200C)
# Remove-Item "$hp`:$sn" -Force

# Clean up JScript
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' -EA 0 | Remove-Item -Force
Remove-Item 'C:\test4-marker.txt' -Force
```

---

## VM Test 5: Obfuscate Advanced + Jitter + Task Persist

**Goal:** Validate jitter (RandomDelay) on triggers.

### Generate (on Linux):

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "VM-Test-5-Jitter" -ForegroundColor Blue; "Test5-Pass" | Out-File C:\test5-marker.txt -Force' \
  -Persist task \
  -JitterPercent 30 \
  -PeriodicMinutes 10 \
  -OutputFile /tmp/vm-test5.txt
```

### Deploy (on Windows VM):

Copy OPTION 1 from `/tmp/vm-test5.txt`, paste into PowerShell (admin).

### Verify (on Windows VM):

```powershell
# Find task
$tn = (Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM|Network' })[0].TaskName
$task = Get-ScheduledTask -TaskName $tn

# Examine triggers for RandomDelay
$task.Triggers | ForEach-Object {
  $type = $_.CimClass.CimClassName
  $delay = $_.Delay
  $randomDelay = $_.RandomDelay
  Write-Host "$type : Delay=$delay, RandomDelay=$randomDelay"
}

# Check jitter calculation: 30% of 10 minutes = 3 minutes = PT3M
$periodicTrigger = $task.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskTimeTrigger' }
if ($periodicTrigger.RandomDelay -eq 'PT3M') {
  Write-Host "PASS: Jitter correct (PT3M)" -ForegroundColor Green
} else {
  Write-Host "FAIL: Jitter incorrect - got $($periodicTrigger.RandomDelay)" -ForegroundColor Red
}

# Execute task
Start-ScheduledTask -TaskName $tn
Start-Sleep -Seconds 3
Get-Content C:\test5-marker.txt
```

### PASS Criteria:

- Periodic trigger has `RandomDelay = PT3M` (ISO 8601 duration)
- AtLogOn/AtStartup triggers have `Delay = PT3M`
- Marker file created

### Cleanup:

```powershell
Unregister-ScheduledTask -TaskName $tn -Confirm:$false
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' -EA 0 | Remove-Item -Force
Remove-Item 'C:\test5-marker.txt' -Force
```

---

## VM Test 6: Obfuscate Advanced + Multi-Instance (InstanceCount 2)

**Goal:** Verify multiple independent deployments with unique paths/streams/tasks.

### Generate (on Linux):

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "VM-Test-6-Multi-Instance" -ForegroundColor White; "Test6-Pass-Instance-$([guid]::NewGuid().ToString().Substring(0,4))" | Out-File C:\test6-marker.txt -Append -Force' \
  -Persist task \
  -InstanceCount 2 \
  -OutputFile /tmp/vm-test6.txt
```

### Deploy (on Windows VM):

Copy OPTION 1 from `/tmp/vm-test6.txt`, paste into PowerShell (admin).

### Verify (on Windows VM):

```powershell
# Find all tasks created by this deployment
Get-ScheduledTask | Where-Object { $_.TaskName -match 'WinSAT_' }

# Should find 2 tasks with unique names
$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -match 'WinSAT_' }
Write-Host "Task count: $($tasks.Count)"

if ($tasks.Count -eq 2) {
  Write-Host "PASS: 2 instances created" -ForegroundColor Green
} else {
  Write-Host "FAIL: Expected 2 instances, got $($tasks.Count)" -ForegroundColor Red
}

# Execute both tasks
$tasks | ForEach-Object {
  Write-Host "Starting task: $($_.TaskName)"
  Start-ScheduledTask -TaskName $_.TaskName
}

Start-Sleep -Seconds 3

# Check marker file (should have 2 lines)
Get-Content C:\test6-marker.txt
$markerLines = (Get-Content C:\test6-marker.txt).Count
if ($markerLines -eq 2) {
  Write-Host "PASS: Both instances executed" -ForegroundColor Green
} else {
  Write-Host "FAIL: Expected 2 marker lines, got $markerLines" -ForegroundColor Red
}
```

### PASS Criteria:

- 2 scheduled tasks created with unique names
- 2 ADS host files created (or 2 streams on different files)
- Both tasks execute successfully
- Marker file has 2 lines

### Cleanup:

```powershell
# Unregister all WinSAT_ tasks
Get-ScheduledTask | Where-Object { $_.TaskName -match 'WinSAT_' } | ForEach-Object {
  Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false
}

# Clean up host files (randomized paths)
Get-ChildItem 'C:\ProgramData' -Filter '*.dat' -EA 0 | Remove-Item -Force
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' -EA 0 | Remove-Item -Force
Remove-Item 'C:\test6-marker.txt' -Force
```

---

## VM Test 7: Obfuscate Advanced + Decoy Streams + Encrypt

**Goal:** Verify decoy ADS creation alongside real payload.

### Generate (on Linux):

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "VM-Test-7-Decoys" -ForegroundColor DarkCyan; "Test7-Pass" | Out-File C:\test7-marker.txt -Force' \
  -Persist task \
  -Encrypt \
  -CreateDecoys 3 \
  -OutputFile /tmp/vm-test7.txt
```

### Deploy (on Windows VM):

Copy OPTION 1 from `/tmp/vm-test7.txt`, paste into PowerShell (admin).

### Verify (on Windows VM):

```powershell
# Find host file (will be in deep directory or randomized path)
$hp = Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.dat' -EA 0 | Select-Object -First 1 | Select-Object -ExpandProperty FullName

# List all ADS streams
Get-Item $hp -Stream *

# Should see 4 streams: :$DATA (default), payload stream, + 3 decoys (Zone.Identifier, Summary, Comments)
$streams = Get-Item $hp -Stream * | Where-Object { $_.Stream -ne ':$DATA' }
Write-Host "Stream count (excluding :$DATA): $($streams.Count)"

if ($streams.Count -eq 4) {
  Write-Host "PASS: 1 payload + 3 decoy streams" -ForegroundColor Green
} else {
  Write-Host "FAIL: Expected 4 streams, got $($streams.Count)" -ForegroundColor Red
}

# Check decoy content
Get-Content "${hp}:Zone.Identifier" -Raw
Get-Content "${hp}:Summary" -Raw
Get-Content "${hp}:Comments" -Raw

# Execute task
$tn = (Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM|Network' })[0].TaskName
Start-ScheduledTask -TaskName $tn
Start-Sleep -Seconds 3
Get-Content C:\test7-marker.txt
```

### PASS Criteria:

- 4 ADS streams total (1 payload + 3 decoys)
- Decoy streams have benign content (e.g., `[ZoneTransfer]`, `Document summary`)
- Real payload executes correctly
- Marker file created

### Cleanup:

```powershell
Unregister-ScheduledTask -TaskName $tn -Confirm:$false
Remove-Item $hp -Force
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' -EA 0 | Remove-Item -Force
Remove-Item 'C:\test7-marker.txt' -Force
```

---

## VM Test 8: Override Test — Advanced with All Overrides Disabled

**Goal:** Verify explicit overrides disable tier-implied defaults.

### Generate (on Linux):

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -UseDeepPlacement:$false \
  -AttachToExisting:$false \
  -Randomize:$false \
  -Payload 'Write-Host "VM-Test-8-Override" -ForegroundColor DarkYellow; "Test8-Pass" | Out-File C:\test8-marker.txt -Force' \
  -Persist task \
  -OutputFile /tmp/vm-test8.txt
```

### Deploy (on Windows VM):

Copy OPTION 1 from `/tmp/vm-test8.txt`, paste into PowerShell (admin).

### Verify (on Windows VM):

```powershell
# Host file should be at DEFAULT path (not deep placement)
Get-Item 'C:\ProgramData\SystemCache.dat' -Stream *

# Task name should still be obfuscated (tier-level applies to names)
$tn = (Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM|Network|Memory' })[0].TaskName
Write-Host "Task name: $tn"

# Stream name should be static (not randomized)
$streams = Get-Item 'C:\ProgramData\SystemCache.dat' -Stream * | Where-Object { $_.Stream -ne ':$DATA' }
Write-Host "Stream name: $($streams[0].Stream)"

# Execute task
Start-ScheduledTask -TaskName $tn
Start-Sleep -Seconds 3
Get-Content C:\test8-marker.txt
```

### PASS Criteria:

- Host file at default path `C:\ProgramData\SystemCache.dat`
- Stream name is static (e.g., `payload`)
- Task name is still obfuscated (Verb-Noun from word list)
- Marker file created

### Cleanup:

```powershell
Unregister-ScheduledTask -TaskName $tn -Confirm:$false
Remove-Item 'C:\ProgramData\SystemCache.dat' -Force
Get-ChildItem 'C:\ProgramData' -Filter '*.js' -EA 0 | Remove-Item -Force
Remove-Item 'C:\test8-marker.txt' -Force
```

---

## VM Test 9: Backward Compat — -ZeroWidthStreams Without Explicit -Obfuscate

**Goal:** Verify `-ZeroWidthStreams` auto-upgrades to Paranoid tier.

### Generate (on Linux):

```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -ZeroWidthStreams \
  -ZeroWidthMode hybrid \
  -HybridPrefix 'Zone.Identifier' \
  -Payload 'Write-Host "VM-Test-9-ZW-Compat" -ForegroundColor DarkMagenta; "Test9-Pass" | Out-File C:\test9-marker.txt -Force' \
  -Persist task \
  -OutputFile /tmp/vm-test9.txt
```

### Deploy (on Windows VM):

Copy OPTION 1 from `/tmp/vm-test9.txt`, paste into PowerShell (admin).

### Verify (on Windows VM):

```powershell
# Task should have zero-width char in name
$task = Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM|Network|Defender' } | Select-Object -First 1
$tn = $task.TaskName
$codepoints = ($tn.ToCharArray() | ForEach-Object { "U+{0:X4}" -f [int]$_ }) -join ' '
Write-Host "Task name codepoints: $codepoints"

if ($codepoints -match 'U\+200[BCD]|U\+FEFF') {
  Write-Host "PASS: Auto-upgraded to Paranoid (ZW in task name)" -ForegroundColor Green
} else {
  Write-Host "FAIL: No ZW chars - tier upgrade failed" -ForegroundColor Red
}

# Stream should be hybrid mode (Zone.Identifier + ZW suffix)
$hp = Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.dat' -EA 0 | Select-Object -First 1 | Select-Object -ExpandProperty FullName
$streams = Get-Item $hp -Stream * | Where-Object { $_.Stream -ne ':$DATA' }
Write-Host "Stream name: $($streams[0].Stream)"

# Execute task
Start-ScheduledTask -TaskName $tn
Start-Sleep -Seconds 3
Get-Content C:\test9-marker.txt
```

### PASS Criteria:

- Obfuscation level upgraded to Paranoid
- Task name has zero-width char
- Stream name is hybrid (e.g., `Zone.Identifier` + ZW suffix)
- Marker file created

### Cleanup:

```powershell
Unregister-ScheduledTask -TaskName $tn -Confirm:$false
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.dat' -EA 0 | Remove-Item -Force
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' -EA 0 | Remove-Item -Force
Remove-Item 'C:\test9-marker.txt' -Force
```

---

# Section 3: Common Verification Commands

**Reusable PowerShell commands for finding ADS artifacts during any test.**

## Find All Scheduled Tasks Created by ADS

```powershell
Get-ScheduledTask | Where-Object {
  $_.TaskName -match 'System|Disk|TPM|Network|Defender|Memory|USB|WinSAT|Language|Speech|Crypto|Background|Device'
} | Format-Table TaskName, State, LastRunTime
```

## Find All ADS Streams in ProgramData

```powershell
Get-ChildItem 'C:\ProgramData' -Recurse -File -EA 0 | ForEach-Object {
  $streams = Get-Item $_.FullName -Stream * -EA 0 | Where-Object { $_.Stream -ne ':$DATA' }
  if ($streams) {
    Write-Host "File: $($_.FullName)" -ForegroundColor Yellow
    $streams | Format-Table Stream, Length
  }
}
```

## Find All JScript Wrappers

```powershell
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' -EA 0 | Select-Object FullName, Length, LastWriteTime
```

## Check Registry Run Keys

```powershell
# HKCU
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' | Format-List

# HKLM (requires admin)
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -EA 0 | Format-List
```

## Reconstruct Zero-Width Stream Name from Manifest Codepoints

```powershell
# Example: Manifest says "Codepoints: U+200B U+200C U+FEFF"
$codepoints = "U+200B U+200C U+FEFF"

# Convert to stream name
$points = $codepoints -split '\s+' | ForEach-Object {
  $cleaned = $_ -replace '^U\+', ''
  [int]"0x$cleaned"
}
$sn = -join ($points | ForEach-Object { [char]$_ })

Write-Host "Stream name: [$sn] (length: $($sn.Length) chars)"

# Use in cleanup
$hp = 'C:\ProgramData\...'  # Get from manifest or runtime
Remove-Item "$hp`:$sn" -Force
```

## Inspect Zero-Width Characters in Task Name

```powershell
$tn = 'DiskCleanupTask'  # Replace with actual task name from Get-ScheduledTask

$chars = $tn.ToCharArray()
$codepoints = ($chars | ForEach-Object { "U+{0:X4}" -f [int]$_ }) -join ' '
$bytes = ([System.Text.Encoding]::Unicode.GetBytes($tn) | ForEach-Object { "0x{0:X2}" -f $_ }) -join ' '

Write-Host "Task name: $tn"
Write-Host "Codepoints: $codepoints"
Write-Host "Byte sequence: $bytes"
Write-Host "Contains zero-width: $(if ($codepoints -match 'U\+200[BCD]|U\+FEFF|U\+061C|U\+180E|U\+2060') { 'YES' } else { 'NO' })"
```

## Extract JScript Path from Task Action

```powershell
$tn = 'DiskCleanupTask'  # Replace with actual task name
$task = Get-ScheduledTask -TaskName $tn
$action = $task.Actions[0]

if ($action.Arguments -match '"([^"]+\.js)"') {
  $jsPath = $Matches[1]
  Write-Host "JScript path: $jsPath"

  if (Test-Path $jsPath) {
    $jsContent = Get-Content $jsPath -Raw
    Write-Host "JScript content ($($jsContent.Length) chars):"
    Write-Host $jsContent.Substring(0, [Math]::Min(500, $jsContent.Length))
  }
}
```

---

# Section 4: Snapshot Workflow

**Best practices for VM snapshot management during comprehensive testing.**

## Pre-Testing Setup

1. **Provision VM:** Windows Server 2022 or Windows 10/11 Pro
2. **Install Prerequisites:**
   - PowerShell 5.1 or 7.x
   - Network isolation (disconnect from internet)
   - Windows Defender enabled (tests evasion)
3. **Take Baseline Snapshot:** Name: `ADS-Clean-Baseline-2026-02-15`

## Between Tests

1. **Restore to Baseline:** Revert to `ADS-Clean-Baseline` snapshot
2. **Verify Clean State:**
   ```powershell
   Get-ScheduledTask | Where-Object { $_.TaskName -match 'System|Disk|TPM|WinSAT' }
   Get-ChildItem 'C:\ProgramData' -Filter '*.js' -EA 0
   Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' | Format-List
   ```
3. **Expected:** No tasks, no JScript wrappers, no Run keys

## After All Tests Pass

1. **Take Success Snapshot:** Name: `ADS-All-Tests-Pass-2026-02-15`
2. **Document Results:** Update `tests/VALIDATION-RUNBOOK.md` with test completion date
3. **Export Logs:** Save test output to `tests/vm-test-results-2026-02-15.log`

## Quick Restore Commands

```powershell
# VMware Workstation
& 'C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe' revertToSnapshot "C:\VMs\Win2022-ADS-Test\Win2022-ADS-Test.vmx" "ADS-Clean-Baseline-2026-02-15"

# Hyper-V
Restore-VMSnapshot -Name 'ADS-Clean-Baseline-2026-02-15' -VMName 'Win2022-ADS-Test' -Confirm:$false
```

---

# Summary

This comprehensive test suite covers:

- **10 Linux pre-flight tests** (syntax, parameter validation, output generation)
- **9 Windows VM tests** (deployment, execution, persistence, cleanup)
- **Common verification commands** (reusable for any test)
- **Snapshot management workflow** (efficient VM testing)

**Total estimated testing time:**
- Linux pre-flight: 15-20 minutes
- Windows VM tests: 60-90 minutes (with snapshots)
- **Total: ~2 hours for full validation**

**Test Coverage:**
- All 4 obfuscation tiers (None, Basic, Advanced, Paranoid)
- Both persistence methods (task, registry)
- All trigger types (AtLogOn, AtStartup, OnIdle, OnUnlock)
- Encryption + jitter + multi-instance + decoys + zero-width streams
- Tier-implied defaults + explicit overrides
- Backward compatibility with legacy flags

---

**End of Comprehensive Test Suite**
