---
description: Office executes a task — dispatches to programmer, designer, etc., then QA and security always check
argument-hint: <task, or path to a council decision file>
---

Execute with the office: $ARGUMENTS

You are the orchestrator (team lead). Subagents cannot call each other, so you dispatch every step.

1. **Understand.** If the argument is a `.council/decisions/*.md` file, use its Plan table. Otherwise break the task into steps yourself and assign each to an office role: `office-programmer`, `office-designer`, `office-security`, `office-finance`, `office-qa`, `office-devops`, `office-docs`, `office-marketing`. Use only the roles the task needs.

2. **Branch.** If the project is a git repo and you are on main/master, create a branch `ai/<short-slug>` before any change. Never commit to main/master.

3. **Dispatch.** Launch independent steps in parallel (one message, several subagents); dependent steps in order. Give each subagent: the exact task, relevant files, constraints, and "done when" criteria. Don't paste whole files — point to paths.

4. **Check — always, if any code changed:**
   - `office-qa` on the changed area.
   - `office-security` on the diff.
   - If QA fails or security says FIX BEFORE MERGE → send findings back to `office-programmer`, then re-run the failed check. Max 2 fix loops; if still failing, stop and report.

5. **Docs.** If behavior changed for users or developers, `office-docs` updates README/CHANGELOG/CLAUDE.md.

6. **Commit** on the branch with a clear message.

7. **Report to the owner in Russian**: what was done, branch name, changed files, QA and security verdicts, anything left for him to decide. Short.
