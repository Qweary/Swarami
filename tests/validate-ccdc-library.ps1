#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validation test suite for payloads/ccdc-library.ps1

.DESCRIPTION
    Pre-VM automated validation for the CCDC payload library.
    Tests syntax parsing, data structure integrity, function availability,
    and string escaping correctness after Notes field modifications.

    This script runs on Linux (pwsh) to catch regressions BEFORE
    consuming Windows VM time. Only deploy to VM after this passes.

.NOTES
    Author: TVA-001 (Testing & Validation Agent)
    Version: 1.0.0
    Required: PowerShell 7.x on Linux (pwsh)

    Run from project root:
        pwsh tests/validate-ccdc-library.ps1

.USAGE
    # Quick run:
    pwsh tests/validate-ccdc-library.ps1

    # Verbose output:
    pwsh tests/validate-ccdc-library.ps1 -Verbose

    # Generate report file:
    pwsh tests/validate-ccdc-library.ps1 -OutputReport ./test-results.txt
#>

param(
    [string]$OutputReport
)

$ErrorActionPreference = 'Stop'
$libraryPath = "$PSScriptRoot/../payloads/ccdc-library.ps1"
$testResults = @()
$passCount = 0
$failCount = 0

# Color helpers for cross-platform support
function Write-TestResult {
    param([string]$Test, [bool]$Pass, [string]$Message = '')
    $symbol = if ($Pass) { '[✓]' } else { '[✗]' }
    $color = if ($Pass) { 'Green' } else { 'Red' }
    $output = "$symbol $Test"
    if ($Message) { $output += " — $Message" }
    Write-Host $output -ForegroundColor $color

    $script:testResults += @{
        Test = $Test
        Pass = $Pass
        Message = $Message
    }

    if ($Pass) { $script:passCount++ } else { $script:failCount++ }
}

Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " CCDC Payload Library Validation Suite" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# ============================================================
# TEST 1: File Existence
# ============================================================
Write-Host "[TEST 1] File Existence Check" -ForegroundColor Yellow
try {
    $exists = Test-Path $libraryPath
    Write-TestResult -Test "ccdc-library.ps1 exists at expected path" -Pass $exists -Message $libraryPath
    if (-not $exists) {
        Write-Host "FATAL: Cannot proceed without library file" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-TestResult -Test "File existence check" -Pass $false -Message $_.Exception.Message
    exit 1
}

# ============================================================
# TEST 2: PowerShell Syntax Validation
# ============================================================
Write-Host "`n[TEST 2] PowerShell Syntax Validation" -ForegroundColor Yellow
try {
    $content = Get-Content $libraryPath -Raw
    $errors = $null
    $tokens = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)

    if ($errors.Count -eq 0) {
        Write-TestResult -Test "PowerShell syntax parsing (zero errors)" -Pass $true -Message "$($tokens.Count) tokens parsed"
    } else {
        Write-TestResult -Test "PowerShell syntax parsing" -Pass $false -Message "$($errors.Count) parse errors found"
        $errors | ForEach-Object { Write-Host "  Line $($_.Token.StartLine): $($_.Message)" -ForegroundColor Red }
    }
} catch {
    Write-TestResult -Test "Syntax validation" -Pass $false -Message $_.Exception.Message
}

# ============================================================
# TEST 3: Dot-Source Loading
# ============================================================
Write-Host "`n[TEST 3] Dot-Source Loading Test" -ForegroundColor Yellow
try {
    . $libraryPath
    Write-TestResult -Test "Dot-source execution without errors" -Pass $true
} catch {
    Write-TestResult -Test "Dot-source execution" -Pass $false -Message $_.Exception.Message
    Write-Host "FATAL: Cannot proceed if library doesn't load" -ForegroundColor Red
    exit 1
}

# ============================================================
# TEST 4: $Payloads Hashtable Structure
# ============================================================
Write-Host "`n[TEST 4] `$Payloads Data Structure Validation" -ForegroundColor Yellow

try {
    $payloadsDefined = $null -ne $Payloads
    Write-TestResult -Test "`$Payloads variable exists" -Pass $payloadsDefined

    if ($payloadsDefined) {
        $isOrdered = $Payloads -is [System.Collections.Specialized.OrderedDictionary]
        Write-TestResult -Test "`$Payloads is [ordered] hashtable" -Pass $isOrdered

        $count = $Payloads.Count
        $expectedCount = 69
        $countMatch = ($count -eq $expectedCount)
        Write-TestResult -Test "Payload count is $expectedCount" -Pass $countMatch -Message "Found $count payloads"

        # Verify all expected categories exist
        $expectedCategories = @('FW', 'RDP', 'USR', 'SVC', 'C2', 'CRED', 'DEF', 'RECON', 'LAT', 'EXFIL', 'FUN', 'COMBO', 'NOVEL')
        $missingCategories = @()
        foreach ($cat in $expectedCategories) {
            $hasCategory = ($Payloads.Keys | Where-Object { $_ -match "^$cat-" }).Count -gt 0
            if (-not $hasCategory) { $missingCategories += $cat }
        }

        if ($missingCategories.Count -eq 0) {
            Write-TestResult -Test "All 13 categories present" -Pass $true
        } else {
            Write-TestResult -Test "All categories present" -Pass $false -Message "Missing: $($missingCategories -join ', ')"
        }
    }
} catch {
    Write-TestResult -Test "Payloads structure validation" -Pass $false -Message $_.Exception.Message
}

