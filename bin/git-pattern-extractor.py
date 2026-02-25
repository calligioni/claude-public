#!/usr/bin/env python3
"""
Git Pattern Extractor - Learn from successful code commits

Analyzes git history to extract:
1. Coding patterns from successful commits
2. Common file change combinations
3. Commit message patterns
4. Technology stack usage trends

Usage:
  python3 git-pattern-extractor.py /path/to/repo
  python3 git-pattern-extractor.py /path/to/repo --since="2 weeks ago"
  python3 git-pattern-extractor.py /path/to/repo --author="psm2"
  python3 git-pattern-extractor.py --all-projects  # Scan all known projects
"""

import json
import os
import re
import subprocess
import sys
import argparse
from datetime import datetime
from pathlib import Path
from collections import defaultdict
from typing import Optional, List

# Paths
MEMORY_DIR = Path.home() / ".claude-setup/memory"
EXTRACTED_DIR = MEMORY_DIR / "extracted"
CORE_MEMORY = MEMORY_DIR / "core-memory.json"

# Known project paths
PROJECT_PATHS = [
    Path("/Volumes/AI/Code/contably"),
    Path("/Volumes/AI/Code/agentcreator"),
    Path("/Volumes/AI/Code/claudia"),
    Path("/Volumes/AI/Code/botescola"),
    Path("/Volumes/AI/Code/cashflow"),
]


def run_git(repo: Path, *args) -> str:
    """Run a git command and return output."""
    try:
        result = subprocess.run(
            ["git", "-C", str(repo)] + list(args),
            capture_output=True,
            text=True,
            timeout=30,
        )
        return result.stdout
    except Exception as e:
        return ""


def get_commits(repo: Path, since: Optional[str] = None, author: Optional[str] = None) -> List[dict]:
    """Get commit history from a repo."""
    commits = []

    # Build git log command
    args = ["log", "--format=%H|%an|%ae|%at|%s", "--no-merges"]
    if since:
        args.append(f"--since={since}")
    if author:
        args.append(f"--author={author}")
    args.append("-100")  # Limit to last 100 commits

    output = run_git(repo, *args)
    if not output:
        return commits

    for line in output.strip().split("\n"):
        if not line or "|" not in line:
            continue
        parts = line.split("|", 4)
        if len(parts) < 5:
            continue

        commit_hash, author_name, author_email, timestamp, message = parts
        commits.append({
            "hash": commit_hash,
            "author": author_name,
            "email": author_email,
            "timestamp": datetime.fromtimestamp(int(timestamp)).isoformat(),
            "message": message,
            "repo": str(repo),
        })

    return commits


def get_commit_diff(repo: Path, commit_hash: str) -> dict:
    """Get diff statistics for a commit."""
    # Get file changes
    diff_stat = run_git(repo, "show", "--stat", "--format=", commit_hash)
    diff_files = run_git(repo, "show", "--name-only", "--format=", commit_hash)

    files_changed = [f.strip() for f in diff_files.strip().split("\n") if f.strip()]

    # Categorize files
    file_types = defaultdict(int)
    categories = defaultdict(int)

    for f in files_changed:
        ext = Path(f).suffix.lower()
        file_types[ext] += 1

        # Categorize by directory/purpose
        if "test" in f.lower() or "spec" in f.lower():
            categories["tests"] += 1
        elif "component" in f.lower() or "/ui/" in f.lower():
            categories["ui"] += 1
        elif "/api/" in f.lower() or "route" in f.lower():
            categories["api"] += 1
        elif "hook" in f.lower():
            categories["hooks"] += 1
        elif "util" in f.lower() or "lib" in f.lower():
            categories["utils"] += 1
        elif "config" in f.lower() or f.endswith(".json"):
            categories["config"] += 1

    return {
        "files": files_changed,
        "file_count": len(files_changed),
        "file_types": dict(file_types),
        "categories": dict(categories),
    }


def analyze_commit_message(message: str) -> dict:
    """Extract patterns from commit message."""
    analysis = {
        "type": "other",
        "scope": None,
        "breaking": False,
        "mentions_test": False,
        "mentions_fix": False,
        "mentions_feature": False,
    }

    # Conventional commit pattern
    match = re.match(r"^(\w+)(?:\(([^)]+)\))?(!)?:\s*(.+)", message)
    if match:
        analysis["type"] = match.group(1).lower()
        analysis["scope"] = match.group(2)
        analysis["breaking"] = bool(match.group(3))

    # Keyword detection
    message_lower = message.lower()
    analysis["mentions_test"] = any(w in message_lower for w in ["test", "spec", "coverage"])
    analysis["mentions_fix"] = any(w in message_lower for w in ["fix", "bug", "issue", "error"])
    analysis["mentions_feature"] = any(w in message_lower for w in ["feat", "add", "implement", "new"])

    return analysis


