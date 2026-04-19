/**
 * Phase 3: Analysis & Categorization
 * Analyze test results and categorize failures
 */

import { TestContext, StepResult, AnalysisResult, Issue, TestResult } from '../types';

export async function analyzeStep(
  context: TestContext,
  testResults: TestResult[]
): Promise<AnalysisResult> {
  const issues: Issue[] = [];

  // Extract issues from test results
  for (const result of testResults) {
    if (result.status === 'fail') {
      // JavaScript errors
      for (const error of result.consoleErrors) {
        issues.push({
          type: 'javascript',
          severity: isErrorCritical(error.message) ? 'critical' : 'high',
          message: error.message,
          url: result.url,
          fixable: isErrorFixable(error.message),
          details: { error },
        });
      }

      // Network failures
      for (const failure of result.networkFailures) {
        issues.push({
          type: 'network',
          severity: failure.statusCode === 404 ? 'high' : 'medium',
          message: `${failure.method} ${failure.url} [${failure.statusCode}]`,
          url: result.url,
          fixable: failure.statusCode === 404,
          details: { failure },
        });
      }

      // Broken links
      for (const link of result.brokenLinks) {
        issues.push({
          type: 'network',
          severity: 'medium',
          message: `Broken link: ${link.url} [${link.statusCode}]`,
          url: result.url,
          fixable: true,
          details: { link },
        });
      }
    }
  }

  // Categorize by type
  const categories = {
    javascriptErrors: issues.filter((i) => i.type === 'javascript').length,
    networkFailures: issues.filter((i) => i.type === 'network').length,
    missingElements: issues.filter((i) => i.type === 'missing-element').length,
    performanceIssues: issues.filter((i) => i.type === 'performance').length,
  };

  // Categorize by priority
  const issuesByPriority = {
    critical: issues.filter((i) => i.severity === 'critical'),
    high: issues.filter((i) => i.severity === 'high'),
    medium: issues.filter((i) => i.severity === 'medium'),
    low: issues.filter((i) => i.severity === 'low'),
  };

  const analysis: AnalysisResult = {
    totalIssues: issues.length,
    fixableIssues: issues.filter((i) => i.fixable).length,
    criticalIssues: issuesByPriority.critical.length,
    allPassed: issues.length === 0,
    categories,
    issuesByPriority,
  };

  return analysis;
}

/**
 * Check if error is critical (breaks functionality)
 */
function isErrorCritical(message: string): boolean {
  const criticalPatterns = [
    'is not defined',
    'Cannot read property',
    'Cannot read properties of null',
    'Cannot read properties of undefined',
    'is not a function',
  ];

  return criticalPatterns.some((pattern) => message.includes(pattern));
}

/**
 * Check if error can be auto-fixed
 */
function isErrorFixable(message: string): boolean {
  const fixablePatterns = [
    'Cannot read properties of null',
    'getElementById',
    'querySelector',
  ];

  return fixablePatterns.some((pattern) => message.includes(pattern));
}
