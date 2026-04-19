/**
 * Configuration loader and validator for fulltest-skill
 */

import * as fs from 'fs';
import * as path from 'path';
import { TestConfig } from './types';

const DEFAULT_CONFIG_PATH = path.join(__dirname, '../config/default.config.json');

/**
 * Load configuration from multiple sources with priority:
 * 1. Project config: ./fulltest-skill.config.json
 * 2. Default config: config/default.config.json
 */
export class ConfigLoader {
  private defaultConfig: TestConfig;

  constructor() {
    this.defaultConfig = this.loadDefaultConfig();
  }

  /**
   * Load default configuration
   */
  private loadDefaultConfig(): TestConfig {
    try {
      const configPath = DEFAULT_CONFIG_PATH;
      const content = fs.readFileSync(configPath, 'utf-8');
      return JSON.parse(content) as TestConfig;
    } catch (error) {
      // Fallback to hardcoded defaults if file not found
      return this.getHardcodedDefaults();
    }
  }

  /**
   * Hardcoded fallback configuration
   */
  private getHardcodedDefaults(): TestConfig {
    return {
      baseUrl: 'http://localhost:3000',
      maxIterations: 3,
      maxPages: 50,
      timeout: 180000,
      parallel: {
        batchSize: 5,
        maxSubagents: 20,
      },
      autoFix: {
        enabled: true,
        conservative: true,
        skipPatterns: ['**/node_modules/**', '**/.git/**'],
        allowedFixTypes: [
          'null-checks',
          'dom-ready-wrap',
          'broken-links',
          'missing-ids',
          'path-corrections',
        ],
      },
      reporting: {
        format: 'markdown',
        includeScreenshots: true,
        outputDir: './test-artifacts',
        verbose: false,
      },
      linkValidation: {
        testExternalLinks: false,
        followRedirects: true,
        timeout: 10000,
        retryCount: 2,
        ignorePatterns: ['mailto:', 'tel:', 'javascript:', '#'],
      },
    };
  }

  /**
   * Load project-specific configuration
   */
  private loadProjectConfig(cwd: string): Partial<TestConfig> | null {
    const projectConfigPath = path.join(cwd, 'fulltest-skill.config.json');

    try {
      if (fs.existsSync(projectConfigPath)) {
        const content = fs.readFileSync(projectConfigPath, 'utf-8');
        return JSON.parse(content) as Partial<TestConfig>;
      }
    } catch (error) {
      console.warn(`Failed to load project config from ${projectConfigPath}:`, error);
    }

    return null;
  }

  /**
   * Merge configurations with deep merge
   */
  private mergeConfigs(
    base: TestConfig,
    override: Partial<TestConfig>
  ): TestConfig {
    return {
      ...base,
      ...override,
      parallel: {
        ...base.parallel,
        ...(override.parallel || {}),
      },
      autoFix: {
        ...base.autoFix,
        ...(override.autoFix || {}),
      },
      reporting: {
        ...base.reporting,
        ...(override.reporting || {}),
      },
      linkValidation: {
        ...base.linkValidation,
        ...(override.linkValidation || {}),
      },
    };
  }

  /**
   * Validate configuration
   */
  private validateConfig(config: TestConfig): void {
    if (!config.baseUrl) {
      throw new Error('baseUrl is required in configuration');
    }

    if (config.maxIterations < 1 || config.maxIterations > 10) {
      throw new Error('maxIterations must be between 1 and 10');
    }

    if (config.maxPages < 1) {
      throw new Error('maxPages must be at least 1');
    }

    if (config.parallel.batchSize < 1 || config.parallel.batchSize > 20) {
      throw new Error('parallel.batchSize must be between 1 and 20');
    }

    const validFormats = ['markdown', 'json', 'html'];
    if (!validFormats.includes(config.reporting.format)) {
      throw new Error(
        `reporting.format must be one of: ${validFormats.join(', ')}`
      );
    }
  }

  /**
   * Load configuration for a test run
   * @param cwd - Current working directory (project root)
   * @param overrides - Runtime configuration overrides
   */
  public load(
    cwd: string,
    overrides?: Partial<TestConfig>
  ): TestConfig {
    // Start with default config
    let config = { ...this.defaultConfig };

    // Merge project config if it exists
    const projectConfig = this.loadProjectConfig(cwd);
    if (projectConfig) {
      config = this.mergeConfigs(config, projectConfig);
    }

    // Merge runtime overrides
    if (overrides) {
      config = this.mergeConfigs(config, overrides);
    }

    // Validate final configuration
    this.validateConfig(config);

    return config;
  }

  /**
   * Get default configuration (useful for reference)
   */
  public getDefaults(): TestConfig {
    return { ...this.defaultConfig };
  }
}

/**
 * Convenience function to load configuration
 */
export function loadConfig(
  cwd: string = process.cwd(),
  overrides?: Partial<TestConfig>
): TestConfig {
  const loader = new ConfigLoader();
  return loader.load(cwd, overrides);
}
