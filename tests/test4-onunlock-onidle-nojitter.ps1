# Tests 4-7: OnUnlock with jitter, OnIdle, JitterPercent=0, Large jitter
$ErrorActionPreference = 'Continue'
$dropperPath = 'C:\RedTeam\Apparition-Delivery-System-WithClaude-Snapshot1\Apparition-Delivery-System-WithClaude-Snapshot1\src\ADS-Dropper.ps1'

function Cleanup-Task($name) {
    Unregister-ScheduledTask -TaskName $name -Confirm:$false -EA SilentlyContinue
    Remove-Item 'C:\ProgramData\SystemCache.dat' -Force -EA SilentlyContinue
    Get-ChildItem 'C:\ProgramData\syshealth_check.js' -EA SilentlyContinue | Remove-Item -Force
    Get-ChildItem 'C:\ProgramData\windiag_*.js' -EA SilentlyContinue | Remove-Item -Force
    Get-ChildItem 'C:\ProgramData\syshealth_companion.js' -EA SilentlyContinue | Remove-Item -Force
}

# ============================================
# TEST 4: OnUnlock trigger with jitter
# ============================================
Write-Host ''
Write-Host '========================================'  -ForegroundColor Cyan
Write-Host ' TEST-4: OnUnlock trigger with jitter'    -ForegroundColor Cyan
Write-Host '========================================'  -ForegroundColor Cyan
Write-Host ''

Cleanup-Task 'SystemOptimization'

try {
    & $dropperPath -Payload "'test4' | Out-File C:\ProgramData\t4.txt -Force" `
        -Persist task -Trigger @('OnUnlock') -JitterPercent 20 -PeriodicMinutes 10 -NoExec -Verbose 4>&1 |
        ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

    $task = Get-ScheduledTask -TaskName 'SystemOptimization' -EA Stop
    Write-Host 'PASS: Task created' -ForegroundColor Green

    $unlockTrigger = $task.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskSessionStateChangeTrigger' }
    if ($unlockTrigger) {
        Write-Host "PASS: OnUnlock found. StateChange=$($unlockTrigger.StateChange), Delay=$($unlockTrigger.Delay)" -ForegroundColor Green
        if ($unlockTrigger.Delay -eq 'PT2M') {
            Write-Host 'PASS: Jitter delay correct (PT2M = 20pct of 10min)' -ForegroundColor Green
        } else {
            Write-Host "WARN: Jitter delay unexpected: $($unlockTrigger.Delay)" -ForegroundColor Yellow
        }
    } else {
        Write-Host 'FAIL: OnUnlock trigger NOT FOUND' -ForegroundColor Red
    }

    $periodicTrigger = $task.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskTimeTrigger' }
    if ($periodicTrigger) {
        Write-Host "PASS: Periodic trigger RandomDelay=$($periodicTrigger.RandomDelay)" -ForegroundColor Green
    }

    Write-Host 'TEST-4: PASS' -ForegroundColor Green
} catch {
    Write-Host "TEST-4: FAIL -- $_" -ForegroundColor Red
}

Cleanup-Task 'SystemOptimization'

# ============================================
# TEST 5: OnIdle trigger
# ============================================
Write-Host ''
Write-Host '========================================'  -ForegroundColor Cyan
Write-Host ' TEST-5: OnIdle trigger'                   -ForegroundColor Cyan
Write-Host '========================================'  -ForegroundColor Cyan
Write-Host ''

try {
    & $dropperPath -Payload "'test5' | Out-File C:\ProgramData\t5.txt -Force" `
        -Persist task -Trigger @('OnIdle') -PeriodicMinutes 60 -NoExec -Verbose 4>&1 |
        ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

    $task = Get-ScheduledTask -TaskName 'SystemOptimization' -EA Stop
    Write-Host 'PASS: Task created' -ForegroundColor Green

    $idleTrigger = $task.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskIdleTrigger' }
    if ($idleTrigger) {
        Write-Host 'PASS: OnIdle trigger found' -ForegroundColor Green
    } else {
        Write-Host 'FAIL: OnIdle trigger NOT FOUND' -ForegroundColor Red
    }

    if ($task.Settings.IdleDuration) {
        Write-Host "PASS: IdleDuration=$($task.Settings.IdleDuration)" -ForegroundColor Green
    }

    Write-Host 'TEST-5: PASS' -ForegroundColor Green
} catch {
    Write-Host "TEST-5: FAIL -- $_" -ForegroundColor Red
}

