---
name: llm-eval
description: "LLM output evaluation pipeline: audit evals, failure analysis, synthetic data, LLM-as-Judge, RAG eval, annotation design. Triggers on: llm eval, evaluate ai, eval pipeline, judge calibration, rag eval, ai quality, /llm-eval."
argument-hint: "<feature/endpoint to evaluate, or 'audit' to review existing evals>"
user-invocable: true
context: fork
model: opus
effort: high
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: true }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: true
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
---

# LLM Eval — AI Output Quality Pipeline

Structured evaluation framework for LLM-powered features. Based on Hamel Husain's eval methodology: start with failure analysis, build judges that correlate with human judgment, then automate.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    /llm-eval ORCHESTRATOR                     │
│                                                               │
│  Mode 1          Mode 2          Mode 3         Mode 4       │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐ │
│  │  AUDIT   │   │ BUILD    │   │   RAG    │   │  FULL    │ │
│  │ existing │   │ eval     │   │  EVAL    │   │ PIPELINE │ │
│  │  evals   │   │ pipeline │   │          │   │          │ │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘ │
│                       │                              │       │
│                       ▼                              ▼       │
│              ┌─────────────────────────────────────────┐     │
│              │ Phases: Failure Analysis → Synthetic     │     │
│              │ Data → Judge Design → Calibration →     │     │
│              │ Automation                               │     │
│              └─────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## Mode Selection

On invocation, detect the mode:

| Input                          | Mode           | What happens                               |
| ------------------------------ | -------------- | ------------------------------------------ |
| `audit` or `review evals`      | Audit          | Analyze existing eval setup, find gaps     |
| `eval <feature>`               | Build Pipeline | Full 5-phase eval pipeline for a feature   |
| `rag eval` or `eval retrieval` | RAG Eval       | Specialized RAG evaluation                 |
| `full pipeline` or no args     | Full           | Audit + Build for all AI features detected |

---

## Phase 1: Failure Analysis & Error Taxonomy

**Goal:** Understand how the LLM feature fails before trying to measure it.

### Process

1. **Identify AI features** in the codebase:

   ```
   Grep for: OpenAI/Anthropic SDK imports, prompt templates, completion calls,
   embedding calls, chat.completions, messages.create, generateText, streamText
   ```

2. **Collect real outputs** (if available):
   - Check for logged LLM responses in DB, log files, or test fixtures
   - If no real outputs exist, generate 20-30 synthetic inputs from the product spec

3. **Build error taxonomy:**

   ```markdown
   ## Error Taxonomy: {Feature Name}

   | Error Type        | Description                          | Severity | Frequency | Example                                                |
   | ----------------- | ------------------------------------ | -------- | --------- | ------------------------------------------------------ |
   | Hallucination     | States facts not in context          | Critical | ~15%      | "Your balance is $5,000" when no balance data provided |
   | Format violation  | Output doesn't match expected schema | High     | ~8%       | JSON with missing required fields                      |
   | Tone mismatch     | Too casual/formal for context        | Medium   | ~5%       | Using slang in financial report                        |
   | Incomplete        | Misses required information          | High     | ~10%      | Skips tax calculation step                             |
   | Instruction drift | Ignores system prompt constraints    | Critical | ~3%       | Answers questions outside scope                        |
   ```

4. **Prioritize** by: `severity * frequency`. Focus eval effort on top 3-5 error types.

---

## Phase 2: Synthetic Test Data Generation

**Goal:** Create a diverse test set that covers the error taxonomy.

### Process

1. **Define test dimensions:**
   - Happy path (expected inputs, expected outputs)
   - Edge cases (empty input, very long input, unicode, special chars)
   - Adversarial (prompt injection attempts, off-topic requests)
   - Error-type specific (inputs designed to trigger each error from Phase 1)

2. **Generate test cases:**
   - For each dimension, create 10-20 input/expected-output pairs
   - Include "golden" examples: 5-10 hand-verified perfect input/output pairs
   - Tag each test case with the error types it's designed to detect

3. **Output format:**

   ```json
   {
     "testCases": [
       {
         "id": "tc-001",
         "input": "...",
         "expectedOutput": "...",
         "tags": ["happy-path", "format-compliance"],
         "errorTypesTargeted": ["format-violation"],
         "difficulty": "easy"
       }
     ],
     "goldenSet": [
       {
         "id": "gold-001",
         "input": "...",
         "expectedOutput": "...",
         "humanVerified": true,
         "verifiedBy": "manual review"
       }
     ]
   }
   ```

4. **Write to:** `.claude/eval/{feature-slug}/test-data.json`

---

## Phase 3: LLM-as-Judge Design