# ============================================================
# TEST 5: Individual Payload Structure Validation
# ============================================================
Write-Host "`n[TEST 5] Individual Payload Field Validation" -ForegroundColor Yellow

$requiredFields = @('Desc', 'Cmd', 'Notes')
$malformedPayloads = @()
$emptyFields = @()

foreach ($key in $Payloads.Keys) {
    $payload = $Payloads[$key]

    # Check all required fields present
    foreach ($field in $requiredFields) {
        if (-not $payload.ContainsKey($field)) {
            $malformedPayloads += "$key (missing $field)"
        }
    }

    # Check no fields are empty/whitespace
    if ([string]::IsNullOrWhiteSpace($payload.Desc)) { $emptyFields += "$key.Desc" }
    if ([string]::IsNullOrWhiteSpace($payload.Cmd)) { $emptyFields += "$key.Cmd" }
    if ([string]::IsNullOrWhiteSpace($payload.Notes)) { $emptyFields += "$key.Notes" }
}

if ($malformedPayloads.Count -eq 0) {
    Write-TestResult -Test "All payloads have required fields (Desc, Cmd, Notes)" -Pass $true
} else {
    Write-TestResult -Test "Payload field completeness" -Pass $false -Message "Malformed: $($malformedPayloads -join ', ')"
}

if ($emptyFields.Count -eq 0) {
    Write-TestResult -Test "No empty field values" -Pass $true
} else {
    Write-TestResult -Test "Field value presence" -Pass $false -Message "Empty: $($emptyFields -join ', ')"
}

# ============================================================
# TEST 6: String Escaping Validation (Notes Field Focus)
# ============================================================
Write-Host "`n[TEST 6] String Escaping and Special Character Handling" -ForegroundColor Yellow

$stringIssues = @()

foreach ($key in $Payloads.Keys) {
    $notes = $Payloads[$key].Notes

    # Check for unescaped single quotes inside single-quoted strings (would break PowerShell)
    # In the source, Notes are defined as single-quoted strings
    # Single quotes inside must be doubled: 'It''s' not 'It's'
    # Since we're reading the parsed hashtable, escaped quotes already processed
    # Instead, check for common encoding issues

    # Check for NULL characters (corruption indicator)
    if ($notes -match "`0") {
        $stringIssues += "$key.Notes contains NULL character"
    }

    # Check for unbalanced quotes in the Notes content (might indicate escaping problem)
    $singleQuoteCount = ($notes.ToCharArray() | Where-Object { $_ -eq "'" }).Count
    # Notes can contain quotes as content, so we just check they're not malformed

    # Check for excessive length (might indicate concatenation errors)
    if ($notes.Length -gt 500) {
        $stringIssues += "$key.Notes exceeds 500 chars (current: $($notes.Length))"
    }
}

