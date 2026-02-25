#!/usr/bin/env python3
"""
Session Analyzer - Extract patterns from Claude Code session logs

This script analyzes:
1. Learning log (learning-log.jsonl) - captured during sessions
2. Session logs (sessions/*.json) - created at session end
3. Extracts patterns, mistakes, and insights for memory storage

Usage:
  python3 session-analyzer.py              # Analyze all unprocessed
  python3 session-analyzer.py --dry-run    # Preview without saving
  python3 session-analyzer.py --last-24h   # Only last 24 hours
  python3 session-analyzer.py --project X  # Filter by project
"""

import json
import os
import sys
import argparse
from datetime import datetime, timedelta
from pathlib import Path
from collections import defaultdict
from typing import Optional

# Paths
MEMORY_DIR = Path.home() / ".claude-setup/memory"
LEARNING_LOG = MEMORY_DIR / "learning-log.jsonl"
SESSIONS_DIR = MEMORY_DIR / "sessions"
EXTRACTED_DIR = MEMORY_DIR / "extracted"
CORE_MEMORY = MEMORY_DIR / "core-memory.json"


def load_core_memory() -> dict:
    """Load core memory for context."""
    try:
        with open(CORE_MEMORY) as f:
            return json.load(f)
    except Exception:
        return {}


def load_learning_log(since: Optional[datetime] = None, project: Optional[str] = None) -> list:
    """Load entries from the learning log."""
    entries = []
    if not LEARNING_LOG.exists():
        return entries

    with open(LEARNING_LOG) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)

                # Filter by date if specified
                if since:
                    entry_date = datetime.fromisoformat(entry["timestamp"].replace("Z", "+00:00"))
                    if entry_date < since:
                        continue

                # Filter by project if specified
                if project and entry.get("project", "").lower() != project.lower():
                    continue

                # Skip already processed
                if entry.get("processed", False):
                    continue

                entries.append(entry)
            except json.JSONDecodeError:
                continue

    return entries


def analyze_patterns(entries: list) -> dict:
    """Analyze entries to find patterns."""
    analysis = {
        "pattern_frequency": defaultdict(int),
        "language_usage": defaultdict(int),
        "project_activity": defaultdict(int),
        "tool_usage": defaultdict(int),
        "success_rate": {"success": 0, "failure": 0},
        "file_types": defaultdict(int),
        "common_sequences": [],
        "potential_patterns": [],
        "potential_mistakes": [],
    }

    # Aggregate statistics
    for entry in entries:
        # Pattern frequency
        for pattern in entry.get("detectedPatterns", []):
            analysis["pattern_frequency"][pattern] += 1

        # Language usage
        lang = entry.get("language", "Unknown")
        if lang:
            analysis["language_usage"][lang] += 1

        # Project activity
        project = entry.get("project", "Unknown")
        analysis["project_activity"][project] += 1

        # Tool usage
        tool = entry.get("tool", "Unknown")
        analysis["tool_usage"][tool] += 1

        # Success rate
        if entry.get("success", True):
            analysis["success_rate"]["success"] += 1
        else:
            analysis["success_rate"]["failure"] += 1

        # File types
        file_path = entry.get("filePath", "")
        if file_path:
            ext = Path(file_path).suffix
            if ext:
                analysis["file_types"][ext] += 1

    # Identify potential new patterns (frequently used combinations)
    if analysis["pattern_frequency"]:
        top_patterns = sorted(
            analysis["pattern_frequency"].items(),
            key=lambda x: x[1],
            reverse=True
        )[:5]

        for pattern, count in top_patterns:
            if count >= 3:  # Used at least 3 times
                analysis["potential_patterns"].append({
                    "name": f"pattern:{pattern}",
                    "usage_count": count,
                    "confidence": min(count / 10, 1.0),  # Cap at 100%
                })

    # Identify potential mistakes (failures)
    failure_rate = (
        analysis["success_rate"]["failure"] /
        max(analysis["success_rate"]["success"] + analysis["success_rate"]["failure"], 1)
    )

    if failure_rate > 0.2:  # More than 20% failure rate
        analysis["potential_mistakes"].append({
            "type": "high-failure-rate",
            "rate": failure_rate,
            "recommendation": "Review recent failures for common causes",
        })

    return analysis


