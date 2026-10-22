---
description: Full cycle — council debate, then office executes the approved plan, then the skeptic reviews the result
argument-hint: <idea>
---

Full cycle for: $ARGUMENTS

1. Run the complete procedure from `~/.claude/commands/court.md` on this idea (both rounds, judge, decision file).

2. If the verdict is **REJECTED**: stop. Report to the owner in Russian: verdict, why, and what alternative (if any) the council suggested.

3. If **APPROVED** or **APPROVED WITH CHANGES**: run the complete procedure from `~/.claude/commands/office.md`, passing the decision file as the argument. Follow the judge's plan, conditions and out-of-scope list strictly.

4. **Final review.** Launch `council-skeptic` once more with: the decision file and the resulting diff (`git diff main...HEAD` or equivalent). Ask: did the office deliver what was approved, did it overreach, what's the remaining risk? Append its review to the decision file under `## Post-implementation review` and commit.

5. **Report to the owner in Russian**: verdict, what was built, branch, QA/security verdicts, skeptic's final note. Short.
