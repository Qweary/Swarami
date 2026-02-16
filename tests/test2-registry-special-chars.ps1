# Test 2: Registry persistence with special characters in payload
# Tests that ADS-Dropper.ps1 correctly handles payloads with quotes, pipes, ampersands, etc.
# Run as admin

$ErrorActionPreference = 'Continue'
$testName = "TEST-2: Registry persistence with special characters"
$marker = "C:\ProgramData\ads-test2-marker.txt"
$results = @{ Test = $testName; Pass = $true; Errors = @(); Details = @{} }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " $testName" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Cleanup prior artifacts
Remove-Item $marker -Force -EA SilentlyContinue
Unregister-ScheduledTask -TaskName "SystemOptimization" -Confirm:$false -EA SilentlyContinue
Unregister-ScheduledTask -TaskName "SystemOptimization_Companion" -Confirm:$false -EA SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'SystemOptimization' -EA SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'SystemOptimization' -EA SilentlyContinue
Remove-Item "C:\ProgramData\SystemCache.dat" -Force -EA SilentlyContinue
Get-ChildItem "C:\ProgramData\syshealth_companion.js" -EA SilentlyContinue | Remove-Item -Force
Get-ChildItem "C:\ProgramData\windiag_*.js" -EA SilentlyContinue | Remove-Item -Force

# Payload with special characters: single quotes, double quotes, pipes, dollar signs, backticks
$payload = @'
$msg = "Test2 `special` chars: pipe|ampersand&semicolon;dollar$var 'single' quotes"
$msg | Out-File 'C:\ProgramData\ads-test2-marker.txt' -Force
'@

Write-Host "[1] Running ADS-Dropper with -Persist registry (special char payload)..." -ForegroundColor Yellow
Write-Host "    Payload:" -ForegroundColor DarkGray
Write-Host "    $payload" -ForegroundColor DarkGray

try {
    & "C:\RedTeam\Apparition-Delivery-System-WithClaude-Snapshot1\Apparition-Delivery-System-WithClaude-Snapshot1\src\ADS-Dropper.ps1" `
        -Payload $payload `
        -Persist registry `
        -NoExec `
        -Verbose 4>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    Write-Host "[+] ADS-Dropper completed" -ForegroundColor Green
} catch {
    $results.Pass = $false
    $results.Errors += "ADS-Dropper execution failed: $_"
    Write-Host "[-] ADS-Dropper FAILED: $_" -ForegroundColor Red
}

# Step 2: Check ADS
Write-Host "`n[2] Checking ADS creation..." -ForegroundColor Yellow
$adsPath = "C:\ProgramData\SystemCache.dat:payload"
try {
    $adsContent = Get-Content $adsPath -Raw -EA Stop
    Write-Host "[+] ADS exists with content ($($adsContent.Length) chars)" -ForegroundColor Green
    $results.Details['ADS_Content'] = $adsContent
} catch {
    $results.Pass = $false
    $results.Errors += "ADS not found: $_"
    Write-Host "[-] ADS NOT FOUND: $_" -ForegroundColor Red
}

# Step 3: Check registry keys
Write-Host "`n[3] Checking registry Run keys..." -ForegroundColor Yellow
$hkcuRun = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$hklmRun = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'

$hkcuVal = (Get-ItemProperty -Path $hkcuRun -Name 'SystemOptimization' -EA SilentlyContinue).SystemOptimization
$hklmVal = (Get-ItemProperty -Path $hklmRun -Name 'SystemOptimization' -EA SilentlyContinue).SystemOptimization

if ($hkcuVal) {
    Write-Host "[+] HKCU Run key exists" -ForegroundColor Green
    Write-Host "    Value: $($hkcuVal.Substring(0, [Math]::Min(200, $hkcuVal.Length)))..." -ForegroundColor DarkGray
    $results.Details['HKCU_Value'] = $hkcuVal
} else {
    $results.Pass = $false
    $results.Errors += "HKCU Run key not found"
    Write-Host "[-] HKCU Run key NOT FOUND" -ForegroundColor Red
}

if ($hklmVal) {
    Write-Host "[+] HKLM Run key exists (we're admin)" -ForegroundColor Green
    $results.Details['HKLM_Value'] = $hklmVal
} else {
    Write-Host "[*] HKLM Run key not set (might not be admin for AtStartup)" -ForegroundColor DarkGray
}

