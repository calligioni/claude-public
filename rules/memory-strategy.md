# Memory Strategy

## Entity Naming: `{type}:{identifier}`

| Prefix             | Purpose                       |
| ------------------ | ----------------------------- |
| `pattern:`         | Reusable code/design patterns |
| `mistake:`         | Errors to avoid               |
| `tech-insight:`    | Technology-specific learnings |
| `preference:`      | User/project preferences      |
| `design-decision:` | Design choices made           |
| `test-pattern:`    | Reusable test sequences       |
| `common-bug:`      | Frequently found issues       |
| `architecture:`    | Architecture decisions        |

Use lowercase with hyphens. Include project name when project-specific.

## Required Observations

Every entity: `"Discovered: {date}"`, `"Source: {how}"`, `"Applied in: {project} - {date} - {HELPFUL|NOT HELPFUL|MODIFIED}"`, `"Use count: {N}"`

## Save vs Skip

**Save when:** high generality, learned from failure, user explicitly shared, expensive to regenerate, high severity.
**Skip when:** duplicate exists (>85% similar), project-specific detail, trivial/obvious.