def extract_code_patterns(repo: Path, commit_hash: str) -> List[str]:
    """Extract code patterns from a commit's changes."""
    patterns = []

    # Get the actual diff
    diff = run_git(repo, "show", "--format=", commit_hash)

    # Pattern detection in diff
    pattern_regexes = {
        "early-returns": r"^\+\s*if\s*\([^)]+\)\s*return",
        "error-handling": r"^\+\s*(try\s*\{|catch\s*\(|throw\s+new)",
        "async-await": r"^\+\s*async\s+|^\+.*await\s+",
        "react-hooks": r"^\+.*use(State|Effect|Callback|Memo|Ref|Context)\s*\(",
        "typescript-types": r"^\+.*(interface\s+|type\s+\w+\s*=|:\s*\w+\[\]|:\s*Promise<)",
        "zod-validation": r"^\+.*z\.(object|string|number|array|enum)\(",
        "prisma-query": r"^\+.*prisma\.\w+\.(find|create|update|delete)",
        "supabase-query": r"^\+.*supabase\s*\.\s*(from|auth|storage)",
        "api-route": r"^\+.*(export\s+(async\s+)?function\s+(GET|POST|PUT|DELETE|PATCH))",
        "middleware": r"^\+.*NextResponse\.(next|redirect|rewrite|json)",
        "tailwind-classes": r'^\+.*className\s*=\s*["\'][^"\']*\b(flex|grid|p-|m-|text-|bg-|border-)',
    }

    for pattern_name, regex in pattern_regexes.items():
        if re.search(regex, diff, re.MULTILINE):
            patterns.append(pattern_name)

    return patterns


def analyze_repo(repo: Path, since: Optional[str] = None, author: Optional[str] = None) -> dict:
    """Analyze a repository for patterns."""
    repo_name = repo.name
    print(f"Analyzing {repo_name}...")

    commits = get_commits(repo, since=since, author=author)
    if not commits:
        print(f"  No commits found for {repo_name}")
        return None

    analysis = {
        "repo": str(repo),
        "repo_name": repo_name,
        "commit_count": len(commits),
        "date_range": {
            "earliest": commits[-1]["timestamp"] if commits else None,
            "latest": commits[0]["timestamp"] if commits else None,
        },
        "commit_types": defaultdict(int),
        "code_patterns": defaultdict(int),
        "file_type_frequency": defaultdict(int),
        "category_frequency": defaultdict(int),
        "authors": defaultdict(int),
    }

    for commit in commits[:50]:  # Limit detailed analysis to 50 most recent
        # Analyze commit message
        msg_analysis = analyze_commit_message(commit["message"])
        analysis["commit_types"][msg_analysis["type"]] += 1
        analysis["authors"][commit["author"]] += 1

        # Get diff details
        diff_details = get_commit_diff(repo, commit["hash"])
        for ext, count in diff_details["file_types"].items():
            analysis["file_type_frequency"][ext] += count
        for cat, count in diff_details["categories"].items():
            analysis["category_frequency"][cat] += count

        # Extract code patterns
        patterns = extract_code_patterns(repo, commit["hash"])
        for pattern in patterns:
            analysis["code_patterns"][pattern] += 1

    # Convert defaultdicts to regular dicts
    analysis["commit_types"] = dict(analysis["commit_types"])
    analysis["code_patterns"] = dict(analysis["code_patterns"])
    analysis["file_type_frequency"] = dict(analysis["file_type_frequency"])
    analysis["category_frequency"] = dict(analysis["category_frequency"])
    analysis["authors"] = dict(analysis["authors"])

    return analysis


