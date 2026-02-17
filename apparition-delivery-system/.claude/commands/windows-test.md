---
description: Generate a complete Windows VM test procedure for a feature or bug fix, with PowerShell-only validation scripts
---

Generate a Windows VM test procedure for: $ARGUMENTS

Use the `test-validator` agent and `windows-internals` agent. All output must be Windows-compatible.

Generate in this exact structure:

**PRE-TEST SETUP (run before pasting payload):**
```powershell
# Snapshot reminder — always snapshot before testing
Write-Host "REMINDER: Take a VM snapshot now before running this test" -ForegroundColor Yellow

# Clear relevant event logs for clean test
wevtutil cl "Microsoft-Windows-Windows Defender/Operational"
wevtutil cl "Microsoft-Windows-TaskScheduler/Operational"

# Record baseline state
$baselineTasks = Get-ScheduledTask | Select-Object TaskName
$baselineStreams = @()  # Will compare after deployment
Write-Host "Baseline captured" -ForegroundColor Cyan
```

**DEPLOYMENT STEP:**
[Insert generated one-liner or readable commands here]

**POST-DEPLOYMENT VALIDATION (PowerShell only, no bash):**
[TVA-001 generates this — must use Select-String not grep, if/else not &&/||]

**DEFENDER EVENT CHECK:**
```powershell
Start-Sleep -Seconds 5  # Allow Defender to process
$defenderEvents = Get-WinEvent -LogName 'Microsoft-Windows-Windows Defender/Operational' `
    -MaxEvents 10 -ErrorAction SilentlyContinue |
    Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-3) }

if ($defenderEvents) {
    Write-Host "DEFENDER EVENTS DETECTED:" -ForegroundColor Red
    $defenderEvents | Select-Object TimeCreated, Id, Message | Format-List
} else {
    Write-Host "No Defender events in last 3 minutes" -ForegroundColor Green
}
```

**TASK SCHEDULER EVENT CHECK:**
```powershell
Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' `
    -MaxEvents 20 -ErrorAction SilentlyContinue |
    Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-5) } |
    Select-Object TimeCreated, Id, Message |
    Format-List
```

**CLEANUP:**
[OSA-001 generates cleanup commands from manifest]

**WHAT TO REPORT BACK:**
- Screenshot or paste of PASS/FAIL output from validation
- Any Defender events (copy full Message field)
- Any Task Scheduler errors
- Exact task name created (for verification)
