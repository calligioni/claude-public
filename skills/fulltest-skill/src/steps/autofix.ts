/**
 * Phase 4: Auto-Fix
 * Apply conservative fixes to issues
 */

import { TestContext, StepResult, Fix, Issue } from '../types';
import { applyFixes } from '../utils/fix-patterns';

export async function autofixStep(
  context: TestContext,
  issues: Issue[]
): Promise<StepResult> {
  if (!context.config.autoFix.enabled) {
    return {
      status: 'skipped',
      message: 'Auto-fix is disabled',
    };
  }

  const fixableIssues = issues.filter((i) => i.fixable);

  if (fixableIssues.length === 0) {
    return {
      status: 'passed',
      message: 'No fixable issues found',
    };
  }

  try {
    const fixes = await applyFixes(fixableIssues, context.config);

    const fixedCount = fixes.filter((f) => f.status === 'fixed').length;
    const skippedCount = fixes.filter((f) => f.status === 'skipped').length;

    return {
      status: fixedCount > 0 ? 'passed' : 'warning',
      message: `Fixed ${fixedCount} issues, skipped ${skippedCount}`,
      details: {
        fixed: fixedCount,
        skipped: skippedCount,
        fixes,
      },
    };
  } catch (error) {
    return {
      status: 'failed',
      message: `Auto-fix failed: ${error}`,
    };
  }
}
