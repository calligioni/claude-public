/**
 * 8 Conservative Fix Patterns
 * Auto-fix patterns for common issues
 */

import { Fix, Issue, FixContext, FixPattern } from '../types';

/**
 * Pattern 1: Null Reference Errors
 */
export const nullReferencePattern: FixPattern = {
  name: 'null-reference',
  detect: (error: string | Issue) => {
    const message = typeof error === 'string' ? error : error.message;
    return message.includes('Cannot read properties of null');
  },
  fix: async (context: FixContext): Promise<Fix | null> => {
    // TODO: Implement actual fix logic
    // Search for the code causing null reference
    // Add null check before accessing property
    return {
      issue: context.issue.message,
      rootCause: 'Null reference - element not found',
      file: null,
      fixApplied: null,
      status: 'skipped',
      reason: 'Requires manual investigation',
      pattern: 'null-reference',
    };
  },
};

/**
 * Pattern 2: DOM Not Ready
 */
export const domNotReadyPattern: FixPattern = {
  name: 'dom-not-ready',
  detect: (error: string | Issue) => {
    const message = typeof error === 'string' ? error : error.message;
    return message.includes('getElementById') || message.includes('querySelector');
  },
  fix: async (context: FixContext): Promise<Fix | null> => {
    // TODO: Wrap code in DOMContentLoaded event listener
    return {
      issue: context.issue.message,
      rootCause: 'Code runs before DOM is ready',
      file: null,
      fixApplied: null,
      status: 'skipped',
      reason: 'Requires code wrapping',
      pattern: 'dom-not-ready',
    };
  },
};

/**
 * Pattern 3: Broken Links (404)
 */
export const brokenLinkPattern: FixPattern = {
  name: 'broken-link',
  detect: (error: string | Issue) => {
    if (typeof error === 'string') return false;
    return error.type === 'network' && error.message.includes('[404]');
  },
  fix: async (context: FixContext): Promise<Fix | null> => {
    // TODO: Find and fix broken links
    // Search for the link in HTML files
    // Correct the path or remove the link
    return {
      issue: context.issue.message,
      rootCause: 'Link points to non-existent page',
      file: null,
      fixApplied: null,
      status: 'skipped',
      reason: 'Requires path correction',
      pattern: 'broken-link',
    };
  },
};

/**
 * Pattern 4: Missing Form IDs
 */
export const missingFormIdPattern: FixPattern = {
  name: 'missing-form-id',
  detect: (error: string | Issue) => {
    const message = typeof error === 'string' ? error : error.message;
    return message.includes('form field') && message.includes('id or name');
  },
  fix: async (context: FixContext): Promise<Fix | null> => {
    // TODO: Add id/name attributes to form inputs
    return {
      issue: context.issue.message,
      rootCause: 'Form input missing id/name attribute',
      file: null,
      fixApplied: null,
      status: 'skipped',
      reason: 'Requires attribute addition',
      pattern: 'missing-form-id',
    };
  },
};

/**
 * Pattern 5: Path Corrections
 */
export const pathCorrectionPattern: FixPattern = {
  name: 'path-correction',
  detect: (error: string | Issue) => {
    const message = typeof error === 'string' ? error : error.message;
    return message.includes('404') && message.includes('/');
  },
  fix: async (context: FixContext): Promise<Fix | null> => {
    // TODO: Correct relative vs absolute paths
    return {
      issue: context.issue.message,
      rootCause: 'Incorrect path (relative vs absolute)',
      file: null,
      fixApplied: null,
      status: 'skipped',
      reason: 'Requires path analysis',
      pattern: 'path-correction',
    };
  },
};

/**
 * Pattern 6: Missing Alt Text
 */
export const missingAltTextPattern: FixPattern = {
  name: 'missing-alt-text',
  detect: (error: string | Issue) => {
    const message = typeof error === 'string' ? error : error.message;
    return message.includes('img') && message.includes('alt');
  },
  fix: async (context: FixContext): Promise<Fix | null> => {
    // TODO: Add alt attributes to images
    return {
      issue: context.issue.message,
      rootCause: 'Image missing alt attribute',
      file: null,
      fixApplied: null,
      status: 'skipped',
      reason: 'Requires descriptive alt text',
      pattern: 'missing-alt-text',
    };
  },
};

/**
 * Pattern 7: Typos in URLs
 */
export const typoInUrlPattern: FixPattern = {
  name: 'typo-in-url',
  detect: (error: string | Issue) => {
    const message = typeof error === 'string' ? error : error.message;
    // Simple heuristic: common typos in URLs
    return (
      message.includes('404') &&
      (message.includes('contcat') ||
        message.includes('abuot') ||
        message.includes('serivces'))
    );
  },
  fix: async (context: FixContext): Promise<Fix | null> => {
    // TODO: Correct spelling in URLs
    return {
      issue: context.issue.message,
      rootCause: 'Typo in URL',
      file: null,
      fixApplied: null,
      status: 'skipped',
      reason: 'Requires spelling correction',
      pattern: 'typo-in-url',
    };
  },
};

/**
 * Pattern 8: CORS Issues
 */
export const corsIssuePattern: FixPattern = {
  name: 'cors-issue',
  detect: (error: string | Issue) => {
    const message = typeof error === 'string' ? error : error.message;
    return message.toLowerCase().includes('cors');
  },
  fix: async (context: FixContext): Promise<Fix | null> => {
    // TODO: Add CORS headers (if server code is available)
    return {
      issue: context.issue.message,
      rootCause: 'CORS policy blocking request',
      file: null,
      fixApplied: null,
      status: 'skipped',
      reason: 'Requires server-side configuration',
      pattern: 'cors-issue',
    };
  },
};

/**
 * All fix patterns
 */
export const allFixPatterns: FixPattern[] = [
  nullReferencePattern,
  domNotReadyPattern,
  brokenLinkPattern,
  missingFormIdPattern,
  pathCorrectionPattern,
  missingAltTextPattern,
  typoInUrlPattern,
  corsIssuePattern,
];

/**
 * Apply fixes to issues
 */
export async function applyFixes(
  issues: Issue[],
  config: any
): Promise<Fix[]> {
  const fixes: Fix[] = [];

  for (const issue of issues) {
    if (!issue.fixable) continue;

    // Find matching pattern
    for (const pattern of allFixPatterns) {
      if (pattern.detect(issue)) {
        const context: FixContext = {
          issue,
          config,
          cwd: process.cwd(),
        };

        const fix = await pattern.fix(context);
        if (fix) {
          fixes.push(fix);
        }
        break;
      }
    }
  }

  return fixes;
}
