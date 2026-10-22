---
description: Council debate — 4 agents argue an idea in 2 rounds, the judge issues a verdict and plan
argument-hint: <idea or question>
---

Run a council debate on: $ARGUMENTS

You are the orchestrator. Subagents cannot call each other, so you run every step.

1. **Context.** Briefly gather project context (README, top-level structure, CLAUDE.md, recent git log). If `.council/decisions/` exists, list it and read decisions related to this idea. Write a 10-15 line context brief.

2. **Round 1 — independent positions.** In ONE message, launch these 4 subagents in parallel: `council-visionary`, `council-skeptic`, `council-pragmatist`, `council-user-advocate`. Give each: the idea, the context brief, related past decisions. Tell them this is round 1 and they must not assume what others think.

3. **Round 2 — rebuttals.** In ONE message, launch the same 4 again in parallel. Give each: the idea, its own round-1 position, and the other three positions in full. Ask them to rebut, concede, or update — and end with their final block.

4. **Verdict.** Launch `council-judge` with: the idea, context brief, past decisions, all round-1 and round-2 outputs.

5. **Record.** Save to `.council/decisions/YYYY-MM-DD-<short-slug>.md`: idea, context brief, round 1, round 2, verdict. Create the folder if missing.

6. **Report to the owner in Russian**: verdict, 3-5 line reasoning, who was for/against with final confidence, the plan table, open questions. Keep it short; the full transcript is in the file.

Hard limits: exactly 2 rounds; do not write or change project code in this command.
