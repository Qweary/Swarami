# Deep Placement Candidate Denylist

Purpose: Files that must NEVER be selected as ADS hosts by the deep placement logic.
These files are held open exclusively by running Windows services and cannot have ADS written to them.

Update this file whenever a new locked-file failure is discovered. Reference this in ADS-Dropper.ps1 code comments.

## Always-Locked Files (Deny by Filename Pattern)

| Pattern | Service | Reason |
|---------|---------|--------|
| `qmgr.db` | BITS (Background Intelligent Transfer) | Exclusive lock by svchost/BITS |
| `qmgr.dat` | BITS | Same service, legacy format |
| `*.edb` | ESE database engine (used by many services) | Exclusive lock by hosting service |
| `srudb.dat` | SRUM (System Resource Usage Monitor) | Exclusive lock by svchost |
| `WebCacheV01.dat` | Edge/IE browser history | Exclusive lock when browser running |
| `DataStore.edb` | Windows Update | Exclusive lock during update activity |
| `priv1.edb` | Windows Search (WSearch) | Exclusive lock by SearchIndexer.exe |
| `Windows.edb` | Windows Search | Same |
| `PerfStringBackup.INI` | Performance counters | Intermittent lock |

## Always-Locked Directories (Higher Risk, Avoid as Parent for New Files Too)

| Directory | Risk Reason |
|-----------|-------------|
| `C:\ProgramData\Microsoft\Network\Downloader\` | BITS owned, files recreated on service restart |
| `C:\Windows\System32\sru\` | SRUM owned |
| `C:\ProgramData\Microsoft\Search\Data\` | Windows Search owned |

## Safe Deep Placement Directories (Confirmed Working)

| Directory | Notes |
|-----------|-------|
| `C:\ProgramData\Microsoft\Windows\WER\ReportQueue\` | WER creates files here but doesn't lock them exclusively |
| `C:\ProgramData\Microsoft\Windows\WER\Temp\` | Same |
| `C:\ProgramData\Microsoft\Diagnosis\` | Low activity, safe |
| `C:\ProgramData\Microsoft\Windows\Power Efficiency Diagnostics\` | Low activity |
| `C:\Windows\Temp\` | Works but higher blue team visibility |

## Implementation Notes

In ADS-Dropper.ps1, the candidate filter should:
1. Check against denylist patterns BEFORE attempting ADS write
2. After selecting a candidate, attempt write and verify with `Get-Item -Stream *`
3. If write fails, remove candidate from pool and try next
4. Never print success until stream existence is verified
5. If all candidates fail, fall back to a known-safe path with a generated filename
```powershell
# Reference implementation for post-write verification:
$pl | Set-Content -Path "$hp`:$sn" -Force -ErrorAction SilentlyContinue
$verifyStream = Get-Item $hp -Stream $sn -ErrorAction SilentlyContinue
if (-not $verifyStream) {
    Write-Warning "ADS write failed on $hp — selecting fallback path"
    # fallback logic here
}
```
