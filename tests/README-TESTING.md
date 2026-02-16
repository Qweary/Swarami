# Testing Documentation Index

This directory contains validation tests for the Apparition Delivery System.

---

## Quick Start

**To validate the CCDC payload library after changes:**

```bash
# Option 1: Direct PowerShell execution
pwsh tests/validate-ccdc-library.ps1

# Option 2: Use wrapper script
bash tests/quick-validate.sh

# Option 3: Generate detailed report
pwsh tests/validate-ccdc-library.ps1 -OutputReport /tmp/test-report.txt
```

**Expected output**: `[✓] ALL TESTS PASSED — Library is ready for VM validation`

**Exit codes**: 0 = success, 1 = failure

---

## Files in This Directory

### Test Scripts

**validate-ccdc-library.ps1** (PowerShell 7.x)
- Comprehensive automated validation suite
- 13 test categories, 27+ individual checks
- Tests syntax, data structure, string integrity, regression detection
- Runs on Linux (no Windows VM required)
- ~10 second execution time

**quick-validate.sh** (Bash wrapper)
- Convenience wrapper for validate-ccdc-library.ps1
- Checks for pwsh availability
- Displays pass/fail summary
- Suitable for CI/CD integration

### Documentation

**VALIDATION-RUNBOOK.md**
- Complete test procedures and scenarios
- Phase 1 (Linux) and Phase 2 (Windows VM) instructions
- Test decision tree and risk analysis
- Step-by-step execution commands

**ANALYSIS-ccdc-library-notes-update.md**
- Detailed analysis of recent Notes field changes
- Regression risk assessment
- Specific test commands for Queue
- Validation checklist

**README-TESTING.md** (this file)
- Quick reference index
- Links to all test resources

---

## Test Coverage

### What Gets Tested

✓ PowerShell syntax parsing (no parse errors)
✓ File loading and dot-sourcing
✓ Data structure integrity ($Payloads hashtable)
✓ All 62 payloads present across 13 categories
✓ Field completeness (Desc, Cmd, Notes)
✓ String encoding and escaping
✓ Function availability (Show-Payloads, Get-Payload, Deploy-Payload)
✓ Regression detection (no unintended changes)
✓ Documentation quality (SYSTEM context warnings)

### What Doesn't Get Tested (Requires VM)

- Actual payload execution
- ADS stream creation and persistence
- Task Scheduler integration
- Encryption/decryption runtime behavior
- AMSI bypass effectiveness
- Cleanup command execution

**Rule of thumb**: If it's a code change in `src/`, run VM tests. If it's a data change in `payloads/`, automated tests are sufficient.

---

## When to Run Tests

**Always run before commit**:
- Modifying `payloads/ccdc-library.ps1`
- Adding new payloads
- Changing payload descriptions or commands
- Modifying utility functions (Show-Payloads, Get-Payload, Deploy-Payload)

**Also run VM tests if**:
- Modifying `src/ADS-Dropper.ps1`
- Modifying `src/ADS-OneLiner.ps1`
- Changing encryption logic
- Changing persistence mechanisms
- Preparing for a release or competition deployment

**Don't need to run tests for**:
- README updates
- Documentation changes in `docs/`
- CLAUDE.md modifications
- Coordination files in `coordination/`

---

## Test Matrix Reference

From TVA-001 system prompt, core scenarios:

1. Standalone ADS-Dropper.ps1 in PS 5.1
2. Standalone in PS 7.x
3. Encrypted payload deployment
4. Unencrypted payload deployment
5. Multi-instance deployment (`-InstanceCount 3`)
6. Zero-width stream creation and cleanup
7. Deep placement in diagnostic directories
8. Attach-to-existing file mode
9. Each persistence method (task, registry, none)
10. Cleanup command generation and execution
11. OPTION 1 (base64 one-liner) deployment
12. OPTION 2 (readable commands) deployment

**Library changes affect**: Integration scenarios (3-5, 11-12) only if Deploy-Payload used
**Core ADS scenarios (1-2, 6-10)**: Not affected by library changes

---

## Troubleshooting

**"pwsh: command not found"**
```bash
sudo apt install powershell -y
# Or on other distros: download from Microsoft
```

**"File not found: ccdc-library.ps1"**
```bash
# Run tests from project root:
cd /home/kali/Desktop/apparition/Apparition-Delivery-System
pwsh tests/validate-ccdc-library.ps1
```

**"Parse errors in library"**
- Check git diff for unintended changes
- Verify no unescaped quotes in Notes fields
- Run: `git diff HEAD payloads/ccdc-library.ps1`

**"Tests pass but library won't load in VM"**
- Check PowerShell version (need 5.1 or 7.x)
- Verify execution policy: `Set-ExecutionPolicy Bypass -Scope Process`
- Try: `. .\payloads\ccdc-library.ps1` (note the dot-space-dot)

---

## Integration with CI/CD

**GitLab CI example**:
```yaml
test-library:
  stage: test
  image: mcr.microsoft.com/powershell:latest
  script:
    - pwsh tests/validate-ccdc-library.ps1
  only:
    changes:
      - payloads/ccdc-library.ps1
```

**GitHub Actions example**:
```yaml
name: Validate Payload Library
on:
  push:
    paths:
      - 'payloads/ccdc-library.ps1'
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install PowerShell
        run: |
          sudo apt-get update
          sudo apt-get install -y powershell
      - name: Run Validation
        run: pwsh tests/validate-ccdc-library.ps1
```

**Pre-commit hook** (`.git/hooks/pre-commit`):
```bash
#!/bin/bash
# Run validation if ccdc-library.ps1 changed
if git diff --cached --name-only | grep -q "payloads/ccdc-library.ps1"; then
    echo "Validating payload library..."
    pwsh tests/validate-ccdc-library.ps1 || exit 1
fi
```

---

## Contributing New Tests

To add tests to `validate-ccdc-library.ps1`:

1. Add new test block after existing tests
2. Use `Write-TestResult` function for consistent output
3. Increment test number in section header
4. Update "Total Tests" count in README if adding new test categories
5. Document what the test validates in comments

**Template**:
```powershell
# ============================================================
# TEST X: Your Test Name
# ============================================================
Write-Host "`n[TEST X] Your Test Name" -ForegroundColor Yellow

try {
    # Test logic here
    $testResult = Your-TestFunction

    if ($testResult) {
        Write-TestResult -Test "Your test description" -Pass $true -Message "Success message"
    } else {
        Write-TestResult -Test "Your test description" -Pass $false -Message "Failure reason"
    }
} catch {
    Write-TestResult -Test "Your test name" -Pass $false -Message $_.Exception.Message
}
```

---

## Resources

**TVA-001 System Prompt**: `.claude/agents/test-validator.md`
**Project Authorization**: `docs/PROJECT-AUTHORIZATION.md`
**Safety Boundaries**: `docs/SAFETY-BOUNDARIES.md`
**Orchestration Guide**: `docs/orchestration-guide.md`

---

## Quick Reference Commands

```bash
# Standard validation (from project root):
pwsh tests/validate-ccdc-library.ps1

# With wrapper:
bash tests/quick-validate.sh

# Generate report:
pwsh tests/validate-ccdc-library.ps1 -OutputReport /tmp/report.txt

# Interactive spot-check:
pwsh
. ./payloads/ccdc-library.ps1
Get-Payload -Id FW-002
exit

# Check what changed:
git diff HEAD payloads/ccdc-library.ps1

# Revert if needed:
git checkout HEAD -- payloads/ccdc-library.ps1
```

---

**Last updated**: 2026-02-14
**Maintained by**: TVA-001 (Testing & Validation Agent)
