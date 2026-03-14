# VIBC Scoring Framework

## Dimensions & Seat Weights

| Dimension          | Default Weight | Primary Seats (2x weight)           | Secondary Seats (1x) |
| ------------------ | -------------- | ----------------------------------- | -------------------- |
| **Risk**           | 20%            | Veteran (1), Intel Analyst (9)      | ER Physician (7)     |
| **Ethics**         | 15%            | Rabbi (3), Pastor (4)               | Social Worker (2)    |
| **Feasibility**    | 20%            | Farmer (6), Immigrant Owner (10)    | ER Physician (7)     |
| **Creativity**     | 10%            | Jazz Musician (8), Comedian (12)    | Immigrant Owner (10) |
| **Sustainability** | 20%            | Farmer (6), Hospice Nurse (11)      | Social Worker (2)    |
| **Clarity**        | 15%            | Trial Lawyer (5), Intel Analyst (9) | Comedian (12)        |

## Weight Adjustment by Decision Type

| Decision Type       | Risk | Ethics | Feasibility | Creativity | Sustainability | Clarity |
| ------------------- | ---- | ------ | ----------- | ---------- | -------------- | ------- |
| crisis              | 30%  | 10%    | 25%         | 5%         | 10%            | 20%     |
| ethical             | 10%  | 30%    | 15%         | 10%        | 25%            | 10%     |
| resource-allocation | 15%  | 10%    | 30%         | 10%        | 20%            | 15%     |
| strategy            | 15%  | 10%    | 20%         | 15%        | 25%            | 15%     |
| binary              | 20%  | 15%    | 20%         | 10%        | 15%            | 20%     |
| general             | 20%  | 15%    | 20%         | 10%        | 20%            | 15%     |

## Scoring Algorithm

For each option O and dimension D:

1. Collect all board inputs relevant to D (from primary and secondary seats for that dimension)
2. Extract the seat's position, concerns, and conditions that relate to dimension D
3. Primary seat scores count 2x, secondary count 1x
4. Score each dimension 1-10 based on how well the option addresses the concerns raised by the relevant seats
5. Multiply by dimension weight (adjusted for decision type)
6. Sum across all 6 dimensions for weighted total (max 10.00)

## Anti-Corruption Checks

- **UNANIMITY WARNING:** If ALL seats score an option > 7 — flag as potential groupthink. Display: "When everyone agrees, someone isn't thinking."
- **KILL CONDITION FLAG:** If ANY dimension scores < 3 — this option has a critical weakness that must be addressed or the option should be eliminated
- **GROUPTHINK WARNING:** If standard deviation across all seat positions < 1.5 — the board is not producing genuinely diverse perspectives. Consider reframing the decision or checking persona prompt quality
- **MANDATORY DISSENT:** If no seat has dissent_strength >= 5, the orchestrator must construct a counter-argument to the leading option and present it to the user
