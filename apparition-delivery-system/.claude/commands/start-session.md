---
description: Initialize a development session by loading project context, recent changes, and active bugs
---

Start a development session for the Apparition Delivery System. Do the following in sequence:

1. Read `docs/project-context/current-state.md` to understand where the project is
2. Run `git log --oneline -15` to see recent commits
3. Read `docs/project-context/active-bugs.md` for known issues
4. Read `coordination/SESSION-HANDOFF.md` for context from the last session
5. Read `coordination/AGENT-STATUS.md` for any pending agent work
6. Read `coordination/DECISION-LOG.md` — scan last 5 entries to avoid re-litigating settled decisions
7. Read `docs/research/defender-behavioral-detections.md` — identify any OPEN items that are the session's focus
8. If the session focus involves AV evasion, have `av-evasion-researcher` run a 2-minute intelligence refresh:
   - WebSearch for any recent updates to the specific detection family flagged in defender-behavioral-detections.md
   - Report if anything new found before starting work

Summarize the project state concisely: version, what was done last session, what's OPEN in defender-behavioral-detections.md, what's blocked, and recommended next steps. Then ask Queue what they want to work on today.