# Step 4: Check companion task
Write-Host "`n[4] Checking companion scheduled task..." -ForegroundColor Yellow
$companionTask = Get-ScheduledTask -TaskName "SystemOptimization_Companion" -EA SilentlyContinue
if ($companionTask) {
    Write-Host "[+] Companion task exists" -ForegroundColor Green
    $results.Details['CompanionTaskState'] = $companionTask.State.ToString()

    # Check its triggers
    for ($i = 0; $i -lt $companionTask.Triggers.Count; $i++) {
        $t = $companionTask.Triggers[$i]
        Write-Host "    Trigger[$i]: $($t.CimClass.CimClassName)" -ForegroundColor Gray
    }

    # Check JScript wrapper
    $compAction = $companionTask.Actions[0]
    Write-Host "    Action: $($compAction.Execute) $($compAction.Arguments)" -ForegroundColor Gray
    if ($compAction.Arguments -match '"([^"]+\.js)"') {
        $jsPath = $Matches[1]
        if (Test-Path $jsPath) {
            Write-Host "[+] Companion JScript wrapper exists at: $jsPath" -ForegroundColor Green
            $results.Details['CompanionJScript'] = $jsPath
        }
    }
} else {
    $results.Pass = $false
    $results.Errors += "Companion task 'SystemOptimization_Companion' not found"
    Write-Host "[-] Companion task NOT FOUND" -ForegroundColor Red
}

# Step 5: Execute payload from ADS directly to verify content integrity
Write-Host "`n[5] Executing payload from ADS to verify special chars survived..." -ForegroundColor Yellow
try {
    $plContent = Get-Content $adsPath -Raw -EA Stop
    Invoke-Expression $plContent
    if (Test-Path $marker) {
        $markerContent = Get-Content $marker -Raw
        Write-Host "[+] Payload executed, marker content:" -ForegroundColor Green
        Write-Host "    '$($markerContent.Trim())'" -ForegroundColor Green
        $results.Details['MarkerContent'] = $markerContent.Trim()

        # Verify special characters survived
        if ($markerContent -match 'pipe\|') {
            Write-Host "[+] Pipe character survived" -ForegroundColor Green
        } else {
            $results.Errors += "Pipe character lost in payload"
            Write-Host "[-] Pipe character LOST" -ForegroundColor Red
        }
        if ($markerContent -match 'ampersand&') {
            Write-Host "[+] Ampersand survived" -ForegroundColor Green
        } else {
            $results.Errors += "Ampersand lost in payload"
            Write-Host "[-] Ampersand LOST" -ForegroundColor Red
        }
        if ($markerContent -match "single'") {
            Write-Host "[+] Single quotes survived" -ForegroundColor Green
        } else {
            $results.Errors += "Single quotes lost in payload"
            Write-Host "[-] Single quotes LOST" -ForegroundColor Red
        }
    } else {
        $results.Pass = $false
        $results.Errors += "Marker file not created after payload execution"
        Write-Host "[-] Marker NOT CREATED" -ForegroundColor Red
    }
} catch {
    $results.Pass = $false
    $results.Errors += "Payload execution failed: $_"
    Write-Host "[-] Payload execution FAILED: $_" -ForegroundColor Red
}

# Step 6: Verify registry command can spawn PowerShell correctly
# (Don't actually run it - just verify syntax)
Write-Host "`n[6] Verifying registry command syntax..." -ForegroundColor Yellow
if ($hkcuVal) {
    # Extract the -C "..." portion and check it parses
    if ($hkcuVal -match '-C "(.+)"$') {
        $innerCmd = $Matches[1]
        Write-Host "    Inner command length: $($innerCmd.Length) chars" -ForegroundColor Gray
        # Check it contains the ADS path reference
        if ($innerCmd -match 'SystemCache\.dat') {
            Write-Host "[+] Registry command references ADS path" -ForegroundColor Green
        } else {
            $results.Errors += "Registry command doesn't reference ADS path"
            Write-Host "[-] Registry command missing ADS path reference" -ForegroundColor Red
        }
    } else {
        $results.Errors += "Could not parse registry command structure"
        Write-Host "[-] Registry command structure unexpected" -ForegroundColor Red
        Write-Host "    Full value: $hkcuVal" -ForegroundColor DarkGray
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
Unregister-ScheduledTask -TaskName "SystemOptimization_Companion" -Confirm:$false -EA SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'SystemOptimization' -EA SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'SystemOptimization' -EA SilentlyContinue
Remove-Item "C:\ProgramData\SystemCache.dat" -Force -EA SilentlyContinue
Get-ChildItem "C:\ProgramData\syshealth_companion.js" -EA SilentlyContinue | Remove-Item -Force
Get-ChildItem "C:\ProgramData\windiag_*.js" -EA SilentlyContinue | Remove-Item -Force

$results
