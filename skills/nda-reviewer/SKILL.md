---
name: nda-reviewer
description: "Review, analyze, and annotate NDAs (Non-Disclosure Agreements) against a library of pre-approved signed NDAs. Use when the user uploads an NDA for review, asks to compare an NDA against approved templates, requests NDA clause analysis, or wants feedback on NDA terms. Triggers on phrases like 'review this NDA', 'check this NDA', 'analyze this agreement', 'NDA review', 'confidentiality agreement review', or when a PDF/DOCX containing NDA language is uploaded with a review request."
user-invocable: true
argument-hint: "[path to NDA file to review]"
context: fork
model: haiku
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Task
tool-annotations:
  Bash: { readOnlyHint: true, idempotentHint: true }
inject:
  - bash: ls "$HOME/code/nuvini-nda/references/" 2>/dev/null | head -20
  - bash: ls "$HOME/code/nuvini-nda/output/" 2>/dev/null | head -10
memory: user
---

# NDA Reviewer Skill

## Purpose

Analyze uploaded NDAs against a reference library of previously signed/approved NDAs. Produce a clear verdict: **APPROVED** (no issues), or **NEEDS REVISION** (with specific comments, suggested edits, and risk flags). Output a professional annotated Word document the user can share with legal or counterparties.

## Project Paths

```
PROJECT_DIR=/Users/ps/code/nuvini-nda
REFERENCES_DIR=/Users/ps/code/nuvini-nda/references
OUTPUT_DIR=/Users/ps/code/nuvini-nda/output
SCRIPTS_DIR=/Users/ps/code/nuvini-nda/scripts
```

All commands use the project's virtual environment via `uv run`.

## Workflow

### Step 1: Locate the NDA to Review

The user will provide a path to the NDA file (PDF, DOCX, or TXT). If they provide just a filename, check:

1. The current working directory
2. Their Downloads folder: `~/Downloads/`
3. Their Desktop: `~/Desktop/`

If the argument matches "add reference" or "add ref", the user wants to add an NDA to the reference library instead of reviewing one. See "Managing Reference NDAs" below.

### Step 2: Load Reference NDAs

Reference NDAs (pre-approved/signed) are stored in:

```
/Users/ps/code/nuvini-nda/references/
```

Extract text from ALL reference NDAs:

```bash
for f in /Users/ps/code/nuvini-nda/references/*; do
  echo "=== $(basename "$f") ==="
  uv run --project /Users/ps/code/nuvini-nda python3 /Users/ps/code/nuvini-nda/scripts/extract_text.py "$f"
  echo ""
done
```

If no references exist yet, inform the user:

> "No reference NDAs found in the library. Please provide your signed/approved NDAs so I can use them as a baseline. You can add them with: `/nda-reviewer add reference <path>`"

You can still perform a standalone review using general NDA best practices, but note in the output that no reference library was available for comparison.

### Step 3: Extract the NDA Under Review

```bash
uv run --project /Users/ps/code/nuvini-nda python3 /Users/ps/code/nuvini-nda/scripts/extract_text.py "<nda_file_path>"
```

### Step 4: Analyze Against Reference Library

Compare the uploaded NDA against ALL reference NDAs on these dimensions:

#### Critical Review Checklist

| Category                                   | What to Check                                                                                               | Risk Level     |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------- | -------------- |
| **Definition of Confidential Information** | Scope too broad or too narrow vs. references                                                                | HIGH           |
| **Exclusions**                             | Standard exclusions present (public domain, prior knowledge, independent development, compelled disclosure) | HIGH           |
| **Term & Duration**                        | Duration of obligations vs. reference norms                                                                 | MEDIUM         |
| **Permitted Disclosures**                  | Who can receive (employees, advisors, affiliates) - compare to references                                   | MEDIUM         |
| **Return/Destruction of Materials**        | Obligations at termination                                                                                  | MEDIUM         |
| **Remedies & Injunctive Relief**           | Unusual remedies, indemnification, liquidated damages                                                       | HIGH           |
| **Non-Solicitation / Non-Compete**         | Hidden restrictive covenants embedded in NDA                                                                | CRITICAL       |
| **Governing Law & Jurisdiction**           | Unfavorable jurisdiction vs. references                                                                     | MEDIUM         |
| **Assignment**                             | Can obligations be assigned without consent?                                                                | LOW            |
| **Mutual vs. Unilateral**                  | Is it one-sided when references are mutual?                                                                 | HIGH           |
| **Residuals Clause**                       | Right to use general knowledge/ideas retained in memory                                                     | MEDIUM         |
| **Standstill / MNPI**                      | Material non-public information restrictions                                                                | HIGH (for M&A) |
| **Non-Circumvention**                      | Restrictions on direct dealing                                                                              | MEDIUM         |
| **Carve-outs for Representatives**         | Are advisors/bankers/lawyers properly covered?                                                              | MEDIUM         |

