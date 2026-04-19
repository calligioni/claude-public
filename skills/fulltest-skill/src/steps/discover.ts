/**
 * Phase 1: Discovery & Mapping
 * Discover all pages on the site
 */

import { TestContext, StepResult, PageInfo } from '../types';
import { SiteMapper } from '../core/site-mapper';

export async function discoverStep(
  context: TestContext
): Promise<StepResult> {
  try {
    const mapper = new SiteMapper(context.config);
    const pages = await mapper.mapSite(context.config.baseUrl);

    // Update context with discovered pages
    context.pages = pages;
    context.state.pages = pages;

    return {
      status: 'passed',
      message: `Discovered ${pages.length} pages`,
      details: {
        pageCount: pages.length,
        pages: pages.map((p) => p.url),
      },
    };
  } catch (error) {
    return {
      status: 'failed',
      message: `Site discovery failed: ${error}`,
    };
  }
}
