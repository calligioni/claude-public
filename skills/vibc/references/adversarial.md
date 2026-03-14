# Adversarial Pairing Protocol

## When to Trigger

Run adversarial pairing when:

1. Two or more seats directly contradict each other on the same point
2. The contradiction has material impact on the final recommendation
3. Neither position is trivially correct

Maximum 3 pairs per decision (cost constraint).

## Steelman Rules

Each side MUST:

1. State the opposing position in the STRONGEST possible terms
2. Identify the BEST evidence supporting the opposing position
3. Name the CONDITIONS under which the opposing position would be correct
4. Only THEN present their own rebuttal

If a debater cannot steelman the opposition (presents a straw man), the moderator discards that round and notes the failure.

## Pairing Selection Priority

When the collision map reveals more than 3 contradictions, prioritize by:

1. **Impact on final decision:** Does resolving this contradiction change the recommended option?
2. **Seat distance:** Contradictions between epistemically distant seats (e.g., Veteran vs. Jazz Musician) are more valuable than those between nearby seats (e.g., Rabbi vs. Pastor)
3. **Novelty:** Contradictions that reveal hidden assumptions are more valuable than disagreements about known trade-offs

## Output Format

Each pair produces:

- **Steelman A:** Side A's best version of B's argument
- **Steelman B:** Side B's best version of A's argument
- **Steelman quality:** Did each side genuinely engage with the opposition, or straw-man?
- **Resolution:** One of:
  - `synthesis` — both are true; the real answer integrates them
  - `conditional` — "A is right if X, B is right if Y" (becomes a testable hypothesis)
  - `trade-off` — genuine tension; choice depends on values, not facts
  - `clear_winner` — one side's argument is materially stronger
- **Key insight:** The one thing discovered through this exchange that neither side articulated alone

## Spawn Prompt Template

For each adversarial pair, spawn two sequential Task subagents:

**Agent A (Seat X defending, steelmanning Seat Y):**

```
You are {Seat X archetype}. In a board deliberation, you hold this position:
{Seat X position}

Another board member ({Seat Y archetype}) holds this opposing position:
{Seat Y position}

FIRST: Present the STRONGEST possible version of their argument. What are they right about? Under what conditions would their position be correct?

THEN: Present your rebuttal. Why is your position ultimately stronger?

Respond as JSON: { "steelman_of_opponent": "...", "conditions_opponent_is_right": ["..."], "rebuttal": "...", "confidence_after_exchange": 1-10 }
```

**Agent B (Seat Y defending, steelmanning Seat X):**
Same template, reversed.
