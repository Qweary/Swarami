---
description: Run a full threat model and detection assessment on a feature or technique using detection-engineering and opsec-specialist agents
---

Run a threat model and detection assessment on: $ARGUMENTS

Use the `detection-engineering` agent and `opsec-specialist` agent to analyze:

1. All telemetry sources that capture this technique (Sysmon events, PowerShell logs, Task Scheduler events, process creation, network)
2. Forensic artifacts created (filesystem, registry, event logs, Prefetch, SRUM, MFT, USN Journal)
3. Detection likelihood rating (Low/Medium/High) with justification
4. Which artifacts survive cleanup and which are permanent
5. Specific detection rules a blue team could write to catch this
6. Recommended evasion improvements to reduce detection surface — DEA-001 identifies the surface, then call av-evasion-researcher to propose specific evasion variants if a detection has already fired
7. Recommended blue team detection rules to add to `defense/Detect-ZeroWidthADS.ps1`

Present as a concise threat model with clear offensive recommendations (how to be stealthier) and defensive recommendations (how to detect better).
