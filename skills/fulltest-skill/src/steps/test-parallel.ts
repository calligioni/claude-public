/**
 * Phase 2: Parallel Testing
 * Test all pages in parallel using page-tester subagents
 */

import { TestContext, StepResult, TestResult } from '../types';
import { ParallelExecutor } from '../core/parallel-executor';

export async function testParallelStep(
  context: TestContext
): Promise<StepResult> {
  try {
    const executor = new ParallelExecutor(context.config);
    const results = await executor.spawnPageTesters(context.pages);

    const passed = results.filter((r) => r.status === 'pass').length;
    const failed = results.filter((r) => r.status === 'fail').length;

    return {
      status: failed > 0 ? 'warning' : 'passed',
      message: `Tested ${results.length} pages: ${passed} passed, ${failed} failed`,
      details: {
        total: results.length,
        passed,
        failed,
        results,
      },
    };
  } catch (error) {
    return {
      status: 'failed',
      message: `Parallel testing failed: ${error}`,
    };
  }
}
