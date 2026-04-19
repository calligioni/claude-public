/**
 * File-based state manager for fulltest-skill
 * Persists test run state to JSON files for resume capability
 */

import * as fs from 'fs';
import * as path from 'path';
import { TestState } from '../types';

export class StateManager {
  private stateDir: string;

  constructor(outputDir: string = './test-artifacts') {
    this.stateDir = path.join(outputDir, 'state');
    this.ensureStateDirectory();
  }

  /**
   * Ensure state directory exists
   */
  private ensureStateDirectory(): void {
    if (!fs.existsSync(this.stateDir)) {
      fs.mkdirSync(this.stateDir, { recursive: true });
    }
  }

  /**
   * Generate a unique test run ID
   */
  public generateTestRunId(): string {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const random = Math.random().toString(36).substring(2, 8);
    return `test-run-${timestamp}-${random}`;
  }

  /**
   * Get file path for a test run
   */
  private getStatePath(testRunId: string): string {
    return path.join(this.stateDir, `${testRunId}.json`);
  }

  /**
   * Save test state to file
   */
  public async save(state: TestState): Promise<void> {
    const statePath = this.getStatePath(state.testRunId);

    try {
      // Convert Map to Object for JSON serialization
      const serializable = {
        ...state,
        testedUrls: Object.fromEntries(
          Object.entries(state.testedUrls)
        ),
      };

      const content = JSON.stringify(serializable, null, 2);
      fs.writeFileSync(statePath, content, 'utf-8');

      console.log(`State saved to ${statePath}`);
    } catch (error) {
      console.error(`Failed to save state to ${statePath}:`, error);
      throw error;
    }
  }

  /**
   * Load test state from file
   */
  public async load(testRunId: string): Promise<TestState | null> {
    const statePath = this.getStatePath(testRunId);

    try {
      if (!fs.existsSync(statePath)) {
        return null;
      }

      const content = fs.readFileSync(statePath, 'utf-8');
      const data = JSON.parse(content);

      // Convert Object back to Map if needed
      return {
        ...data,
        testedUrls: data.testedUrls || {},
      } as TestState;
    } catch (error) {
      console.error(`Failed to load state from ${statePath}:`, error);
      return null;
    }
  }

  /**
   * Resume a test run from saved state
   */
  public async resume(testRunId: string): Promise<TestState | null> {
    const state = await this.load(testRunId);

    if (!state) {
      console.warn(`No saved state found for test run: ${testRunId}`);
      return null;
    }

    if (state.status === 'passed' || state.status === 'failed' || state.status === 'stopped') {
      console.warn(`Test run ${testRunId} is already completed with status: ${state.status}`);
      return null;
    }

    console.log(`Resuming test run: ${testRunId} from ${state.status} status`);
    return state;
  }

  /**
   * List all saved test runs
   */
  public async list(): Promise<string[]> {
    try {
      const files = fs.readdirSync(this.stateDir);
      return files
        .filter((file) => file.endsWith('.json'))
        .map((file) => file.replace('.json', ''));
    } catch (error) {
      console.error(`Failed to list test runs:`, error);
      return [];
    }
  }

  /**
   * Delete old test run states (cleanup)
   * @param olderThanDays - Delete states older than this many days
   */
  public async cleanup(olderThanDays: number = 7): Promise<number> {
    const testRuns = await this.list();
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);

    let deleted = 0;

    for (const testRunId of testRuns) {
      const state = await this.load(testRunId);
      if (!state) continue;

      const startedAt = new Date(state.startedAt);
      if (startedAt < cutoffDate) {
        const statePath = this.getStatePath(testRunId);
        try {
          fs.unlinkSync(statePath);
          deleted++;
          console.log(`Deleted old test run: ${testRunId}`);
        } catch (error) {
          console.error(`Failed to delete ${statePath}:`, error);
        }
      }
    }

    console.log(`Cleaned up ${deleted} old test runs`);
    return deleted;
  }

  /**
   * Create initial test state
   */
  public createInitialState(config: any, pages: any[]): TestState {
    return {
      testRunId: this.generateTestRunId(),
      status: 'pending',
      startedAt: new Date().toISOString(),
      iteration: 0,
      config,
      pages,
      testedUrls: {},
      iterations: [],
      artifacts: {
        screenshots: [],
        logs: [],
        reports: [],
      },
    };
  }

  /**
   * Mark test run as running
   */
  public async markRunning(state: TestState): Promise<void> {
    state.status = 'running';
    await this.save(state);
  }

  /**
   * Mark test run as completed
   */
  public async markCompleted(
    state: TestState,
    status: 'passed' | 'failed' | 'stopped'
  ): Promise<void> {
    state.status = status;
    state.completedAt = new Date().toISOString();
    await this.save(state);
  }

  /**
   * Update state with iteration results
   */
  public async updateIteration(
    state: TestState,
    iteration: any
  ): Promise<void> {
    state.iterations.push(iteration);
    state.iteration = iteration.number;
    await this.save(state);
  }
}