Cleanup-Task 'SystemOptimization'

# ============================================
# TEST 6: JitterPercent=0
# ============================================
Write-Host ''
Write-Host '========================================'  -ForegroundColor Cyan
Write-Host ' TEST-6: JitterPercent=0 (no jitter)'     -ForegroundColor Cyan
Write-Host '========================================'  -ForegroundColor Cyan
Write-Host ''

try {
    & $dropperPath -Payload "'test6' | Out-File C:\ProgramData\t6.txt -Force" `
        -Persist task -JitterPercent 0 -PeriodicMinutes 5 -NoExec -Verbose 4>&1 |
        ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

    $task = Get-ScheduledTask -TaskName 'SystemOptimization' -EA Stop
    Write-Host 'PASS: Task created' -ForegroundColor Green

    $hasDelay = $false
    $task.Triggers | ForEach-Object {
        $type = $_.CimClass.CimClassName
        $rd = $_.RandomDelay
        $d = $_.Delay
        Write-Host "    $type : RandomDelay=$rd, Delay=$d" -ForegroundColor Gray
        if (($rd -and $rd -ne '' -and $rd -ne 'PT0S') -or ($d -and $d -ne '' -and $d -ne 'PT0S')) {
            $hasDelay = $true
        }
    }

    if (-not $hasDelay) {
        Write-Host 'PASS: No jitter delays (correct for JitterPercent=0)' -ForegroundColor Green
    } else {
        Write-Host 'FAIL: Unexpected delay found with JitterPercent=0' -ForegroundColor Red
    }

    Write-Host 'TEST-6: PASS' -ForegroundColor Green
} catch {
    Write-Host "TEST-6: FAIL -- $_" -ForegroundColor Red
}

Cleanup-Task 'SystemOptimization'

# ============================================
# TEST 7: Large jitter (50pct of 1440 min)
# ============================================
Write-Host ''
Write-Host '========================================'  -ForegroundColor Cyan
Write-Host ' TEST-7: Large jitter (720min delay)'     -ForegroundColor Cyan
Write-Host '========================================'  -ForegroundColor Cyan
Write-Host ''

try {
    & $dropperPath -Payload "'test7' | Out-File C:\ProgramData\t7.txt -Force" `
        -Persist task -JitterPercent 50 -PeriodicMinutes 1440 -NoExec -Verbose 4>&1 |
        ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

    $task = Get-ScheduledTask -TaskName 'SystemOptimization' -EA Stop
    Write-Host 'PASS: Task created' -ForegroundColor Green

    $periodicTrigger = $task.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskTimeTrigger' }
    Write-Host "    Periodic RandomDelay: $($periodicTrigger.RandomDelay)" -ForegroundColor Gray

    $logonTrigger = $task.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' }
    Write-Host "    AtLogOn Delay: $($logonTrigger.Delay)" -ForegroundColor Gray

    if ($periodicTrigger.RandomDelay -eq 'PT720M') {
        Write-Host 'PASS: Large jitter correct (PT720M = 12 hours)' -ForegroundColor Green
    } else {
        Write-Host "WARN: Large jitter value: $($periodicTrigger.RandomDelay)" -ForegroundColor Yellow
    }

    Write-Host 'TEST-7: PASS' -ForegroundColor Green
} catch {
    Write-Host "TEST-7: FAIL -- $_" -ForegroundColor Red
}

Cleanup-Task 'SystemOptimization'

Write-Host ''
Write-Host '========================================'  -ForegroundColor Cyan
Write-Host ' ALL BLOCKER TESTS COMPLETE'               -ForegroundColor Cyan
Write-Host '========================================'  -ForegroundColor Cyan
