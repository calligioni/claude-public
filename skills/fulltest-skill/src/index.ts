/**
 * fulltest-skill - Unified Full-Spectrum Testing Agent
 * Entry point
 */

import { TestRunner } from './runner';
import { loadConfig } from './config';
import { TestConfig } from './types';

export { TestRunner, loadConfig };
export * from './types';

/**
 * Main entry point
 */
export async function runFullTest(
  cwd: string = process.cwd(),
  overrides?: Partial<TestConfig>
) {
  const config = loadConfig(cwd, overrides);
  const runner = new TestRunner(config);
  return await runner.run();
}

// CLI support
if (require.main === module) {
  const cwd = process.cwd();
  const baseUrl = process.argv[2] || 'http://localhost:3000';

  runFullTest(cwd, { baseUrl })
    .then((result) => {
      console.log('\n✅ Test complete:');
      console.log(JSON.stringify(result, null, 2));
      process.exit(result.status === 'passed' ? 0 : 1);
    })
    .catch((error) => {
      console.error('\n❌ Test failed:', error);
      process.exit(1);
    });
}
