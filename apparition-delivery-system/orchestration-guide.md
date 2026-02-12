# Multi-Agent Orchestration Guide

**Version:** 1.0  
**Date:** February 11, 2026  
**Purpose:** Coordinate six specialized Claude Code agents for ADS development

---

## Agent Overview

| Agent ID | Name | Specialization | Primary Role |
|----------|------|----------------|--------------|
| RTO-001 | Red Team Operations | Competition tactics, workflow optimization | Strategic guidance |
| WIS-001 | Windows Internals | OS behavior, PowerShell, NTFS | Technical debugging |
| DEA-001 | Detection Engineering | Blue team perspective, telemetry | Evasion validation |
| CAS-001 | Code Architecture | Structure, quality, maintainability | Code review |
| OSA-001 | OPSEC Specialist | Artifacts, anti-forensics, cleanup | Security review |
| PEA-001 | Payload Engineering | Library management, technique development | Payload expertise |

---

## Workflow Patterns

### Pattern 1: Feature Development

**Scenario:** Adding new feature to ADS tool

**Agent Collaboration:**

1. **RTO-001** (Red Team Ops): Evaluates operational value and priority
   - *"Does this feature improve speed, reliability, or stealth for CCDC?"*
   - *"What's the time budget impact? Is it worth the complexity?"*

2. **WIS-001** (Windows Internals): Assesses technical feasibility
   - *"Can this be implemented in PowerShell 5.1 and 7.x?"*
   - *"What Windows behaviors or quirks affect this feature?"*

3. **CAS-001** (Code Architecture): Designs integration approach
   - *"How does this fit into existing architecture?"*
   - *"What parameters are needed? How to maintain backward compatibility?"*

4. **Queue**: Makes final decision and implements with agent guidance

5. **DEA-001** (Detection Engineering): Reviews telemetry implications
   - *"What new artifacts does this create?"*
   - *"How detectable is this feature?"*

6. **OSA-001** (OPSEC Specialist): Plans artifact management
   - *"What cleanup steps are needed?"*
   - *"How do we track deployments using this feature?"*

7. **CAS-001** (Code Architecture): Final code review before commit

**Example: Volume Root ADS Feature**

```
Queue: "I want to implement volume root ADS (C::stream) for maximum stealth"

RTO-001: "Operational value is high for advanced evasion, but stability concerns limit 
          to Tier 1 targets only. Recommend as opt-in feature, not default."

WIS-001: "Technically feasible with C::streamname:$DATA syntax. CRITICAL: Unstable on 
          some Windows versions, may cause filesystem corruption. Requires extensive 
          testing in disposable VMs. Syntax validated in PS 5.1 and 7.x."

CAS-001: "Add -StorageBackend parameter with values 'classic', 'volume-root'. Default 
          to 'classic' for safety. Implement as separate code path in Get-RandomADSConfig 
          with additional warnings. Update documentation prominently."

DEA-001: "Volume root ADS less commonly enumerated than file-based ADS. Sysmon Event 15 
          still logs them. Detection likelihood: Low-Medium. Worth implementing for 
          advanced scenarios."

OSA-001: "Cleanup more complex - can't delete volume, only remove stream. Manifests 
          CRITICAL for tracking. Include volume root streams in Detect-ZeroWidthADS.ps1 
          enumeration."

Queue: [Implements feature with all guidance incorporated, tests thoroughly]

CAS-001: [Reviews implementation]
         "Code quality good. Warnings present. Backward compatible. Test coverage needed.
          Approve for commit after adding volume root test scenario."
```

### Pattern 2: Debugging Failed Deployment

**Scenario:** ADS deployment failing in Windows VM

**Agent Collaboration:**

1. **Queue**: Reports symptoms
   - *"Deployment script runs but scheduled task doesn't execute"*

2. **WIS-001** (Windows Internals): Diagnoses root cause
   - *"Check task scheduler operational logs for Event ID 103/104"*
   - *"Verify JScript wrapper file exists at expected path"*
   - *"Test wscript.exe execution manually"*

3. **RTO-001** (Red Team Ops): Suggests workaround if fix is time-consuming
   - *"If task scheduler is blocked, fall back to registry run key persistence"*

4. **CAS-001** (Code Architecture): Identifies code location for fix
   - *"Bug likely in task registration section around line 450"*
   - *"Check parameter escaping in -Argument value"*

5. **Queue**: Implements fix with WIS-001 technical guidance

6. **OSA-001** (OPSEC Specialist): Reviews if fix creates new artifacts
   - *"Additional event log entries? New forensic visibility?"*

**Example: RepetitionDuration Bug**

