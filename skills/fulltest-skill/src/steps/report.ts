/**
 * Phase 6: Report Generation
 * Generate comprehensive executive summary report
 */

import * as fs from 'fs';
import * as path from 'path';
import { TestContext, StepResult } from '../types';

export async function reportStep(context: TestContext): Promise<StepResult> {
  try {
    const reportDir = path.join(context.config.reporting.outputDir, 'reports');

    // Ensure reports directory exists
    if (!fs.existsSync(reportDir)) {
      fs.mkdirSync(reportDir, { recursive: true });
    }

    const reportPath = path.join(reportDir, `${context.testRunId}.md`);
    const report = generateMarkdownReport(context);

    fs.writeFileSync(reportPath, report, 'utf-8');

    return {
      status: 'passed',
      message: `Report generated: ${reportPath}`,
      details: {
        reportPath,
        format: 'markdown',
      },
    };
  } catch (error) {
    return {
      status: 'failed',
      message: `Report generation failed: ${error}`,
    };
  }
}

/**
 * Generate markdown report
 */
function generateMarkdownReport(context: TestContext): string {
  const { state, config } = context;
  const lines: string[] = [];

  // Header
  lines.push(`# Site Test Report: ${config.baseUrl}`);
  lines.push('');

  // Executive Summary
  lines.push('## Executive Summary');
  lines.push('');
  lines.push(`- **Site URL**: ${config.baseUrl}`);
  lines.push(`- **Test Run ID**: ${state.testRunId}`);
  lines.push(`- **Final Status**: ${state.status.toUpperCase()}`);
  lines.push(`- **Test Iterations**: ${state.iterations.length} of ${config.maxIterations}`);
  lines.push(`- **Pages Tested**: ${state.pages.length}`);

  const totalFixes = state.iterations.reduce(
    (sum, iter) => sum + iter.fixes.length,
    0
  );
  lines.push(`- **Auto-Fixes Applied**: ${totalFixes}`);
  lines.push('');

  // Iteration Results
  for (const iteration of state.iterations) {
    lines.push(`## Iteration ${iteration.number}`);
    lines.push('');

    // Test Results Table
    lines.push('### Test Results');
    lines.push('');
    lines.push('| Page | Status | Console Errors | Network Failures | Broken Links |');
    lines.push('|------|--------|----------------|------------------|--------------|');

    for (const result of iteration.tests.website) {
      lines.push(
        `| ${result.url} | ${result.status.toUpperCase()} | ${result.consoleErrors.length} | ${result.networkFailures.length} | ${result.brokenLinks.length} |`
      );
    }
    lines.push('');

    // Analysis
    lines.push('### Analysis');
    lines.push('');
    lines.push(`- Total Issues: ${iteration.analysis.totalIssues}`);
    lines.push(`- Fixable Issues: ${iteration.analysis.fixableIssues}`);
    lines.push(`- Critical Issues: ${iteration.analysis.criticalIssues}`);
    lines.push('');

    lines.push('**Issues by Category:**');
    lines.push('');
    lines.push(`- JavaScript Errors: ${iteration.analysis.categories.javascriptErrors}`);
    lines.push(`- Network Failures: ${iteration.analysis.categories.networkFailures}`);
    lines.push(`- Missing Elements: ${iteration.analysis.categories.missingElements}`);
    lines.push(`- Performance Issues: ${iteration.analysis.categories.performanceIssues}`);
    lines.push('');

    // Fixes Applied
    if (iteration.fixes.length > 0) {
      lines.push('### Fixes Applied');
      lines.push('');

      for (const fix of iteration.fixes) {
        const icon = fix.status === 'fixed' ? '✅' : '⚠️';
        lines.push(`${icon} ${fix.issue}`);
        if (fix.fixApplied) {
          lines.push(`   - Fix: ${fix.fixApplied}`);
        }
        if (fix.reason) {
          lines.push(`   - Reason: ${fix.reason}`);
        }
      }
      lines.push('');
    }
  }

  // Issues Summary
  lines.push('## Issues Summary');
  lines.push('');

  const allFixes = state.iterations.flatMap((iter) => iter.fixes);
  const fixedIssues = allFixes.filter((f) => f.status === 'fixed');
  const skippedIssues = allFixes.filter((f) => f.status === 'skipped');

  if (fixedIssues.length > 0) {
    lines.push('### Fixed Automatically');
    lines.push('');
    fixedIssues.forEach((fix, i) => {
      lines.push(`${i + 1}. ✅ ${fix.issue}`);
    });
    lines.push('');
  }

  if (skippedIssues.length > 0) {
    lines.push('### Requires Manual Attention');
    lines.push('');
    skippedIssues.forEach((fix, i) => {
      lines.push(`${i + 1}. ⚠️ ${fix.issue}`);
      if (fix.reason) {
        lines.push(`   - ${fix.reason}`);
      }
    });
    lines.push('');
  }

  // Recommendations
  lines.push('## Recommendations');
  lines.push('');
  if (skippedIssues.length > 0) {
    lines.push('- Review and manually fix issues that could not be auto-fixed');
  }
  if (state.iterations.length === config.maxIterations && state.status !== 'passed') {
    lines.push('- Some issues persist after maximum iterations - consider manual review');
  }
  lines.push('- Consider adding automated tests to prevent regressions');
  lines.push('- Review console errors and network failures in detail');
  lines.push('');

  // Test Artifacts
  lines.push('## Test Artifacts');
  lines.push('');
  lines.push(`- **State File**: ${config.reporting.outputDir}/state/${state.testRunId}.json`);
  lines.push(`- **Report**: ${config.reporting.outputDir}/reports/${state.testRunId}.md`);
  lines.push('');

  // Footer
  lines.push('---');
  lines.push('');
  lines.push(`Generated by fulltest-skill v2.0.0`);
  lines.push(`Test Run: ${state.testRunId}`);
  lines.push(`Completed: ${state.completedAt || 'In Progress'}`);

  return lines.join('\n');
}