#### Analysis Approach

For each clause in the NDA under review:

1. **Identify** the clause and its purpose
2. **Compare** against corresponding clauses in reference NDAs
3. **Flag** any deviations — noting whether they favor or disfavor the user (Nuvini Group)
4. **Classify** risk: CRITICAL / HIGH / MEDIUM / LOW / OK
5. **Suggest** specific language edits where needed, drawing from reference NDAs

### Step 5: Generate the Review Report DOCX

Write the analysis results as a JSON file, then generate the DOCX:

```bash
# Write the report JSON to a temp file
cat > /tmp/nda_report.json << 'REPORT_EOF'
{
  "document_name": "<filename>",
  "review_date": "<YYYY-MM-DD>",
  "verdict": "APPROVED" or "NEEDS REVISION",
  "executive_summary": "<2-3 sentences>",
  "risk_counts": {
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0
  },
  "clauses": [
    {
      "name": "<clause name>",
      "status": "OK" | "FLAGGED" | "CRITICAL",
      "risk": "CRITICAL" | "HIGH" | "MEDIUM" | "LOW",
      "current_language": "<quoted text from the NDA>",
      "issue": "<description of the problem>",
      "recommended_edit": "<suggested replacement language>",
      "reference": "<which reference NDA>"
    }
  ],
  "missing_clauses": ["<clause descriptions>"],
  "recommended_actions": ["<action items>"]
}
REPORT_EOF

# Generate the DOCX
uv run --project /Users/ps/code/nuvini-nda python3 /Users/ps/code/nuvini-nda/scripts/generate_report.py /tmp/nda_report.json "/Users/ps/code/nuvini-nda/output/NDA_Review_<filename>_<date>.docx"
```

For clauses with status "OK", omit the `issue` and `recommended_edit` fields.

### Step 6: Present Results

Present a concise summary in chat:

```
## NDA Review: <filename>
**Verdict: APPROVED** or **Verdict: NEEDS REVISION**

### Risk Summary
- Critical: X | High: Y | Medium: Z | Low: W

### Key Findings
1. [Most important finding]
2. [Second most important]
3. [Third most important]

Full report saved to: `/Users/ps/code/nuvini-nda/output/NDA_Review_<name>_<date>.docx`

> This is an analytical comparison, not legal advice. Flagged items should be reviewed by qualified legal counsel.
```

## Managing Reference NDAs

When the user wants to add reference NDAs:

```bash
cp "<file_path>" /Users/ps/code/nuvini-nda/references/
```

After adding, count references:

```bash
ls /Users/ps/code/nuvini-nda/references/ | wc -l
```

Tell the user: "Added [filename] to the reference library. I now have [N] reference NDAs to compare against."

## Important Notes

- **Never provide legal advice.** Always caveat that this is an analytical comparison tool, not legal counsel. Recommend legal review for any flagged items.
- **Preserve confidentiality.** Don't include full NDA text in chat responses — keep details in the document.
- **Be specific.** Vague flags like "this seems unusual" are unhelpful. Always explain WHY something is flagged and provide concrete suggested edits.
- **M&A Context.** Given the user's M&A background at Nuvini Group, pay special attention to MNPI provisions, standstill clauses, non-circumvention, and carve-outs for financial advisors and investment banks.
- **PDF handling.** For PDFs over 10 pages, use the `pages` parameter: `Read(file_path="doc.pdf", pages="1-5")`. Maximum 20 pages per request.
- **Language matching.** Detect the language of the NDA under review. If the document is in Brazilian Portuguese, ALL output must be in Brazilian Portuguese — the chat summary, the DOCX report (executive summary, clause analysis, issues, recommended edits, actions), and any suggested replacement language. If the document is in English, output in English. Always match the document's language.
- **Open output.** After generating the DOCX, offer to open it: `open "<output_path>"`
