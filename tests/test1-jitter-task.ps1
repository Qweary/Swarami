# Test 1: Jitter with -Persist task
# Tests that ADS-Dropper.ps1 correctly creates a scheduled task with jitter (RandomDelay)
# Run as admin

$ErrorActionPreference = 'Continue'
$testName = "TEST-1: Jitter with -Persist task"
$marker = "C:\ProgramData\ads-test1-marker.txt"
$results = @{ Test = $testName; Pass = $true; Errors = @(); Details = @{} }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " $testName" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Cleanup any prior test artifacts
Remove-Item $marker -Force -EA SilentlyContinue
Unregister-ScheduledTask -TaskName "SystemOptimization" -Confirm:$false -EA SilentlyContinue
Remove-Item "C:\ProgramData\SystemCache.dat" -Force -EA SilentlyContinue
Get-ChildItem "C:\ProgramData\syshealth_check.js" -EA SilentlyContinue | Remove-Item -Force

# Step 1: Run ADS-Dropper with jitter + task persistence
Write-Host "[1] Running ADS-Dropper with -Persist task -JitterPercent 20 -PeriodicMinutes 5..." -ForegroundColor Yellow

$payload = "'Test1-Jitter-Task' | Out-File '$marker' -Force"

try {
    $dropperOutput = & "C:\RedTeam\Apparition-Delivery-System-WithClaude-Snapshot1\Apparition-Delivery-System-WithClaude-Snapshot1\src\ADS-Dropper.ps1" `
        -Payload $payload `
        -Persist task `
        -JitterPercent 20 `
        -PeriodicMinutes 5 `
        -NoExec `
        -Verbose 4>&1

    Write-Host "[+] ADS-Dropper completed" -ForegroundColor Green
    $dropperOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
} catch {
    $results.Pass = $false
    $results.Errors += "ADS-Dropper execution failed: $_"
    Write-Host "[-] ADS-Dropper FAILED: $_" -ForegroundColor Red
}

# Step 2: Check ADS was created
Write-Host "`n[2] Checking ADS creation..." -ForegroundColor Yellow
$adsPath = "C:\ProgramData\SystemCache.dat:payload"
$adsContent = $null
try {
    $adsContent = Get-Content $adsPath -Raw -EA Stop
    Write-Host "[+] ADS exists with content ($($adsContent.Length) chars)" -ForegroundColor Green
    $results.Details['ADS_Content'] = $adsContent.Substring(0, [Math]::Min(100, $adsContent.Length))
} catch {
    $results.Pass = $false
    $results.Errors += "ADS not found: $_"
    Write-Host "[-] ADS NOT FOUND: $_" -ForegroundColor Red
}

