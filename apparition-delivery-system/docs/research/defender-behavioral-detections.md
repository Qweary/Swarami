# Windows Defender Behavioral Detection Research Log

Purpose: Persistent, append-only log of AV detection hits, root cause analysis, and evasion findings.
Never delete entries — cross them out with [RESOLVED] and note what fixed it.

Format: newest entries at top.

---

## [2026-02-16] PShellCobStager.A — GZip Decompress + IEX Chain

**Detection:** `Behavior:Win32/PShellCobStager.A` — Severity: Severe
**Triggered by:** Compression decompression stub in ADS-OneLiner.ps1 v2.3
**Exact pattern that triggered:**
```powershell
$gz=[IO.Compression.GZipStream]::new($ms,[IO.Compression.CompressionMode]::Decompress)
$sr=[IO.StreamReader]::new($gz)
IEX $sr.ReadToEnd()
```
**Why it fired:** This exact pattern (decompress MemoryStream → StreamReader → IEX) is a known Cobalt Strike stager behavioral signature. Defender's behavioral engine maps it to the PShellCobStager family regardless of the actual payload content. The detection is heuristic, not signature-based — the payload bytes don't matter, the execution *pattern* does.

**Context:** Introduced when compression feature was added (v2.3). Compression reduced payload size by ~50% but introduced this detection. AMSI bypass (XOR Fragment Splitting) protects the deployment script but NOT the decompression stub at execution time — the stub runs after AMSI bypass window.

**Status:** OPEN — needs evasion approach

**Evasion approaches to test (in order of preference):**
1. Obfuscate type names — never use `GZipStream` or `StreamReader` as adjacent plain strings; reconstruct via char array or string concat
2. Use Deflate instead of GZip — `[IO.Compression.DeflateStream]` — different API surface, less mapped
3. Wrap decompression stub inside Layer B XOR bypass so it's never plaintext at scan time
4. Replace IEX with `[scriptblock]::Create($content).Invoke()` — different execution path
5. Add artificial delay between decompress and execute (may break behavioral correlation window)

**Research links to check:** 
- Search: `"PShellCobStager" Defender behavioral signature evasion`
- Elastic rules: https://github.com/elastic/detection-rules/search?q=gzip+powershell
- Sigma: https://github.com/SigmaHQ/sigma/search?q=GZipStream

**Assigned to:** WIS-001 + DEA-001 for next session

---

## [2026-02-16] Silent Failure — ADS Write to Locked System File

**Detection:** Not AV — operational failure
**Triggered by:** Deep placement selecting `qmgr.db` (BITS queue manager database)
**Error:** `Could not open the alternate data stream 'X' of the file 'C:\ProgramData\Microsoft\Network\Downloader\qmgr.db'`
**Root cause:** qmgr.db is held open exclusively by the BITS service at all times. Deep placement candidate filter had no awareness of service-locked files.
**Compounding issue:** Script printed `[+] Deployment complete` despite ADS write failure — silent failure with false success message.

**Status:** OPEN

**Fix required:**
1. Add denylist to deep placement candidate filter
2. Add mandatory post-write verification of ADS existence
3. Never print deployment success if ADS write failed

**Known always-locked files to add to denylist:**
- `qmgr.db`, `qmgr.dat` (BITS)
- `*.edb` files (ESE database — used by many Windows services)
- `srudb.dat` (SRUM — System Resource Usage Monitor)
- `WebCacheV01.dat` (Edge/IE cache database)
- Active `*.etl` files in ETW-monitored directories

**Assigned to:** CAS-001 + WIS-001

---

## [Template for future entries]

## [YYYY-MM-DD] <Detection Name or Issue Title>

**Detection:** <AV detection name and severity OR "operational failure">
**Triggered by:** <exact feature/code that caused it>
**Exact pattern:** <code block if applicable>
**Why it fired:** <root cause analysis>
**Status:** OPEN / RESOLVED / INVESTIGATING
**Evasion approaches tested:**
- Approach 1: [result]
- Approach 2: [result]
**What worked:** <if resolved>
**Research links:** <URLs>
**Assigned to:** <agent IDs>