**Goal:** Write judge prompts that reliably score LLM outputs.

### Methodology

Do NOT use generic "rate from 1-5" judges. They correlate poorly with human judgment. Instead:

1. **One judge per error type.** Each judge checks for exactly one failure mode.

2. **Binary judges first.** Start with pass/fail, not scores. Binary judges are easier to calibrate.

3. **Judge prompt structure:**

   ```
   You are evaluating whether an AI assistant's response contains {error_type}.

   ## Context
   The assistant was given this input:
   {input}

   The assistant's system prompt instructs it to:
   {system_prompt_summary}

   ## Response to Evaluate
   {response}

   ## Evaluation Criteria
   {specific_criteria_for_this_error_type}

   ## Examples
   PASS example: {example_of_correct_output}
   FAIL example: {example_of_output_with_this_error}

   ## Your Verdict
   Respond with exactly one of:
   - PASS: The response does not contain {error_type}
   - FAIL: The response contains {error_type}

   Then explain your reasoning in 1-2 sentences.
   ```

4. **Write judges for top 3-5 error types** from Phase 1.

5. **Output:** `.claude/eval/{feature-slug}/judges/` directory with one file per judge.

### Judge Prerequisites (strict ordering)

1. Completed error analysis (Phase 1) identifying the specific failure mode
2. At least 20 Pass + 20 Fail human-labeled examples
3. Confirmation that code-based checks cannot address this criterion — **always try code first** (regex, schema validation, format checks) before resorting to LLM judges

### Code-First Checks (before LLM judges)

| Criterion                   | Code Check                         | LLM Judge Needed? |
| --------------------------- | ---------------------------------- | ----------------- |
| JSON format valid           | `JSON.parse()` / schema validation | No                |
| Response length             | Character/token count              | No                |
| Contains required fields    | Key existence check                | No                |
| Language detection          | `franc` / regex                    | No                |
| Tone appropriateness        | --                                 | Yes               |
| Factual accuracy vs context | --                                 | Yes               |
| Instruction adherence       | --                                 | Yes               |

### Anti-patterns to avoid

- "Rate the overall quality from 1-10" — too vague, low inter-rater reliability
- Single judge for multiple criteria — conflates different failure modes
- No examples in the judge prompt — judges without examples are 30-40% less accurate
- Verbose criteria — keep each judge focused on ONE thing
- ROUGE, BERTScore, cosine similarity as primary metrics — they measure surface overlap, not quality
- Building judges before fixing obvious problems found in Phase 1

---

## Phase 4: Judge Calibration

**Goal:** Verify that LLM judges agree with human judgment.

### Process

1. **Take the golden set** from Phase 2 (human-verified examples)

2. **Run each judge** against the golden set:

   ```
   For each golden example:
     For each judge:
       Run judge(input, response) → PASS/FAIL
       Compare against human label
       Record agreement/disagreement
   ```

3. **Calculate metrics:**

   ```markdown
   ## Judge Calibration Report

   | Judge               | Accuracy | Precision | Recall | F1   | Cohen's Kappa |
   | ------------------- | -------- | --------- | ------ | ---- | ------------- |
   | hallucination-judge | 92%      | 89%       | 95%    | 0.92 | 0.84          |
   | format-judge        | 97%      | 96%       | 98%    | 0.97 | 0.94          |
   ```

4. **Acceptance threshold:** TPR > 90% AND TNR > 90%. Minimum acceptable: 80%/80%.

   Use TPR/TNR over precision/recall or raw accuracy — especially important with class imbalance.

5. **If a judge fails calibration:**
   - Inspect every disagreement — false passes and false fails have different fixes
   - False Pass: strengthen failure definitions or add edge cases to prompt
   - False Fail: clarify pass criteria or adjust examples
   - Try upgrading the model (haiku → sonnet for that judge)
   - Decompose criterion into sub-criteria if stalled
   - Re-calibrate (iterate on dev set only)

6. **Bias correction for production deployment:**

   When deploying judges to score production traffic, apply the Rogan-Gladen formula:

   ```
   true_rate = (observed_pass_rate + TNR - 1) / (TPR + TNR - 1)
   ```

   This corrects for systematic judge bias. Bootstrap 95% CI with 2,000 resamples.

7. **Pin exact model versions.** Use `claude-sonnet-4-20250514` not `sonnet`. Judge behavior changes with model updates — re-validate after any model change.

8. **Output:** `.claude/eval/{feature-slug}/calibration-report.md`

---

## Phase 5: RAG Evaluation (when applicable)

**Goal:** Evaluate retrieval quality separately from generation quality.

