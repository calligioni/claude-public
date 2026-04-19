/**
 * Site mapping and discovery algorithm
 * Crawls website to discover all pages
 */

import { PageInfo, TestConfig } from '../types';

export class SiteMapper {
  private visited: Set<string> = new Set();
  private toVisit: string[] = [];
  private pages: PageInfo[] = [];
  private config: TestConfig;

  constructor(config: TestConfig) {
    this.config = config;
  }

  /**
   * Extract internal links from snapshot
   */
  private extractInternalLinks(snapshot: any, baseUrl: string): string[] {
    const links: string[] = [];
    const baseDomain = new URL(baseUrl).hostname;

    // Parse snapshot to find all links
    // This is a placeholder - in real implementation, would parse the snapshot
    // For now, return empty array
    // TODO: Implement link extraction from Chrome DevTools snapshot

    return links.filter((link) => {
      try {
        const url = new URL(link, baseUrl);

        // Filter out external links
        if (url.hostname !== baseDomain) return false;

        // Filter out anchors
        if (url.hash && url.pathname === new URL(baseUrl).pathname) return false;

        // Filter out assets
        const assetExtensions = [
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.svg',
          '.css',
          '.js',
          '.ico',
          '.woff',
          '.woff2',
          '.ttf',
          '.eot',
        ];
        if (assetExtensions.some((ext) => url.pathname.endsWith(ext)))
          return false;

        // Filter out ignored patterns
        if (
          this.config.linkValidation.ignorePatterns.some((pattern) =>
            link.startsWith(pattern)
          )
        )
          return false;

        return true;
      } catch {
        return false;
      }
    });
  }

  /**
   * Normalize URL for deduplication
   */
  private normalizeUrl(url: string): string {
    try {
      const parsed = new URL(url);
      // Remove trailing slash for consistency
      let path = parsed.pathname;
      if (path.endsWith('/') && path.length > 1) {
        path = path.slice(0, -1);
      }
      return parsed.origin + path + parsed.search;
    } catch {
      return url;
    }
  }

  /**
   * Map entire site starting from root URL
   * Returns list of discovered pages
   */
  public async mapSite(rootUrl: string): Promise<PageInfo[]> {
    this.visited.clear();
    this.toVisit = [rootUrl];
    this.pages = [];

    const maxPages = this.config.maxPages;

    while (this.toVisit.length > 0 && this.pages.length < maxPages) {
      const url = this.toVisit.shift()!;
      const normalizedUrl = this.normalizeUrl(url);

      if (this.visited.has(normalizedUrl)) {
        continue;
      }

      this.visited.add(normalizedUrl);

      try {
        // In real implementation, would use Chrome DevTools MCP to navigate and get snapshot
        // For now, just add the page
        const pageInfo: PageInfo = {
          url: normalizedUrl,
          title: `Page: ${normalizedUrl}`,
          discoveredAt: new Date().toISOString(),
        };

        this.pages.push(pageInfo);

        // TODO: Use Chrome DevTools MCP to navigate and extract links
        // const snapshot = await chromeDevTools.navigate(url);
        // const links = this.extractInternalLinks(snapshot, rootUrl);
        //
        // for (const link of links) {
        //   const normalized = this.normalizeUrl(link);
        //   if (!this.visited.has(normalized)) {
        //     this.toVisit.push(link);
        //   }
        // }
      } catch (error) {
        console.warn(`Failed to map ${url}:`, error);
      }
    }

    console.log(`Site mapping complete: ${this.pages.length} pages discovered`);
    return this.pages;
  }

  /**
   * Get discovered pages
   */
  public getPages(): PageInfo[] {
    return this.pages;
  }

  /**
   * Check if URL has been visited
   */
  public isVisited(url: string): boolean {
    return this.visited.has(this.normalizeUrl(url));
  }
}
