/**
 * Phase 0: Verify Chrome DevTools MCP is available
 * Auto-configure if missing
 */

import * as fs from 'fs';
import * as path from 'path';
import { TestContext, StepResult } from '../types';

export async function verifyMCPStep(
  context: TestContext
): Promise<StepResult> {
  const claudeJsonPath = path.join(process.cwd(), '.claude.json');

  try {
    // Check if chrome-devtools MCP tools are available
    // In a real implementation, this would try to use an MCP tool
    // For now, check if .claude.json has the configuration

    let claudeConfig: any = {};

    if (fs.existsSync(claudeJsonPath)) {
      const content = fs.readFileSync(claudeJsonPath, 'utf-8');
      claudeConfig = JSON.parse(content);
    }

    const hasChromeDevTools =
      claudeConfig.mcpServers?.['chrome-devtools'] !== undefined;

    if (hasChromeDevTools) {
      return {
        status: 'passed',
        message: 'Chrome DevTools MCP is configured',
      };
    }

    // Auto-configure Chrome DevTools MCP
    if (!claudeConfig.mcpServers) {
      claudeConfig.mcpServers = {};
    }

    claudeConfig.mcpServers['chrome-devtools'] = {
      command: 'npx',
      args: ['-y', '@anthropic/mcp-chrome-devtools'],
    };

    // Write updated configuration
    fs.writeFileSync(claudeJsonPath, JSON.stringify(claudeConfig, null, 2), 'utf-8');

    return {
      status: 'warning',
      message:
        'Chrome DevTools MCP has been configured in .claude.json. Please restart Claude Code session.',
      details: {
        action: 'configured',
        path: claudeJsonPath,
      },
    };
  } catch (error) {
    return {
      status: 'failed',
      message: `Failed to verify/configure Chrome DevTools MCP: ${error}`,
    };
  }
}
