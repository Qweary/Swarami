---
description: Run a full pre-commit review using code-architect and test-validator agents before committing changes
---

Run a pre-commit review on the current changes. Do the following:

1. Run `git diff --cached` (or `git diff` if nothing staged) to see all changes
2. Use the `code-architect` agent to review the changes against the code review checklist: backward compatibility, parameter design, error handling, PS 5.1/7.x compatibility, safety warnings preserved, no code duplication
3. Use the `test-validator` agent to identify which test scenarios are affected by these changes and generate specific test commands
4. Use the `detection-engineering` agent if the changes affect deployment behavior, to assess any new detection surface
5. Use the `opsec-specialist` agent if the changes affect artifact creation or cleanup

Present findings organized as: critical issues (must fix before commit), warnings (should fix), suggestions (consider for future), and the test scenarios Queue should run in their VM before pushing.
