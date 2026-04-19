/**
 * Test Runner - Main orchestrator
 * Implements the 6-phase testing loop
 */

import { TestConfig, TestRunResult, TestContext, TestState, IterationResult } from './types';
import { StateManager } from './core/state-manager';
import { verifyMCPStep } from './steps/verify-mcp';
import { discoverStep } from './steps/discover';
import { testParallelStep } from './steps/test-parallel';
import { analyzeStep } from './steps/analyze';
import { autofixStep } from './steps/autofix';
import { reportStep } from './steps/report';

export class TestRunner {
  private config: TestConfig;
  private stateManager: StateManager;

  constructor(config: TestConfig) {
    this.config = config;
    this.stateManager = new StateManager(config.reporting.outputDir);
  }

  /**
   * Run the complete testing workflow
   */
  public async run(): Promise<TestRunResult> {
    const startTime = Date.now();
    let state: TestState = this.stateManager.createInitialState(
      this.config,
      []
    );

    try {
      // Create initial context
      const context: TestContext = {
        testRunId: state.testRunId,
        config: this.config,
        state,
        pages: [],
        iteration: 0,
        baseUrl: this.config.baseUrl,
      };

      console.log(`\n🚀 Starting test run: ${state.testRunId}\n`);

      // Phase 0: Verify MCP
      console.log('Phase 0: Verifying Chrome DevTools MCP...');
      const mcpResult = await verifyMCPStep(context);
      if (mcpResult.status === 'failed') {
        throw new Error(mcpResult.message);
      }
      if (mcpResult.status === 'warning') {
        console.warn(mcpResult.message);
        // Stop here - user needs to restart session
        return this.generateResult(state, 'stopped', startTime);
      }

      // Mark as running
      await this.stateManager.markRunning(state);

      // Phase 1: Discovery
      console.log('\nPhase 1: Discovering pages...');
      const discoverResult = await discoverStep(context);
      if (discoverResult.status === 'failed') {
        throw new Error(discoverResult.message);
      }
      console.log(`✓ ${discoverResult.message}`);

      // Testing loop (max iterations)
      let allPassed = false;

      for (
        let i = 0;
        i < this.config.maxIterations && !allPassed;
        i++
      ) {
        context.iteration = i + 1;
        console.log(`\n📋 Iteration ${context.iteration}/${this.config.maxIterations}`);

        const iteration: IterationResult = {
          number: context.iteration,
          startedAt: new Date().toISOString(),
          completedAt: '',
          tests: { website: [] as any[], api: [] as any[] },
          analysis: {
            totalIssues: 0,
            fixableIssues: 0,
            criticalIssues: 0,
            allPassed: false,
            categories: {
              javascriptErrors: 0,
              networkFailures: 0,
              missingElements: 0,
              performanceIssues: 0,
            },
            issuesByPriority: { critical: [] as any[], high: [] as any[], medium: [] as any[], low: [] as any[] },
          },
          fixes: [] as any[],
          summary: { passed: 0 as number, failed: 0 as number, skipped: 0 as number },
        };

        // Phase 2: Test in parallel
        console.log('\nPhase 2: Testing pages in parallel...');
        const testResult = await testParallelStep(context);
        console.log(`✓ ${testResult.message}`);

        iteration.tests.website = (testResult.details?.results || []) as any;
        iteration.summary.passed = (testResult.details?.passed || 0) as number;
        iteration.summary.failed = (testResult.details?.failed || 0) as number;

        // Phase 3: Analyze
        console.log('\nPhase 3: Analyzing results...');
        const analysis = await analyzeStep(context, iteration.tests.website);
        iteration.analysis = analysis;

        console.log(
          `✓ Found ${analysis.totalIssues} issues (${analysis.fixableIssues} fixable)`
        );

        if (analysis.allPassed) {
          console.log('✅ All tests passed!');
          allPassed = true;
          iteration.completedAt = new Date().toISOString();
          await this.stateManager.updateIteration(state, iteration);
          break;
        }

        // Phase 4: Auto-fix
        if (this.config.autoFix.enabled && analysis.fixableIssues > 0) {
          console.log('\nPhase 4: Applying auto-fixes...');
          const fixableIssues = [
            ...analysis.issuesByPriority.critical.filter((i) => i.fixable),
            ...analysis.issuesByPriority.high.filter((i) => i.fixable),
            ...analysis.issuesByPriority.medium.filter((i) => i.fixable),
            ...analysis.issuesByPriority.low.filter((i) => i.fixable),
          ];

          const fixResult = await autofixStep(context, fixableIssues);
          iteration.fixes = (fixResult.details?.fixes || []) as any;

          console.log(`✓ ${fixResult.message}`);

          const fixedCount = fixResult.details?.fixed || 0;
          if (fixedCount === 0) {
            console.log('⚠️  No fixes could be applied, stopping loop');
            iteration.completedAt = new Date().toISOString();
            await this.stateManager.updateIteration(state, iteration);
            break;
          }
        } else {
          console.log('\n⏭️  Skipping auto-fix (disabled or no fixable issues)');
          iteration.completedAt = new Date().toISOString();
          await this.stateManager.updateIteration(state, iteration);
          break;
        }

        iteration.completedAt = new Date().toISOString();
        await this.stateManager.updateIteration(state, iteration);
      }

      // Phase 6: Generate report
      console.log('\nPhase 6: Generating report...');
      const reportResult = await reportStep(context);
      console.log(`✓ ${reportResult.message}`);

      const finalStatus = allPassed ? 'passed' : 'failed';
      await this.stateManager.markCompleted(state, finalStatus);

      const result = this.generateResult(state, finalStatus, startTime);

      console.log(`\n✨ Test run complete: ${result.status.toUpperCase()}`);
      console.log(`   Duration: ${(result.duration / 1000).toFixed(2)}s`);
      console.log(`   Iterations: ${result.iterations}`);
      console.log(`   Fixes Applied: ${result.fixesApplied}`);
      console.log(`   Report: ${result.reportPath}\n`);

      return result;
    } catch (error) {
      console.error(`\n❌ Test run failed: ${error}`);
      await this.stateManager.markCompleted(state, 'failed');
      return this.generateResult(state, 'failed', startTime);
    }
  }