def generate_memory_candidates(analysis: dict, entries: list) -> list:
    """Generate memory entities from analysis."""
    candidates = []
    today = datetime.now().strftime("%Y-%m-%d")

    # Create pattern entities for frequently detected patterns
    for pattern_info in analysis["potential_patterns"]:
        if pattern_info["confidence"] >= 0.3:  # At least 30% confidence
            candidates.append({
                "name": pattern_info["name"],
                "entityType": "pattern",
                "observations": [
                    f"Discovered: {today}",
                    f"Source: session-analysis",
                    f"Usage count: {pattern_info['usage_count']}",
                    f"Confidence: {pattern_info['confidence']:.0%}",
                    "Auto-detected from session analysis",
                ],
                "relevance_score": min(pattern_info["usage_count"], 10),
            })

    # Create tech insights for heavily used languages/tools
    for lang, count in analysis["language_usage"].items():
        if count >= 10 and lang not in ["Unknown", "Other"]:
            candidates.append({
                "name": f"tech-insight:{lang.lower()}-heavy-usage",
                "entityType": "tech-insight",
                "observations": [
                    f"Discovered: {today}",
                    f"Source: session-analysis",
                    f"{lang} is a primary language in workflow",
                    f"Used in {count} file changes this period",
                ],
                "relevance_score": min(count // 5, 8),
            })

    # Create project activity insights
    for project, count in analysis["project_activity"].items():
        if count >= 5 and project != "Unknown":
            candidates.append({
                "name": f"project-activity:{project.lower().replace(' ', '-')}",
                "entityType": "project-activity",
                "observations": [
                    f"Date: {today}",
                    f"Activity count: {count}",
                    f"Active development on {project}",
                ],
                "relevance_score": 3,  # Lower priority
            })

    return candidates


def calculate_relevance(candidate: dict, core_memory: dict) -> dict:
    """Calculate relevance score for a memory candidate."""
    score = candidate.get("relevance_score", 0)
    reasons = []

    # Check if similar exists in core memory
    patterns = core_memory.get("stablePatterns", {})
    if any(candidate["name"].replace("pattern:", "") in p for p in patterns):
        score -= 2
        reasons.append("Similar pattern in core memory (-2)")

    # Boost if aligns with preferences
    preferences = core_memory.get("preferences", {})
    if "typescript" in candidate["name"].lower() and "TypeScript" in str(preferences):
        score += 1
        reasons.append("Aligns with TypeScript preference (+1)")

    threshold = core_memory.get("memoryConfig", {}).get("relevanceThreshold", 5)

    return {
        "score": score,
        "reasons": reasons,
        "should_save": score >= threshold,
        "threshold": threshold,
    }


def save_extractions(candidates: list, dry_run: bool = False):
    """Save extracted patterns to file for later memory import."""
    EXTRACTED_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    output_file = EXTRACTED_DIR / f"extraction-{timestamp}.json"

    extraction = {
        "timestamp": datetime.now().isoformat(),
        "candidates": candidates,
        "status": "pending_import" if not dry_run else "dry_run",
    }

    if not dry_run:
        with open(output_file, "w") as f:
            json.dump(extraction, f, indent=2)
        print(f"Saved extraction to: {output_file}")
    else:
        print("DRY RUN - Would save:")
        print(json.dumps(extraction, indent=2))

    return output_file if not dry_run else None


def mark_entries_processed(entries: list):
    """Mark learning log entries as processed."""
    if not LEARNING_LOG.exists():
        return

    # Read all entries
    all_entries = []
    with open(LEARNING_LOG) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                # Mark if in our processed list
                if any(e["timestamp"] == entry["timestamp"] for e in entries):
                    entry["processed"] = True
                all_entries.append(entry)
            except json.JSONDecodeError:
                continue

    # Write back
    with open(LEARNING_LOG, "w") as f:
        for entry in all_entries:
            f.write(json.dumps(entry) + "\n")


def print_analysis_report(analysis: dict, candidates: list, core_memory: dict):
    """Print analysis report."""
    print("\n" + "=" * 60)
    print("SESSION ANALYSIS REPORT")
    print("=" * 60)

    print("\n## Pattern Frequency")
    for pattern, count in sorted(analysis["pattern_frequency"].items(), key=lambda x: -x[1])[:10]:
        print(f"  {pattern}: {count}")

    print("\n## Language Usage")
    for lang, count in sorted(analysis["language_usage"].items(), key=lambda x: -x[1])[:5]:
        print(f"  {lang}: {count}")

    print("\n## Project Activity")
    for project, count in sorted(analysis["project_activity"].items(), key=lambda x: -x[1]):
        print(f"  {project}: {count}")

    print("\n## Success Rate")
    total = analysis["success_rate"]["success"] + analysis["success_rate"]["failure"]
    if total > 0:
        rate = analysis["success_rate"]["success"] / total * 100
        print(f"  {rate:.1f}% success ({analysis['success_rate']['success']}/{total})")

    print("\n## Memory Candidates")
    for candidate in candidates:
        relevance = calculate_relevance(candidate, core_memory)
        status = "SAVE" if relevance["should_save"] else "SKIP"
        print(f"  [{status}] {candidate['name']} (score: {relevance['score']}/{relevance['threshold']})")

    print("\n" + "=" * 60)


def main():
    parser = argparse.ArgumentParser(description="Analyze Claude Code sessions for pattern extraction")
    parser.add_argument("--dry-run", action="store_true", help="Preview without saving")
    parser.add_argument("--last-24h", action="store_true", help="Only analyze last 24 hours")
    parser.add_argument("--project", type=str, help="Filter by project name")
    parser.add_argument("--quiet", action="store_true", help="Minimal output")

    args = parser.parse_args()

    # Determine time filter
    since = None
    if args.last_24h:
        since = datetime.now(tz=None) - timedelta(hours=24)

    # Load data
    core_memory = load_core_memory()
    entries = load_learning_log(since=since, project=args.project)

    if not entries:
        if not args.quiet:
            print("No unprocessed entries found.")
        return

    if not args.quiet:
        print(f"Analyzing {len(entries)} entries...")

    # Analyze
    analysis = analyze_patterns(entries)
    candidates = generate_memory_candidates(analysis, entries)

    # Filter by relevance
    filtered_candidates = []
    for candidate in candidates:
        relevance = calculate_relevance(candidate, core_memory)
        if relevance["should_save"]:
            candidate["relevance"] = relevance
            filtered_candidates.append(candidate)

    # Report
    if not args.quiet:
        print_analysis_report(analysis, candidates, core_memory)

    # Save
    if filtered_candidates:
        save_extractions(filtered_candidates, dry_run=args.dry_run)

        if not args.dry_run:
            mark_entries_processed(entries)
            if not args.quiet:
                print(f"\nMarked {len(entries)} entries as processed.")
    else:
        if not args.quiet:
            print("\nNo candidates met relevance threshold.")


if __name__ == "__main__":
    main()