Only runs when the feature uses RAG (retrieval-augmented generation). Detect by grepping for: embedding calls, vector DB queries (Pinecone, Weaviate, pgvector, Supabase vector), similarity search, chunk retrieval.

### Retrieval Metrics

| Metric                | What it measures                            | How to compute                                                         |
| --------------------- | ------------------------------------------- | ---------------------------------------------------------------------- |
| **Recall@k**          | Are the right documents retrieved?          | % of relevant docs in top-k results                                    |
| **Precision@k**       | Are retrieved docs actually relevant?       | % of top-k results that are relevant                                   |
| **MRR**               | Is the best doc ranked first?               | 1/rank of first relevant result                                        |
| **Context relevance** | Does retrieved context answer the question? | LLM judge: "Does this context contain info needed to answer: {query}?" |

### Generation Metrics (given correct retrieval)

| Metric                  | What it measures                                               |
| ----------------------- | -------------------------------------------------------------- |
| **Faithfulness**        | Does the answer stick to retrieved context? (no hallucination) |
| **Answer relevance**    | Does the answer actually address the question?                 |
| **Context utilization** | Does the answer use all relevant retrieved info?               |

### Process

1. Build a test set of queries with known-relevant documents
2. Run retrieval, measure Recall@k and Precision@k
3. For each retrieved context + query, run generation
4. Apply faithfulness judge and relevance judge
5. Report separately: retrieval quality vs generation quality

---

## Phase 6: Automation & CI Integration

**Goal:** Make evals run automatically.

### Process

1. **Create eval runner script:** `.claude/eval/{feature-slug}/run-eval.ts`

   ```typescript
   // Pseudo-structure
   import { testCases } from "./test-data.json";
   import { judges } from "./judges/";

   async function runEval() {
     const results = [];
     for (const tc of testCases) {
       const response = await callFeature(tc.input);
       const judgments = await Promise.all(
         judges.map((j) => j.evaluate(tc.input, response)),
       );
       results.push({ tc, response, judgments });
     }
     return generateReport(results);
   }
   ```

2. **Integration options:**
   - Add to `package.json` scripts: `"eval": "tsx .claude/eval/run-eval.ts"`
   - Add to CI: run evals on PRs that touch AI-related files
   - Add to `/ship` Phase 5: run evals alongside QA for AI features

3. **Regression detection:** Compare current eval scores against baseline. Flag if any judge's pass rate drops by >5%.

---

## Output Structure

```
.claude/eval/{feature-slug}/
├── error-taxonomy.md          # Phase 1
├── test-data.json             # Phase 2
├── judges/                    # Phase 3
│   ├── hallucination.md
│   ├── format-compliance.md
│   └── tone-match.md
├── calibration-report.md      # Phase 4
├── rag-eval-report.md         # Phase 5 (if RAG)
├── run-eval.ts                # Phase 6
└── eval-report.md             # Final summary
```

---

## Audit Mode

When run with `audit`, skip pipeline creation and instead:

1. Find all AI features in the codebase
2. Check for existing eval infrastructure (test files, judges, metrics)
3. Report gaps:

```markdown
## Eval Audit: {Project Name}

| AI Feature       | Has Test Data  | Has Judges      | Has Calibration | Has CI | Gap                       |
| ---------------- | -------------- | --------------- | --------------- | ------ | ------------------------- |
| Chat completion  | No             | No              | No              | No     | Full pipeline needed      |
| RAG search       | Yes (20 cases) | Yes (2/5 types) | No              | No     | Calibration + more judges |
| Email generation | Yes            | Yes             | Yes             | No     | CI integration only       |
```

---

## Model Routing

| Phase                      | Model  | Rationale                                            |
| -------------------------- | ------ | ---------------------------------------------------- |
| Phase 1 (failure analysis) | sonnet | Needs judgment to classify errors                    |
| Phase 2 (synthetic data)   | sonnet | Creative + structured output                         |
| Phase 3 (judge design)     | opus   | Critical — judge quality determines pipeline quality |
| Phase 4 (calibration)      | haiku  | Mechanical — run judges, compute metrics             |
| Phase 5 (RAG eval)         | sonnet | Needs understanding of retrieval relevance           |
| Phase 6 (automation)       | sonnet | Code generation, bounded scope                       |

---

## Usage

```bash
# Audit existing evals
/llm-eval audit

# Build eval pipeline for a specific feature
/llm-eval "chat completion endpoint in src/api/chat"

# RAG-specific evaluation
/llm-eval rag eval

# Full pipeline for all AI features
/llm-eval full pipeline
```

---

## Version

**v1.0.0** — Initial release. 6-phase eval pipeline based on Hamel Husain methodology: failure analysis, synthetic data, LLM-as-Judge, calibration, RAG eval, automation.
