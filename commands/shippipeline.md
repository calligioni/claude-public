Run the full feature pipeline for: $ARGUMENTS
Execute in order. Do not skip ahead.
Confirm each handoff file exists before the next stage.
1. Delegate to planner. Wait for .pipeline/spec.md. If spec has OPEN QUESTIONS — stop, show me.
2. Delegate to coder. Wait for .pipeline/changes.md.
3. Delegate to tester. Wait for .pipeline/test-results.md. If tests failed — stop, show me failures.
4. Delegate to reviewer. Show me .pipeline/review.md.
Report the final verdict.
Do not merge. Leave branch for morning review.