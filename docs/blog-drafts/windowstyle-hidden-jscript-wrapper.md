---
layout: post
title: "The -WindowStyle Hidden Trap: Why Task Scheduler Breaks PowerShell Window Hiding"
date: 2026-02-14
categories: [windows-internals, red-team, evasion]
tags: [powershell, task-scheduler, jscript, persistence, opsec]
---

# The -WindowStyle Hidden Trap: Why Task Scheduler Breaks PowerShell Window Hiding

If you've ever tried to create stealthy PowerShell persistence using Windows Task Scheduler, you've probably discovered this the hard way: **`-WindowStyle Hidden` doesn't work from scheduled tasks**. You get a bright blue PowerShell window flashing on screen for a fraction of a second — just long enough for any alert user to notice something's wrong.

This issue has bitten red teamers for years. Many offensive tools still get it wrong, and the documentation around *why* it fails is sparse. I ran into this while building the Apparition Delivery System (ADS), a PowerShell framework that uses NTFS Alternate Data Streams for hiding and persistence. Here's what I learned about why `-WindowStyle Hidden` fails, and how a JScript wrapper solves it completely.

## The Discovery: A Bright Blue Flash

I was testing scheduled task persistence for ADS on a Windows 10 VM. The plan was simple:
1. Create a scheduled task that runs at user logon
2. Launch PowerShell with `-WindowStyle Hidden` to suppress the window
3. Execute the payload from an ADS stream with zero visibility

The task registered successfully. I rebooted. The payload executed. But there was a problem: **a bright blue PowerShell window flashed on screen for ~200ms before disappearing**. Not exactly stealthy.

I triple-checked the task configuration — `-WindowStyle Hidden` was definitely in the command. I tested the same PowerShell command from `cmd.exe` manually, and the window stayed hidden perfectly. So why did Task Scheduler behave differently?

## The Technical Root Cause

The answer lies in **when** the window style flag gets processed during process creation.

### How Task Scheduler Creates Processes

When Task Scheduler launches a program, it uses the Task Scheduler service (`svchost.exe -k netsvcs -p -s Schedule`). This service calls `CreateProcessAsUser` to spawn the task's executable. Here's the key distinction:

- **SYSTEM tasks in Session 0** (non-interactive): These run in the background session with no visible desktop. The window never appears because there's nowhere to render it. `-WindowStyle Hidden` is technically irrelevant.

- **User-context tasks in interactive sessions**: Tasks with `-AtLogOn` triggers or tasks configured to run as a specific user execute in Session 1+ (the interactive desktop session). These *can* create visible windows.

### The Problem: Process Creation Timing

When Task Scheduler spawns `powershell.exe` in an interactive session:

1. **CreateProcessAsUser** is called by the Task Scheduler service
2. A window station and desktop are assigned to the new process *before PowerShell.exe starts*
3. The process inherits default window creation flags from Task Scheduler
4. A visible console window appears immediately
5. **PowerShell's startup code eventually processes `-WindowStyle Hidden`** and hides the window
6. But steps 4 and 5 aren't atomic — there's a ~100-500ms gap where the window is visible

The `-WindowStyle Hidden` flag is a **PowerShell-level** parameter, not an OS-level process creation flag. By the time PowerShell parses its command-line arguments and calls the Windows API to hide its own window, the damage is done.

### Why Manual Execution Works

When you run the same command from `cmd.exe` or another PowerShell session:
```powershell
powershell.exe -WindowStyle Hidden -NoProfile -Command "Write-Host 'test'"
```
...it works perfectly because the *parent process* (cmd.exe or the existing PowerShell session) has already established a hidden window context before spawning the child. The timing is tight enough that no visible flash occurs.

But Task Scheduler doesn't know about PowerShell's `-WindowStyle` flag — it just sees an executable path and arguments. It creates the process with default window settings.

## The Solution: JScript Wrapper Shim

The fix is to interpose a layer between Task Scheduler and PowerShell — something that can set the window style *before* process creation. Enter **WScript.Shell**.

### Why JScript?