  /**
   * Generate final test run result
   */
  private generateResult(
    state: TestState,
    status: 'passed' | 'failed' | 'stopped',
    startTime: number
  ): TestRunResult {
    const duration = Date.now() - startTime;
    const totalTests = state.iterations.reduce(
      (sum, iter) => sum + (iter.summary.passed + iter.summary.failed),
      0
    );
    const passedTests = state.iterations.reduce(
      (sum, iter) => sum + iter.summary.passed,
      0
    );
    const fixesApplied = state.iterations.reduce(
      (sum, iter) => sum + iter.fixes.length,
      0
    );

    return {
      id: state.testRunId,
      status,
      startedAt: state.startedAt,
      completedAt: state.completedAt || new Date().toISOString(),
      duration,
      iterations: state.iterations.length,
      totalTests,
      passedTests,
      failedTests: totalTests - passedTests,
      fixesApplied,
      reportPath: `${this.config.reporting.outputDir}/reports/${state.testRunId}.md`,
      summary: this.generateSummary(state, status),
    };
  }

  /**
   * Generate summary text
   */
  private generateSummary(
    state: TestState,
    status: 'passed' | 'failed' | 'stopped'
  ): string {
    const lines = [];
    lines.push(`Test Run ${state.testRunId}`);
    lines.push(`Status: ${status.toUpperCase()}`);
    lines.push(`Pages Tested: ${state.pages.length}`);
    lines.push(`Iterations: ${state.iterations.length}`);
    return lines.join('\n');
  }
}