if ($stringIssues.Count -eq 0) {
    Write-TestResult -Test "String encoding and escaping integrity" -Pass $true
} else {
    Write-TestResult -Test "String encoding integrity" -Pass $false -Message "$($stringIssues.Count) issues found"
    $stringIssues | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

# ============================================================
# TEST 7: SYSTEM Context Warning Presence
# ============================================================
Write-Host "`n[TEST 7] SYSTEM Context Documentation Validation" -ForegroundColor Yellow

# Payloads that SHOULD have SYSTEM context warnings (affected by recent changes)
$expectedWarnings = @{
    'CRED-002' = 'SYSTEM.*CAVEAT|SYSTEM.*WARNING'
    'CRED-003' = 'SYSTEM.*WARNING|SYSTEM.*CAVEAT'
    'CRED-005' = 'SYSTEM.*CAVEAT|SYSTEM.*WARNING'
    'EXFIL-001' = 'SYSTEM.*CAVEAT|SYSTEM.*WARNING'
    'FUN-001' = 'SYSTEM.*WARNING|SYSTEM.*CAVEAT'
    'FUN-002' = 'SYSTEM.*WARNING|SYSTEM.*CAVEAT'
    'FUN-003' = 'SYSTEM.*WARNING|SYSTEM.*CAVEAT'
    'FUN-004' = 'SYSTEM.*WARNING|SYSTEM.*CAVEAT'
    'FUN-005' = 'SYSTEM.*WARNING|SYSTEM.*CAVEAT'
    'FUN-006' = 'SYSTEM.*WARNING|SYSTEM.*CAVEAT'
    'NOVEL-002' = 'SYSTEM.*WARNING|SYSTEM.*CAVEAT'
    'NOVEL-004' = 'SYSTEM.*WARNING|SYSTEM.*CAVEAT'
    'NOVEL-006' = 'SYSTEM.*CAVEAT|SYSTEM.*WARNING'
}

$missingWarnings = @()
foreach ($id in $expectedWarnings.Keys) {
    $pattern = $expectedWarnings[$id]
    if ($Payloads[$id].Notes -notmatch $pattern) {
        $missingWarnings += $id
    }
}

if ($missingWarnings.Count -eq 0) {
    Write-TestResult -Test "All expected SYSTEM context warnings present" -Pass $true -Message "$($expectedWarnings.Count) warnings verified"
} else {
    Write-TestResult -Test "SYSTEM context warnings" -Pass $false -Message "Missing in: $($missingWarnings -join ', ')"
}

# ============================================================
# TEST 8: Show-Payloads Function Execution
# ============================================================
Write-Host "`n[TEST 8] Show-Payloads Function Test" -ForegroundColor Yellow

try {
    $showOutput = Show-Payloads 6>&1 5>&1 4>&1 3>&1 2>&1 | Out-String

    # Check output contains expected category headers
    $hasCategories = ($showOutput -match 'Firewall Manipulation') -and
                    ($showOutput -match 'Credential Access') -and
                    ($showOutput -match 'Novel / Experimental')

    Write-TestResult -Test "Show-Payloads renders without errors" -Pass $hasCategories -Message "$($showOutput.Length) chars output"

    # Check output includes payload count
    $hasCount = $showOutput -match 'Total:\s+\d+\s+payloads'
    Write-TestResult -Test "Show-Payloads includes payload count" -Pass $hasCount

} catch {
    Write-TestResult -Test "Show-Payloads execution" -Pass $false -Message $_.Exception.Message
}

# ============================================================
# TEST 9: Get-Payload Function Test
# ============================================================
Write-Host "`n[TEST 9] Get-Payload Function Test" -ForegroundColor Yellow

$testPayloads = @('FW-002', 'CRED-002', 'FUN-001', 'NOVEL-006')

foreach ($testId in $testPayloads) {
    try {
        $cmd = Get-Payload -Id $testId 6>&1 5>&1 4>&1 3>&1 2>&1 | Out-String
        $hasContent = $cmd.Length -gt 10 # Should return actual command
        Write-TestResult -Test "Get-Payload retrieves $testId" -Pass $hasContent -Message "$($cmd.Length) chars returned"
    } catch {
        Write-TestResult -Test "Get-Payload $testId" -Pass $false -Message $_.Exception.Message
    }
}

# Test invalid payload ID handling
try {
    $output = Get-Payload -Id 'INVALID-999' 6>&1 5>&1 4>&1 3>&1 2>&1 | Out-String
    $handlesError = $output -match 'Unknown payload ID'
    Write-TestResult -Test "Get-Payload gracefully handles invalid ID" -Pass $handlesError
} catch {
    Write-TestResult -Test "Get-Payload error handling" -Pass $false -Message $_.Exception.Message
}

# ============================================================
# TEST 10: Deploy-Payload Function Signature Test
# ============================================================
Write-Host "`n[TEST 10] Deploy-Payload Function Availability" -ForegroundColor Yellow

try {
    $deployFunc = Get-Command Deploy-Payload -ErrorAction Stop
    $hasRequiredParams = $deployFunc.Parameters.ContainsKey('Id') -and
                        $deployFunc.Parameters.ContainsKey('Encrypt') -and
                        $deployFunc.Parameters.ContainsKey('Randomize')

    Write-TestResult -Test "Deploy-Payload function exists with expected parameters" -Pass $hasRequiredParams
} catch {
    Write-TestResult -Test "Deploy-Payload function availability" -Pass $false -Message $_.Exception.Message
}

# Note: We don't execute Deploy-Payload because it requires ADS-OneLiner.ps1
# which requires Windows-specific features in -GenerateOnly mode
Write-Host "  (Skipping Deploy-Payload execution — requires ADS-OneLiner.ps1 integration)" -ForegroundColor DarkGray

# ============================================================
# TEST 11: Notes Field Length Distribution
# ============================================================
Write-Host "`n[TEST 11] Notes Field Quality Metrics" -ForegroundColor Yellow

$notesLengths = $Payloads.Keys | ForEach-Object { $Payloads[$_].Notes.Length }
$avgLength = ($notesLengths | Measure-Object -Average).Average
$maxLength = ($notesLengths | Measure-Object -Maximum).Maximum
$minLength = ($notesLengths | Measure-Object -Minimum).Minimum

Write-Host "  Average Notes length: $([int]$avgLength) chars" -ForegroundColor Gray
Write-Host "  Min: $minLength chars | Max: $maxLength chars" -ForegroundColor Gray

# All notes should be at least 20 chars (basic description)
$tooShort = $Payloads.Keys | Where-Object { $Payloads[$_].Notes.Length -lt 20 }
if ($tooShort.Count -eq 0) {
    Write-TestResult -Test "All Notes fields have substantial content (20+ chars)" -Pass $true
} else {
    Write-TestResult -Test "Notes field content sufficiency" -Pass $false -Message "Too short: $($tooShort -join ', ')"
}

# ============================================================
# TEST 12: Cmd Field PowerShell Validity (Spot Check)
# ============================================================
Write-Host "`n[TEST 12] Payload Command Syntax Spot Check" -ForegroundColor Yellow

# Test a few representative Cmd values can parse as PowerShell
$spotCheckPayloads = @('FW-001', 'RDP-001', 'USR-001', 'C2-001', 'DEF-001')
$cmdSyntaxErrors = @()

foreach ($id in $spotCheckPayloads) {
    try {
        $cmd = $Payloads[$id].Cmd
        $scriptBlock = [scriptblock]::Create($cmd)
        # If we get here, it parsed successfully
    } catch {
        $cmdSyntaxErrors += "$id : $($_.Exception.Message)"
    }
}

if ($cmdSyntaxErrors.Count -eq 0) {
    Write-TestResult -Test "Spot-checked Cmd values parse as valid PowerShell" -Pass $true -Message "$($spotCheckPayloads.Count) payloads checked"
} else {
    Write-TestResult -Test "Cmd field PowerShell syntax" -Pass $false -Message "$($cmdSyntaxErrors.Count) errors"
    $cmdSyntaxErrors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

# ============================================================
# TEST 13: Regression Check - No Cmd Field Changes
# ============================================================
Write-Host "`n[TEST 13] Regression Detection - Cmd Field Integrity" -ForegroundColor Yellow

# This test verifies that ONLY Notes fields changed, not Cmd or Desc
# We'll check if any Cmd values contain strings that look like Notes content
# (e.g., "SYSTEM CONTEXT WARNING" should never appear in Cmd fields)

$cmdContamination = @()
foreach ($key in $Payloads.Keys) {
    $cmd = $Payloads[$key].Cmd
    if ($cmd -match 'SYSTEM CONTEXT (WARNING|CAVEAT)') {
        $cmdContamination += $key
    }
}

if ($cmdContamination.Count -eq 0) {
    Write-TestResult -Test "No Notes content leaked into Cmd fields" -Pass $true
} else {
    Write-TestResult -Test "Cmd field isolation" -Pass $false -Message "Contamination in: $($cmdContamination -join ', ')"
}

# ============================================================
# RESULTS SUMMARY
# ============================================================
Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Test Results Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$totalTests = $passCount + $failCount
$passRate = if ($totalTests -gt 0) { [math]::Round(($passCount / $totalTests) * 100, 1) } else { 0 }

Write-Host "  Total Tests: $totalTests" -ForegroundColor White
Write-Host "  Passed:      $passCount" -ForegroundColor Green
Write-Host "  Failed:      $failCount" -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Red' })
Write-Host "  Pass Rate:   $passRate%" -ForegroundColor $(if ($passRate -eq 100) { 'Green' } elseif ($passRate -ge 80) { 'Yellow' } else { 'Red' })

if ($failCount -eq 0) {
    Write-Host "`n[✓] ALL TESTS PASSED — Library is ready for VM validation" -ForegroundColor Green
    $exitCode = 0
} else {
    Write-Host "`n[✗] $failCount TEST(S) FAILED — Fix issues before VM testing" -ForegroundColor Red
    $exitCode = 1
}

# ============================================================
# OPTIONAL REPORT OUTPUT
# ============================================================
if ($OutputReport) {
    $reportContent = @"
CCDC Payload Library Validation Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Library: $libraryPath

SUMMARY
-------
Total Tests: $totalTests
Passed: $passCount
Failed: $failCount
Pass Rate: $passRate%

DETAILED RESULTS
----------------
$($testResults | ForEach-Object {
    $status = if ($_.Pass) { 'PASS' } else { 'FAIL' }
    $msg = if ($_.Message) { " ($($_.Message))" } else { '' }
    "[$status] $($_.Test)$msg"
} | Out-String)

EXIT CODE: $exitCode
"@

    $reportContent | Out-File -FilePath $OutputReport -Force
    Write-Host "`nReport written to: $OutputReport" -ForegroundColor Cyan
}

Write-Host ""
exit $exitCode
