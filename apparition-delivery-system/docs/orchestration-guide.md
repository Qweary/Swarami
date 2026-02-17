# Multi-Agent Orchestration Guide

Version: 2.0 — February 11, 2026
Purpose: Coordinate eight specialized Claude Code subagents for ADS development

## Agent Roster

RTO-001 `red-team-ops` — Competition tactics, deployment strategy, target prioritization
WIS-001 `windows-internals` — OS behavior, PowerShell, NTFS, Task Scheduler, AMSI
DEA-001 `detection-engineering` — Blue team perspective, telemetry, forensic artifacts
CAS-001 `code-architect` — Code quality, refactoring, backward compatibility
OSA-001 `opsec-specialist` — Artifact management, anti-forensics, cleanup
PEA-001 `payload-engineer` — Library management, obfuscation, technique development
TVA-001 `test-validator` — Testing methodology, regression detection, VM validation (NEW)
RWA-001 `research-writer` — Blog posts, research documentation, technique write-ups (NEW)

## Workflow Patterns

### Feature Development

RTO-001 evaluates operational value and priority ("Does this improve speed, reliability, or stealth for CCDC? Is it worth the complexity?"). WIS-001 assesses technical feasibility ("Can this work in PS 5.1 and 7.x? What Windows quirks affect it?"). CAS-001 designs integration approach ("How does this fit existing architecture? What parameters are needed? Backward compatible?"). Queue implements with agent guidance. DEA-001 reviews detection surface ("What new telemetry does this create? How detectable?"). OSA-001 plans artifact management ("What cleanup steps needed? How to track deployments?"). TVA-001 generates test scenarios ("What test matrix covers this? What regressions could it cause?"). CAS-001 does final code review before commit.

### Bug Fix (Mid-Development)

WIS-001 provides root cause analysis explaining the underlying Windows behavior. CAS-001 suggests surgical fix with specific line numbers and minimal changes. Queue applies the fix. TVA-001 identifies affected test scenarios and generates validation commands. OSA-001 confirms no new artifacts or cleanup changes needed. CAS-001 approves after verifying backward compatibility.

### Emergency Debugging (Mid-Competition)

RTO-001 takes lead: "What's the minimum fix to get operational?" WIS-001 provides rapid diagnosis. Queue implements minimal fix. TVA-001 provides quick verification steps. Post-event: full root cause analysis and proper fix.

### Payload Development

PEA-001 leads implementation following library structure. WIS-001 validates PowerShell syntax and SYSTEM context compatibility. DEA-001 assesses detectability and blue team response likelihood. RTO-001 evaluates operational utility and prioritization. OSA-001 defines cleanup requirements. CAS-001 reviews integration with ADS deployment mechanism.

### Documentation & Blog

RWA-001 leads content creation using Queue's voice and the honest-representation principle. WIS-001 provides technical details and Windows version compatibility. DEA-001 contributes detection rules and blue team perspective. CAS-001 reviews for accuracy against current codebase. RTO-001 provides operational context for competition-focused content.

### Release Preparation

CAS-001 performs full code review. WIS-001 validates cross-version compatibility. DEA-001 reviews detection surface of new features. OSA-001 validates cleanup procedures. PEA-001 verifies payload library integrity. TVA-001 runs complete test matrix and generates release validation runbook. RTO-001 confirms operational readiness. RWA-001 updates changelog and user-facing documentation.

## Cross-Agent Consultation Patterns

WIS-001 → DEA-001: "This Windows behavior creates X telemetry. How detectable?"
DEA-001 → OSA-001: "This telemetry can't be avoided. How do we clean it up?"
PEA-001 → WIS-001: "Does this payload syntax work in PS 5.1 as SYSTEM?"
RTO-001 → All: "What's the fastest way to achieve X objective?"
CAS-001 → All: "This refactoring affects everyone. Validate approach?"
TVA-001 → CAS-001: "These test failures indicate a regression in [area]."

## Agent Response Format

Direct answer first (if clear answer exists). Context and reasoning (why this answer). Alternatives (if applicable). Warnings and caveats (risks or limitations). Next steps (what Queue should do).

### AV Evasion Research (Iterative Loop)

This workflow runs when any generated script triggers Windows Defender.

**Loop iteration:**
1. AVR-001 leads: identify detection family, fetch current intelligence via WebSearch
2. AVR-001 proposes minimum-change evasion variants (at least 3)
3. WIS-001 validates each variant is syntactically correct in PS 5.1 and 7.x
4. PEA-001 confirms no payload library impacts from the approach
5. TVA-001 generates Windows-compatible test procedure (use `/windows-test` command)
6. Queue executes test on Windows VM, reports back Defender events and PASS/FAIL
7. AVR-001 interprets results, updates `docs/research/defender-behavioral-detections.md`
8. If PASS: CAS-001 reviews change for surgical minimalism before commit
9. If FAIL: loop back to step 2 with new approach
10. Escalate to Queue if 3+ full loops complete without success — need fresh research direction

**Escalation signal:** If the same detection family fires on all 3 variants with minimal code differences, the behavioral engine is pattern-matching on execution context rather than code content — this is a harder class of evasion requiring fundamentally different approach. Document and escalate immediately.

### Deep Placement Failure (Silent Deployment Failure)

When deep placement selects a locked system file:
1. WIS-001 identifies root cause (which service holds the file exclusively)
2. OSA-001 updates the denylist in `deep-placement-denylist.md`
3. CAS-001 adds the file pattern to the candidate filter with `-ErrorAction SilentlyContinue` + post-write verification
4. TVA-001 generates test that specifically targets that directory to verify fallback works
5. Never print deployment success without verifying ADS stream actually exists

## Conflict Resolution

When agents disagree: state perspectives clearly, present tradeoffs (what each approach optimizes for), defer to Queue for final decision with full information. Example: RTO-001 wants multi-instance as default (redundancy), CAS-001 wants it opt-in (backward compatibility). Resolution: keep default at 1 (compatible), document multi-instance prominently, recommend 3-5 for critical targets.

## Session Management

Starting: read `docs/project-context/current-state.md`, check `git log --oneline -10`, review `docs/project-context/active-bugs.md`.
Ending: commit working changes, update current-state.md, log blocking issues in active-bugs.md, note next steps.