```
Queue: "Tasks register successfully but only execute once, not every 5 minutes"

WIS-001: "This is Windows Server 2019+ behavior. -RepetitionInterval requires explicit 
          -RepetitionDuration or task stops after first execution. Not a bug, but 
          undocumented Windows change."

CAS-001: "Surgical fix: Add -RepetitionDuration (New-TimeSpan -Days 9999) parameter 
          to trigger creation. Line 387 in ADS-Dropper.ps1. Don't rewrite entire 
          task logic, just add one line."

Queue: [Applies fix exactly as specified]

WIS-001: "Verified. Works on Server 2016, 2019, 2022. No regression."

OSA-001: "No new artifacts. Cleanup commands unchanged."

CAS-001: "Clean implementation. Backward compatible. Approve."
```

### Pattern 3: Payload Development

**Scenario:** Creating new payload for library

**Agent Collaboration:**

1. **PEA-001** (Payload Engineering): Leads development
   - *"Implement payload following library structure"*
   - *"Test compatibility across Windows versions"*

2. **WIS-001** (Windows Internals): Validates PowerShell syntax
   - *"Payload works in PS 5.1? As SYSTEM context?"*

3. **DEA-001** (Detection Engineering): Assesses detectability
   - *"What signatures does this create?"*
   - *"How do common EDR tools react?"*

4. **RTO-001** (Red Team Ops): Evaluates operational utility
   - *"When would this payload be used in competition?"*
   - *"Prioritize adding this vs. other payloads?"*

5. **OSA-001** (OPSEC Specialist): Plans cleanup requirements
   - *"What artifacts remain after payload execution?"*

6. **CAS-001** (Code Architecture): Reviews integration with ADS deployment
   - *"Does payload structure fit ADS deployment mechanism?"*

**Example: EDR Bypass Payload**

```
PEA-001: "Developing EVASION-007: Disable common EDR telemetry via registry"

[Implements payload]

WIS-001: "Syntax valid. Requires SYSTEM privileges. Works PS 5.1 and 7. Registry 
          paths confirmed on Server 2019/2022."

DEA-001: "Registry changes logged in Event 4657 (Registry Value Modification). 
          Highly suspicious activity. Blue team likely monitors these keys. 
          Detection likelihood: HIGH. Recommend using only when EDR already evaded 
          by other means."

RTO-001: "Operational value MEDIUM. Useful for advanced scenarios but high detection 
          risk limits utility. Add to library as advanced payload with warnings."

OSA-001: "Artifacts: Registry changes persist until reverted. Include revert commands 
          in payload notes. Cleanup requires restoring original values (capture first)."

CAS-001: "Integration straightforward. Add to EVASION category. Document prerequisites 
          (SYSTEM context, high detection risk). Include usage notes."

PEA-001: [Adds to ccdc-library.ps1 with all feedback incorporated]
```

### Pattern 4: Documentation Update

**Scenario:** Updating documentation after feature additions

**Agent Collaboration:**

1. **CAS-001** (Code Architecture): Identifies documentation gaps
   - *"New parameters not documented in README"*
   - *"USAGE-GUIDE.md needs examples for new feature"*

2. **RTO-001** (Red Team Ops): Provides operational context for docs
   - *"Explain when to use feature vs. when to skip"*

3. **WIS-001** (Windows Internals): Adds technical details
   - *"Document Windows version compatibility"*
   - *"Explain technical limitations"*

4. **PEA-001** (Payload Engineering): Updates payload library docs if relevant

5. **Queue**: Writes documentation with agent input

6. **CAS-001** (Code Architecture): Reviews for completeness and accuracy

---

## Agent Interaction Protocols

### When Queue Should Invoke Specific Agents

**Invoke RTO-001 (Red Team Ops) for:**
- Prioritizing features or bug fixes
- Deciding deployment strategy for competition
- Selecting payloads for specific scenarios
- Evaluating operational tempo vs. stealth trade-offs

**Invoke WIS-001 (Windows Internals) for:**
- Debugging PowerShell syntax errors
- Understanding Windows-specific behaviors
- Implementing OS-level features (ADS, tasks, registry)
- Validating compatibility across Windows versions

**Invoke DEA-001 (Detection Engineering) for:**
- Assessing detectability of techniques
- Understanding blue team perspective
- Improving evasion capabilities
- Developing defensive tooling

**Invoke CAS-001 (Code Architecture) for:**
- Code review before commits
- Architectural decisions
- Refactoring guidance
- Ensuring backward compatibility

**Invoke OSA-001 (OPSEC Specialist) for:**
- Cleanup operation planning
- Artifact management
- Anti-forensics techniques
- Manifest system improvements

**Invoke PEA-001 (Payload Engineering) for:**
- Adding payloads to library
- Payload selection advice
- Compatibility testing
- Obfuscation techniques

### Cross-Agent Consultations

Agents should consult each other when expertise overlaps:

**WIS-001 → DEA-001:** "This Windows behavior creates X telemetry. How detectable?"
**DEA-001 → OSA-001:** "This telemetry can't be avoided. How do we clean it up?"
**PEA-001 → WIS-001:** "Does this payload syntax work in PS 5.1?"
**RTO-001 → All:** "What's the fastest way to achieve X objective?"
**CAS-001 → All:** "This refactoring affects everyone. Validate approach?"

