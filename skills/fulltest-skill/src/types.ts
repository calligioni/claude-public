/**
 * Core TypeScript types for fulltest-skill
 * Unified full-spectrum testing agent
 */

/**
 * Configuration for a test run
 */
export interface TestConfig {
  baseUrl: string;
  maxIterations: number;
  maxPages: number;
  timeout: number;
  parallel: {
    batchSize: number;
    maxSubagents: number;
  };
  autoFix: {
    enabled: boolean;
    conservative: boolean;
    skipPatterns: string[];
    allowedFixTypes: string[];
  };
  reporting: {
    format: 'markdown' | 'json' | 'html';
    includeScreenshots: boolean;
    outputDir: string;
    verbose: boolean;
  };
  linkValidation: {
    testExternalLinks: boolean;
    followRedirects: boolean;
    timeout: number;
    retryCount: number;
    ignorePatterns: string[];
  };
}

/**
 * Information about a discovered page
 */
export interface PageInfo {
  url: string;
  title?: string;
  linkCount?: number;
  discoveredAt: string;
}

/**
 * Context passed to each step during execution
 */
export interface TestContext {
  testRunId: string;
  config: TestConfig;
  state: TestState;
  pages: PageInfo[];
  iteration: number;
  baseUrl: string;
}

/**
 * State of a test run (persisted to JSON file)
 */
export interface TestState {
  testRunId: string;
  status: 'pending' | 'running' | 'passed' | 'failed' | 'stopped';
  startedAt: string;
  completedAt?: string;
  iteration: number;
  config: TestConfig;
  pages: PageInfo[];
  testedUrls: Record<string, LinkTestResult>;  // For deduplication
  iterations: IterationResult[];
  artifacts: {
    screenshots: string[];
    logs: string[];
    reports: string[];
  };
}

/**
 * Result from testing a link
 */
export interface LinkTestResult {
  url: string;
  statusCode: number;
  tested: boolean;
  testedAt: string;
}

/**
 * Result from one iteration of testing
 */
export interface IterationResult {
  number: number;
  startedAt: string;
  completedAt: string;
  tests: {
    website: TestResult[];
    api: TestResult[];
  };
  analysis: AnalysisResult;
  fixes: Fix[];
  summary: {
    passed: number;
    failed: number;
    skipped: number;
  };
}

/**
 * Result from testing a single page/endpoint
 */
export interface TestResult {
  url: string;
  status: 'pass' | 'fail' | 'skip';
  title?: string;
  consoleErrors: ConsoleError[];
  networkFailures: NetworkFailure[];
  brokenLinks: BrokenLink[];
  structure?: {
    hasHeader: boolean;
    hasMain: boolean;
    hasFooter: boolean;
  };
  duration?: number;
}

/**
 * Console error found during testing
 */
export interface ConsoleError {
  message: string;
  line?: number;
  column?: number;
  source?: string;
}

/**
 * Network failure (404, 500, etc)
 */
export interface NetworkFailure {
  url: string;
  method: string;
  statusCode: number;
  message?: string;
}

/**
 * Broken link found on a page
 */
export interface BrokenLink {
  text: string;
  url: string;
  statusCode: number;
  foundOn: string;
}

/**
 * Analysis result from categorizing failures
 */
export interface AnalysisResult {
  totalIssues: number;
  fixableIssues: number;
  criticalIssues: number;
  allPassed: boolean;
  categories: {
    javascriptErrors: number;
    networkFailures: number;
    missingElements: number;
    performanceIssues: number;
  };
  issuesByPriority: {
    critical: Issue[];
    high: Issue[];
    medium: Issue[];
    low: Issue[];
  };
}

/**
 * An issue found during testing
 */
export interface Issue {
  type: 'javascript' | 'network' | 'missing-element' | 'performance';
  severity: 'critical' | 'high' | 'medium' | 'low';
  message: string;
  url: string;
  fixable: boolean;
  details?: Record<string, unknown>;
}

/**
 * A fix applied to the codebase
 */
export interface Fix {
  issue: string;
  rootCause: string;
  file: string | null;
  fixApplied: string | null;
  status: 'fixed' | 'skipped';
  reason?: string;
  pattern?: string;
}

/**
 * Definition of a test step
 */
export interface StepDefinition {
  name: string;
  displayName: string;
  execute: (context: TestContext) => Promise<StepResult>;
  canBeSkipped?: (config: TestConfig) => boolean;
  isCleanup?: boolean;
}

/**
 * Result from executing a step
 */
export interface StepResult {
  status: 'passed' | 'failed' | 'skipped' | 'warning';
  message: string;
  details?: Record<string, unknown>;
  duration?: number;
}

/**
 * Final test run result
 */
export interface TestRunResult {
  id: string;
  status: 'passed' | 'failed' | 'stopped';
  startedAt: string;
  completedAt: string;
  duration: number;
  iterations: number;
  totalTests: number;
  passedTests: number;
  failedTests: number;
  fixesApplied: number;
  reportPath: string;
  summary: string;
}

/**
 * Fix pattern for auto-fixing issues
 */
export interface FixPattern {
  name: string;
  detect: (error: string | Issue) => boolean;
  fix: (context: FixContext) => Promise<Fix | null>;
}

/**
 * Context for applying a fix
 */
export interface FixContext {
  issue: Issue;
  config: TestConfig;
  cwd: string;
}
