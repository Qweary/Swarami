---
description: Run a structured AV evasion test cycle for a specific technique or code pattern
---

Run an AV evasion test cycle for: $ARGUMENTS

Use the `av-evasion-researcher` agent to lead this workflow:

1. Read `docs/research/defender-behavioral-detections.md` for prior findings on this technique
2. Use WebSearch/WebFetch to pull current intelligence on the detection family
3. Identify the minimum triggering code unit (ask Queue to binary-search if needed)
4. Generate THREE evasion variants in order of least-to-most invasive change:
   - Variant A: string obfuscation only
   - Variant B: execution path substitution
   - Variant C: API surface replacement
5. For each variant, generate BOTH:
   - A Linux test: `pwsh ./src/ADS-OneLiner.ps1 ... -OutputFile /tmp/av-test-variantA.txt`
   - A Windows validation script (PowerShell-only syntax) to run after deployment
6. Generate a Defender event capture command to run during testing:
```powershell
   # Run this on Windows VM before testing each variant:
   Get-WinEvent -LogName 'Microsoft-Windows-Windows Defender/Operational' -MaxEvents 20 |
       Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-5) } |
       Select-Object TimeCreated, Id, Message |
       Format-List
```
7. After Queue reports results, update `docs/research/defender-behavioral-detections.md` with findings
8. If all three variants are detected, escalate to Queue with full research findings — do not continue without new intelligence

Present results as: detection family confirmed, variants generated (with copy-paste commands), what to capture during Windows testing, and how to report back.