---

## Communication Standards

### Agent Response Format

When agents provide guidance, follow this structure:

**1. Direct Answer** (if question has clear answer)
**2. Context/Reasoning** (why this answer)
**3. Alternatives** (if applicable)
**4. Warnings/Caveats** (risks or limitations)
**5. Next Steps** (what Queue should do)

**Example:**

```
Queue: "Should I add timestamp manipulation to ADS deployment?"

OSA-001: 
Direct Answer: Not as default feature, but offer as opt-in parameter.

Context: Timestamp manipulation helps blend new files with existing ones, reducing
timeline analysis detectability. However, advanced forensics compare $STANDARD_INFORMATION
vs $FILE_NAME attributes in MFT, revealing manipulation.

Alternatives: 
- Option 1: Add -TimestompToMatch parameter with path to reference file
- Option 2: Add -TimestompToDate parameter with specific date
- Option 3: Skip timestamp manipulation, rely on deep placement instead

Warnings: Timestomping is itself suspicious to sophisticated analysts. USN journal
still records actual modification times. Only effective against basic timeline analysis.

Next Steps:
1. Implement as opt-in feature (don't change default behavior)
2. Add to OPSEC section of documentation with appropriate warnings
3. Test in VM to verify it works as expected
4. Consider adding to advanced deployment scenarios only
```

### Conflict Resolution

When agents disagree:

1. **Acknowledge Disagreement:** State different perspectives clearly
2. **Present Trade-offs:** Explain what each approach optimizes for
3. **Defer to Queue:** Let Queue make final decision with full information

**Example:**

```
Queue: "Should multi-instance deployment be the default?"

RTO-001: "YES. Redundancy is critical in competition. Blue team will kill beacons.
          Multi-instance should be default with -InstanceCount 3."

CAS-001: "NO. Breaking change affects existing workflows. Defaults should be conservative.
          Multi-instance should be opt-in to maintain backward compatibility."

Resolution:
Both agents have valid points. Trade-off is operational effectiveness vs stability.

Recommendation: Keep default -InstanceCount 1 (backward compatible), but document
multi-instance prominently in quickstart guide. Update competition-focused docs
to recommend -InstanceCount 3-5 for critical targets.

Queue: [Decides based on full context]
```

---

## Session Management

### Starting a Development Session

**Initialization Checklist:**

1. Start Claude Code in terminal (full feature access)
2. Navigate to ADS project directory
3. Read /docs/project-context/current-state.md
4. Load all six agent skills
5. Review recent commits (git log)
6. Check open issues or TODOs

**Session Startup Template:**

```
Queue: "Starting development session. Load project context."

[Claude Code reads current-state.md, recent-changes.md, active-bugs.md]

Queue: "I want to work on implementing volume root ADS support today."

RTO-001: [Provides operational context and priority assessment]
WIS-001: [Provides technical feasibility analysis]
CAS-001: [Suggests architectural approach]
[Other agents provide relevant input as needed]

Queue: [Proceeds with development with full agent team support]
```

### Ending a Development Session

**Shutdown Checklist:**

1. Commit all working changes
2. Update /docs/project-context/current-state.md with progress
3. Log any blocking issues in active-bugs.md
4. Update recent-changes.md with commits
5. Note next steps for future session

---

## Special Workflows

### Emergency Debugging (Mid-Competition)

When time is critical:

1. **RTO-001** takes lead: "What's the minimum fix to get operational?"
2. **WIS-001** provides rapid diagnosis
3. **Queue** implements minimal fix
4. **Testing**: Verify fix works, accept imperfect solution if time-constrained
5. **Post-Event**: Full root cause analysis and proper fix

### Research and Exploration

When researching new techniques:

1. **WIS-001 or DEA-001** leads research
2. Document findings in /docs/research/
3. Implement proof-of-concept
4. Test thoroughly in VMs
5. **RTO-001** evaluates operational utility
6. **CAS-001** plans integration if valuable
7. Add to roadmap or implement

### Code Review Before Release

Before major version releases:

1. **CAS-001** performs full code review
2. **WIS-001** validates PowerShell compatibility
3. **DEA-001** reviews detection surface
4. **OSA-001** validates cleanup procedures
5. **PEA-001** verifies payload library integrity
6. **RTO-001** confirms operational readiness
7. Update all documentation
8. Tag release in git

---

## Success Metrics

Track agent effectiveness:

**Qualitative:**
- Code quality improvements over time
- Reduced debugging time with agent help
- Faster feature development
- Better documentation completeness

**Quantitative:**
- Time from feature idea to implementation
- Number of bugs caught before commit
- Test scenario pass rate
- Documentation coverage percentage

---

**End of Orchestration Guide**
