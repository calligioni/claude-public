#!/usr/bin/env python3
"""
extract-body.py — extract a clean page body from a captured HTML file,
ready to drop into a SiteLayout slot.

Usage:
  python3 extract-body.py <html-file> <target-domain> [--mode jsx|set-html]

Output: prints the cleaned body to stdout.

Strips: <head>, <header>, <footer>, .loading-container, .transition-*,
        #menu-mobile, .menu-bg, Yoast schema, oEmbed, RSS, plugin chrome.
Rewrites: https://<target>/X → /X
          https://<target>/wp-content/X → /wp-content/X
Escapes (in --mode jsx): { and } in body text, NOT inside <style>/<script>.

The --mode flag controls escape strategy:
  jsx       → HTML-entity-escape literal { and } in body text
  set-html  → no escaping; dump into a JS template literal and render via
              <Fragment set:html={bodyHtml} /> (preferred — safer)
"""

import sys
import re
import argparse
from pathlib import Path


def extract_body(html: str) -> str:
    m = re.search(r'<body[^>]*>(.*?)</body>', html, re.DOTALL | re.IGNORECASE)
    if not m:
        raise ValueError("No <body> tag found")
    return m.group(1)


def strip_chrome(body: str) -> str:
    """Remove SiteLayout-provided chrome from the body."""
    patterns = [
        (r'<header[^>]*\bid="header_sticky".*?</header>', ''),
        (r'<footer[^>]*\bclass="footer_bottom.*?</footer>', ''),
        (r'<div[^>]*class="loading-container[^"]*".*?</div>\s*', ''),
        (r'<div[^>]*class="transition-progress[^"]*".*?</div>\s*</div>\s*', ''),
        (r'<div[^>]*class="transition-container[^"]*".*?</div>\s*</div>\s*', ''),
        (r'<div[^>]*\bid="menu-mobile".*?</div>\s*</div>\s*', ''),
        (r'<div[^>]*class="menu-bg".*?</div>\s*', ''),
        (r'<script[^>]*yoast-schema-graph[^<]*</script>', ''),
        (r'<style[^>]*\bid="wp-emoji[^<]*</style>', ''),
        (r'<style[^>]*\bid="classic-theme-styles[^<]*</style>', ''),
        (r'<style[^>]*\bid="global-styles-inline-css[^<]*</style>', ''),
        (r'<link[^>]*rel="alternate"[^>]*type="application/rss\+xml"[^>]*>', ''),
        (r'<link[^>]*rel="alternate"[^>]*application/json\+oembed[^>]*>', ''),
        (r'<link[^>]*rel="dns-prefetch"[^>]*>', ''),
    ]
    for pattern, replacement in patterns:
        body = re.sub(pattern, replacement, body, flags=re.DOTALL | re.IGNORECASE)
    return body


def rewrite_urls(body: str, target_domain: str) -> str:
    body = body.replace(f'https://{target_domain}/', '/')
    body = body.replace(f'http://{target_domain}/', '/')
    return body


def escape_jsx_braces(body: str) -> str:
    """Entity-escape { and } in body text — but leave them inside
    <style>...</style> and <script>...</script> blocks where they're
    CSS or JS syntax."""
    style_block_pattern = r'(<(?:style|script)[^>]*>.*?</(?:style|script)>)'
    parts = re.split(style_block_pattern, body, flags=re.DOTALL | re.IGNORECASE)
    out = []
    for i, part in enumerate(parts):
        if i % 2 == 1:
            out.append(part)
        else:
            part = part.replace('{', '&#123;').replace('}', '&#125;')
            out.append(part)
    return ''.join(out)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('html_file')
    parser.add_argument('target_domain')
    parser.add_argument('--mode', choices=['jsx', 'set-html'], default='set-html')
    args = parser.parse_args()

    html = Path(args.html_file).read_text(encoding='utf-8', errors='replace')

    body = extract_body(html)
    body = strip_chrome(body)
    body = rewrite_urls(body, args.target_domain)

    if args.mode == 'jsx':
        body = escape_jsx_braces(body)

    print(body)


if __name__ == '__main__':
    main()