JScript (Microsoft's ECMAScript implementation) has access to `WScript.Shell`, a COM object that provides a `Run` method with a critical parameter: **window style**. The signature is:

```javascript
intReturn = shell.Run(strCommand, [intWindowStyle], [bWaitOnReturn])
```

The `intWindowStyle` parameter accepts the same values as the Win32 `ShowWindow` API:
- `0` = `SW_HIDE` (completely hidden)
- `1` = `SW_SHOWNORMAL` (default visible)
- `2` = `SW_SHOWMINIMIZED` (minimized)

Crucially, **this window style is applied at `CreateProcess` time**, not after the fact. The process is born hidden.

### The Implementation

Here's the actual JScript wrapper code from ADS (simplified for clarity):

```javascript
var shell = new ActiveXObject("WScript.Shell");
var cmd = "powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -Command \"" +
    "IEX(Get-Content 'C:\\ProgramData\\sysdata.dat:payload' -Raw)" +
    "\"";
shell.Run(cmd, 0, false);
```

Breaking it down:
- `new ActiveXObject("WScript.Shell")` — creates the COM object
- `cmd` — the full PowerShell command line, properly escaped for JScript string concatenation
- `shell.Run(cmd, 0, false)` — executes the command with `SW_HIDE` (0), without waiting for completion

### Task Scheduler Configuration

The scheduled task now looks like this:

```powershell
$action = New-ScheduledTaskAction -Execute "wscript.exe" `
    -Argument "//B //E:JScript `"C:\ProgramData\wrapper.js`""
```

The flags:
- `//B` — **Batch mode**: suppresses all user prompts and error dialogs from wscript.exe itself
- `//E:JScript` — **Explicit engine selection**: forces the JScript engine (vs. VBScript, which is the default for .vbs files)

### Why ASCII Encoding Matters

One gotcha I discovered: **wscript.exe chokes on UTF-8 BOM** (Byte Order Mark). PowerShell's default `Out-File` uses UTF-8 with BOM, which causes wscript to fail silently. The fix:

```powershell
$jsContent | Out-File -FilePath $jsPath -Encoding ASCII -Force
```

ASCII is a safe subset that wscript.exe handles reliably.

## Why Not VBScript?

VBScript works fine for this purpose:
```vbscript
CreateObject("WScript.Shell").Run "powershell.exe ...", 0, False
```

So why did I choose JScript for ADS?

1. **Better string handling**: JScript's string concatenation is cleaner for building complex command lines (especially when embedding functions and escaping nested quotes).

2. **Lower signature density**: Most AV heuristics are tuned to VBScript patterns because malware has historically favored `.vbs` files. JScript (`.js`) is less frequently flagged.

3. **Modern familiarity**: `.js` files look less suspicious than `.vbs` to analysts — they could plausibly be legitimate build scripts, Node.js tooling artifacts, etc.

4. **Dual-use**: JScript can be embedded in HTML Application (.hta) files for more advanced delivery vectors.

## Detection Guidance for Blue Teams

Let's flip the perspective. If you're defending against this technique, here's what to look for.

### 1. Process Ancestry Chain

The telltale signature is:
```
svchost.exe (Task Scheduler) → wscript.exe → powershell.exe
```

This chain is **extremely rare** in legitimate enterprise environments. Filter Sysmon Event ID 1 (Process Create) for:
- `ParentImage` ends with `\svchost.exe`
- `ParentCommandLine` contains `-s Schedule`
- `Image` ends with `\wscript.exe`
- `CommandLine` contains `//B //E:JScript` OR `//B //NoLogo`

Then pivot to child processes spawned by that wscript.exe instance:
- `ParentImage` ends with `\wscript.exe`
- `Image` ends with `\powershell.exe`

**Reality check**: If you see this chain, it's almost certainly malicious. Legitimate scheduled tasks don't use JScript shims to launch PowerShell.

### 2. Security Event 4698 (Task Created)

When the task is registered, Event ID 4698 captures the full task XML. Search for:
```xml
<Actions>
  <Exec>
    <Command>C:\Windows\System32\wscript.exe</Command>
    <Arguments>//B //E:JScript "C:\ProgramData\something.js"</Arguments>
  </Exec>
</Actions>
```

The combination of `wscript.exe` + `//B` + `.js` file in `C:\ProgramData` or temp directories is a strong indicator.

### 3. PowerShell Script Block Logging

Enable Script Block Logging (Event ID 4104). Even if the PowerShell window is hidden, **the full command is captured**:
```
IEX(Get-Content 'C:\ProgramData\sysdata.dat:payload' -Raw)
```

Reading from NTFS Alternate Data Streams (the `:payload` suffix) is another red flag. Legitimate software almost never uses ADS for execution.

### 4. File System Artifacts

JScript files on disk:
- Common locations: `C:\ProgramData`, `C:\Windows\Temp`, `%APPDATA%`
- Filename patterns: Generic system names (`syshealth_check.js`, `windiag_*.js`, `msupdate_*.js`)
- File content: `WScript.Shell` + `powershell.exe` + `Run` method

Use autoruns tools or file integrity monitoring to detect new `.js` files in system directories.

### 5. Sigma Rules

Here's a starter Sigma rule for detecting this pattern:

```yaml
title: Scheduled Task Launches PowerShell via JScript Wrapper
status: experimental
description: Detects wscript.exe spawned by Task Scheduler launching PowerShell
references:
    - https://github.com/Qweary/Apparition-Delivery-System
author: Queue
date: 2026/02/14
logsource:
    category: process_creation
    product: windows
detection:
    selection_parent:
        ParentImage|endswith: '\svchost.exe'
        ParentCommandLine|contains: 'Schedule'
    selection_wscript:
        Image|endswith: '\wscript.exe'
        CommandLine|contains:
            - '//B'
            - '//E:JScript'
    selection_powershell:
        ParentImage|endswith: '\wscript.exe'
        Image|endswith: '\powershell.exe'
    condition: (selection_parent and selection_wscript) or selection_powershell
falsepositives:
    - Rare legitimate automation frameworks (validate with whitelisting)
level: high
tags:
    - attack.persistence
    - attack.t1053.005  # Scheduled Task/Job: Scheduled Task
    - attack.t1059.001  # Command and Scripting Interpreter: PowerShell
```

### The Honest Assessment

**If you're a blue teamer and you see wscript.exe spawning powershell.exe from a scheduled task, that's almost certainly malicious.** There are vanishingly few legitimate use cases for this pattern. Flag it, investigate the JScript source, and check the task's XML configuration.

The JScript wrapper technique trades one detection vector (visible window OPSEC failure) for another (suspicious process chain). It's not invisible — it's just different. Good telemetry catches it.

## Lessons Learned

Building offensive tooling teaches you Windows internals in ways that documentation never does. Here are my takeaways from this particular rabbit hole:

### 1. Flags Operate at Different Layers

`-WindowStyle Hidden` is a PowerShell-level flag, not an OS-level process creation flag. That distinction matters when you're working with indirection layers like Task Scheduler. Always ask: **when** does the flag take effect in the process lifecycle?

### 2. Test in the Real Environment

The `-WindowStyle Hidden` command worked perfectly when I tested it manually from a PowerShell prompt. It failed completely when launched from Task Scheduler. **Test your persistence mechanisms in the exact execution context they'll use in production.** Don't assume behavior transfers across invocation methods.

### 3. Every Evasion Has a Detection Surface

The JScript wrapper solves the visibility problem completely — zero blue flashes, zero visible windows. But it creates a highly distinctive process chain that's trivial to detect with proper logging. There's no such thing as a perfect evasion technique. **Understand the tradeoffs.**

### 4. Document the "Why"

I've seen dozens of offensive tools that use JScript wrappers for Task Scheduler persistence, but almost none of them explain *why*. Comments like "// use jscript for stealth" don't help the next person who has to maintain the code. **Document the root cause, not just the solution.**

## Conclusion

The `-WindowStyle Hidden` trap is a well-known issue, but it's still poorly documented in most red team tooling. PowerShell can't hide its own window when spawned by Task Scheduler because the window is created before PowerShell gets control. A JScript wrapper solves this by setting the hidden window style at `CreateProcess` time.

Is it invisible to defenders? No. The `svchost.exe → wscript.exe → powershell.exe` chain is highly distinctive and easy to detect with Sysmon or EDR telemetry. But it solves the immediate OPSEC problem of a visible blue window flashing on screen.

The real lesson: **Windows internals matter**. Process creation, window stations, session isolation, and COM invocation semantics all interact in subtle ways. Offensive tooling requires understanding these interactions at the API level, not just scripting surface features.

The full implementation (including AES-256 encryption, ADS stream hiding, and AMSI bypass) is available in the [Apparition Delivery System repository](https://github.com/Qweary/Apparition-Delivery-System). The `Build-JScriptWrapper` function in `src/ADS-Dropper.ps1` contains the complete code, and `Create-ScheduledTaskPersistence` shows the Task Scheduler integration.

Use it for authorized security research and CCDC competition only. And remember: if you're building offensive tools, always think about the blue team's perspective. Every technique you use is also a detection opportunity for defenders.

---

**About the Apparition Delivery System**: ADS is a PowerShell framework designed for CCDC (Collegiate Cyber Defense Competition) red team operations. It exploits NTFS Alternate Data Streams to hide encrypted payloads, uses hardware-derived keys for encryption, and implements dual-layer AMSI bypass. The project emphasizes honest representation of capabilities and detection surfaces — offensive research should benefit both red and blue teams.

**Authorized Use Only**: This research is intended for authorized security testing, competition environments (CCDC), and defensive research. Deploying these techniques against systems without explicit authorization is illegal and unethical.