# Step 3: Check scheduled task was created
Write-Host "`n[3] Checking scheduled task..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName "SystemOptimization" -EA SilentlyContinue
if ($task) {
    Write-Host "[+] Task 'SystemOptimization' exists" -ForegroundColor Green
    $results.Details['TaskState'] = $task.State.ToString()

    # Step 4: Examine triggers for RandomDelay (jitter)
    Write-Host "`n[4] Examining triggers for jitter (RandomDelay)..." -ForegroundColor Yellow
    $taskInfo = Get-ScheduledTaskInfo -TaskName "SystemOptimization" -EA SilentlyContinue

    $triggerCount = $task.Triggers.Count
    Write-Host "    Trigger count: $triggerCount" -ForegroundColor Gray
    $results.Details['TriggerCount'] = $triggerCount

    $jitterFound = $false
    for ($i = 0; $i -lt $task.Triggers.Count; $i++) {
        $trigger = $task.Triggers[$i]
        $triggerType = $trigger.CimClass.CimClassName
        $randomDelay = $trigger.RandomDelay

        Write-Host "    Trigger[$i]: Type=$triggerType, RandomDelay='$randomDelay'" -ForegroundColor Gray
        $results.Details["Trigger_${i}_Type"] = $triggerType
        $results.Details["Trigger_${i}_RandomDelay"] = "$randomDelay"

        if ($randomDelay -and $randomDelay -ne '' -and $randomDelay -ne 'PT0S' -and $randomDelay -ne 'P0D') {
            $jitterFound = $true
        }
    }

    if ($jitterFound) {
        Write-Host "[+] JITTER FOUND on at least one trigger" -ForegroundColor Green
    } else {
        $results.Pass = $false
        $results.Errors += "No RandomDelay (jitter) found on any trigger"
        Write-Host "[-] NO JITTER FOUND on any trigger" -ForegroundColor Red
    }

    # Step 5: Check task action (JScript wrapper)
    Write-Host "`n[5] Checking task action..." -ForegroundColor Yellow
    $action = $task.Actions[0]
    Write-Host "    Execute: $($action.Execute)" -ForegroundColor Gray
    Write-Host "    Arguments: $($action.Arguments)" -ForegroundColor Gray
    $results.Details['Action_Execute'] = $action.Execute
    $results.Details['Action_Arguments'] = $action.Arguments

    # Extract JS path from arguments
    if ($action.Arguments -match '"([^"]+\.js)"') {
        $jsPath = $Matches[1]
        if (Test-Path $jsPath) {
            $jsContent = Get-Content $jsPath -Raw
            Write-Host "[+] JScript wrapper exists at: $jsPath ($($jsContent.Length) chars)" -ForegroundColor Green
            $results.Details['JScript_Path'] = $jsPath
            $results.Details['JScript_ContentLength'] = $jsContent.Length
            # Show first 200 chars
            Write-Host "    Content preview: $($jsContent.Substring(0, [Math]::Min(200, $jsContent.Length)))..." -ForegroundColor DarkGray
        } else {
            $results.Pass = $false
            $results.Errors += "JScript wrapper not found at: $jsPath"
            Write-Host "[-] JScript wrapper NOT FOUND at: $jsPath" -ForegroundColor Red
        }
    } else {
        $results.Pass = $false
        $results.Errors += "Could not extract JScript path from arguments: $($action.Arguments)"
        Write-Host "[-] Could not extract JScript path from arguments" -ForegroundColor Red
    }

    # Step 6: Execute payload via ADS to verify it works
    Write-Host "`n[6] Executing payload from ADS to verify..." -ForegroundColor Yellow
    try {
        $plContent = Get-Content $adsPath -Raw
        Invoke-Expression $plContent
        if (Test-Path $marker) {
            $markerContent = Get-Content $marker -Raw
            Write-Host "[+] Payload executed successfully, marker contains: $($markerContent.Trim())" -ForegroundColor Green
            $results.Details['PayloadExecuted'] = $true
        } else {
            $results.Pass = $false
            $results.Errors += "Payload executed but marker file not created"
            Write-Host "[-] Marker file not created" -ForegroundColor Red
        }
    } catch {
        $results.Pass = $false
        $results.Errors += "Payload execution failed: $_"
        Write-Host "[-] Payload execution FAILED: $_" -ForegroundColor Red
    }

} else {
    $results.Pass = $false
    $results.Errors += "Scheduled task 'SystemOptimization' not found"
    Write-Host "[-] TASK NOT FOUND" -ForegroundColor Red

    # Debug: list all tasks containing relevant keywords
    Write-Host "`n    Searching for any ADS-related tasks..." -ForegroundColor DarkGray
    Get-ScheduledTask | Where-Object { $_.TaskName -match 'System|WinSAT|Optimization' } | ForEach-Object {
        Write-Host "    Found: $($_.TaskName) ($($_.State))" -ForegroundColor DarkGray
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($results.Pass) {
    Write-Host " RESULT: PASS" -ForegroundColor Green
} else {
    Write-Host " RESULT: FAIL" -ForegroundColor Red
    Write-Host " Errors:" -ForegroundColor Red
    $results.Errors | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
}
Write-Host "========================================`n" -ForegroundColor Cyan

# Cleanup
Write-Host "[*] Cleaning up test artifacts..." -ForegroundColor DarkGray
Remove-Item $marker -Force -EA SilentlyContinue
Unregister-ScheduledTask -TaskName "SystemOptimization" -Confirm:$false -EA SilentlyContinue
Remove-Item "C:\ProgramData\SystemCache.dat" -Force -EA SilentlyContinue
# Clean up JScript wrapper
if ($results.Details['JScript_Path']) {
    Remove-Item $results.Details['JScript_Path'] -Force -EA SilentlyContinue
}
Get-ChildItem "C:\ProgramData\syshealth_check.js" -EA SilentlyContinue | Remove-Item -Force

# Return results object
$results