def generate_memory_candidates(analyses: List[dict]) -> List[dict]:
    """Generate memory candidates from repo analyses."""
    candidates = []
    today = datetime.now().strftime("%Y-%m-%d")

    # Aggregate patterns across repos
    all_patterns = defaultdict(int)
    all_file_types = defaultdict(int)
    all_commit_types = defaultdict(int)

    for analysis in analyses:
        if not analysis:
            continue
        for pattern, count in analysis["code_patterns"].items():
            all_patterns[pattern] += count
        for ft, count in analysis["file_type_frequency"].items():
            all_file_types[ft] += count
        for ct, count in analysis["commit_types"].items():
            all_commit_types[ct] += count

    # Create pattern memories for frequently used patterns
    for pattern, count in all_patterns.items():
        if count >= 5:  # Used at least 5 times across repos
            candidates.append({
                "name": f"pattern:{pattern}-from-git",
                "entityType": "pattern",
                "observations": [
                    f"Discovered: {today}",
                    "Source: git-analysis",
                    f"Found in {count} commits across analyzed repos",
                    "Auto-extracted from git commit history",
                    f"Use count: {count}",
                ],
                "relevance_score": min(count // 2, 10),
            })

    # Create insights about commit patterns
    total_commits = sum(all_commit_types.values())
    if total_commits > 0:
        feat_ratio = all_commit_types.get("feat", 0) / total_commits
        fix_ratio = all_commit_types.get("fix", 0) / total_commits

        if feat_ratio > 0.3:
            candidates.append({
                "name": "insight:feature-focused-development",
                "entityType": "development-insight",
                "observations": [
                    f"Discovered: {today}",
                    "Source: git-analysis",
                    f"{feat_ratio:.0%} of commits are feature additions",
                    "Development style: Feature-focused",
                ],
                "relevance_score": 3,
            })

        if fix_ratio > 0.3:
            candidates.append({
                "name": "insight:maintenance-heavy-period",
                "entityType": "development-insight",
                "observations": [
                    f"Discovered: {today}",
                    "Source: git-analysis",
                    f"{fix_ratio:.0%} of commits are fixes",
                    "Consider: Review testing practices",
                ],
                "relevance_score": 4,
            })

    return candidates


def save_extractions(candidates: List[dict], analyses: List[dict], dry_run: bool = False):
    """Save extracted patterns."""
    EXTRACTED_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    output_file = EXTRACTED_DIR / f"git-extraction-{timestamp}.json"

    extraction = {
        "timestamp": datetime.now().isoformat(),
        "source": "git-pattern-extractor",
        "analyses": [a for a in analyses if a],
        "candidates": candidates,
        "status": "pending_import" if not dry_run else "dry_run",
    }

    if not dry_run:
        with open(output_file, "w") as f:
            json.dump(extraction, f, indent=2)
        print(f"\nSaved extraction to: {output_file}")
    else:
        print("\nDRY RUN - Would save extraction with these candidates:")
        for c in candidates:
            print(f"  - {c['name']} (score: {c['relevance_score']})")

    return output_file if not dry_run else None


def print_report(analyses: List[dict], candidates: List[dict]):
    """Print analysis report."""
    print("\n" + "=" * 60)
    print("GIT PATTERN EXTRACTION REPORT")
    print("=" * 60)

    for analysis in analyses:
        if not analysis:
            continue

        print(f"\n## {analysis['repo_name']}")
        print(f"  Commits analyzed: {analysis['commit_count']}")

        if analysis["code_patterns"]:
            print("  Code patterns:")
            for pattern, count in sorted(analysis["code_patterns"].items(), key=lambda x: -x[1])[:5]:
                print(f"    {pattern}: {count}")

        if analysis["commit_types"]:
            print("  Commit types:")
            for ct, count in sorted(analysis["commit_types"].items(), key=lambda x: -x[1])[:5]:
                print(f"    {ct}: {count}")

    print("\n## Memory Candidates")
    for candidate in candidates:
        print(f"  [{candidate['relevance_score']}] {candidate['name']}")

    print("\n" + "=" * 60)


def main():
    parser = argparse.ArgumentParser(description="Extract patterns from git history")
    parser.add_argument("repo", nargs="?", help="Repository path to analyze")
    parser.add_argument("--all-projects", action="store_true", help="Analyze all known projects")
    parser.add_argument("--since", type=str, default="2 weeks ago", help="Analyze commits since (default: 2 weeks ago)")
    parser.add_argument("--author", type=str, help="Filter by author")
    parser.add_argument("--dry-run", action="store_true", help="Preview without saving")
    parser.add_argument("--quiet", action="store_true", help="Minimal output")

    args = parser.parse_args()

    repos = []
    if args.all_projects:
        repos = [p for p in PROJECT_PATHS if p.exists()]
    elif args.repo:
        repos = [Path(args.repo)]
    else:
        # Default to current directory
        repos = [Path.cwd()]

    if not repos:
        print("No repositories found to analyze.")
        return

    # Analyze repos
    analyses = []
    for repo in repos:
        if not (repo / ".git").exists():
            if not args.quiet:
                print(f"Skipping {repo} - not a git repository")
            continue
        analysis = analyze_repo(repo, since=args.since, author=args.author)
        analyses.append(analysis)

    # Generate candidates
    candidates = generate_memory_candidates(analyses)

    # Report
    if not args.quiet:
        print_report(analyses, candidates)

    # Save
    if candidates:
        save_extractions(candidates, analyses, dry_run=args.dry_run)
    else:
        if not args.quiet:
            print("\nNo candidates generated from analysis.")


if __name__ == "__main__":
    main()
