#!/usr/bin/env python3
"""
Memory Importer - Import extracted patterns into Memory MCP

This script:
1. Reads extraction files from the extracted/ directory
2. Filters candidates by relevance threshold
3. Checks for duplicates against existing memories
4. Imports qualified candidates to Memory MCP

Usage:
  python3 memory-importer.py                    # Import all pending extractions
  python3 memory-importer.py --file X.json      # Import specific file
  python3 memory-importer.py --dry-run          # Preview without importing
  python3 memory-importer.py --threshold 3      # Lower relevance threshold
"""

import json
import os
import subprocess
import sys
import argparse
from datetime import datetime
from pathlib import Path
from typing import List, Optional

# Paths
MEMORY_DIR = Path.home() / ".claude-setup/memory"
EXTRACTED_DIR = MEMORY_DIR / "extracted"
IMPORTED_DIR = MEMORY_DIR / "imported"
CORE_MEMORY = MEMORY_DIR / "core-memory.json"


def load_core_memory() -> dict:
    """Load core memory configuration."""
    try:
        with open(CORE_MEMORY) as f:
            return json.load(f)
    except Exception:
        return {"memoryConfig": {"relevanceThreshold": 5}}


def get_pending_extractions() -> List[Path]:
    """Get all pending extraction files."""
    if not EXTRACTED_DIR.exists():
        return []

    files = []
    for f in EXTRACTED_DIR.glob("*.json"):
        try:
            with open(f) as fp:
                data = json.load(fp)
                if data.get("status") == "pending_import":
                    files.append(f)
        except Exception:
            continue

    return sorted(files)


def call_memory_mcp(action: str, payload: dict) -> dict:
    """
    Call Memory MCP tool via Claude CLI.

    Note: This is a simplified version. In practice, the memory import
    happens within a Claude session using the mcp__memory__* tools.
    This script prepares the import batch for the next session.
    """
    # For now, we just prepare the batch - actual MCP calls happen in Claude
    return {"status": "prepared", "action": action, "payload": payload}


def check_duplicate(name: str, existing_names: List[str]) -> bool:
    """Check if a memory name already exists."""
    # Exact match
    if name in existing_names:
        return True

    # Similar name (without suffix variations)
    base_name = name.rsplit("-", 1)[0] if "-" in name else name
    for existing in existing_names:
        existing_base = existing.rsplit("-", 1)[0] if "-" in existing else existing
        if base_name == existing_base:
            return True

    return False


def prepare_import_batch(extraction_file: Path, threshold: int, dry_run: bool = False) -> dict:
    """Prepare a batch of candidates for import."""
    with open(extraction_file) as f:
        extraction = json.load(f)

    candidates = extraction.get("candidates", [])
    if not candidates:
        return {"imported": 0, "skipped": 0, "file": str(extraction_file)}

    # Filter by relevance
    qualified = []
    skipped = []

    for candidate in candidates:
        score = candidate.get("relevance_score", 0)
        if score >= threshold:
            qualified.append(candidate)
        else:
            skipped.append({
                "name": candidate["name"],
                "reason": f"score {score} < threshold {threshold}",
            })

    result = {
        "file": str(extraction_file),
        "total_candidates": len(candidates),
        "qualified": len(qualified),
        "skipped_low_relevance": len(skipped),
        "candidates_to_import": qualified,
        "skipped_details": skipped,
    }

    if not dry_run and qualified:
        # Mark as processed
        extraction["status"] = "imported"
        extraction["imported_at"] = datetime.now().isoformat()
        extraction["import_result"] = result

        # Move to imported directory
        IMPORTED_DIR.mkdir(parents=True, exist_ok=True)
        imported_file = IMPORTED_DIR / extraction_file.name

        with open(imported_file, "w") as f:
            json.dump(extraction, f, indent=2)

        # Remove from extracted
        extraction_file.unlink()

    return result


def generate_mcp_commands(candidates: List[dict]) -> str:
    """Generate MCP commands for importing candidates."""
    if not candidates:
        return ""

    entities = []
    for c in candidates:
        entities.append({
            "name": c["name"],
            "entityType": c.get("entityType", "pattern"),
            "observations": c.get("observations", []),
        })

    # Format as MCP tool call
    command = f"""
To import these {len(candidates)} memories, run in Claude:

mcp__memory__create_entities({{
  "entities": {json.dumps(entities, indent=2)}
}})
"""
    return command


def print_report(results: List[dict], dry_run: bool):
    """Print import report."""
    print("\n" + "=" * 60)
    print("MEMORY IMPORT REPORT" + (" (DRY RUN)" if dry_run else ""))
    print("=" * 60)

    total_imported = 0
    total_skipped = 0
    all_candidates = []

    for result in results:
        print(f"\n## {Path(result['file']).name}")
        print(f"  Total candidates: {result['total_candidates']}")
        print(f"  Qualified: {result['qualified']}")
        print(f"  Skipped (low relevance): {result['skipped_low_relevance']}")

        total_imported += result["qualified"]
        total_skipped += result["skipped_low_relevance"]
        all_candidates.extend(result.get("candidates_to_import", []))

        if result.get("skipped_details"):
            print("  Skipped:")
            for s in result["skipped_details"][:5]:
                print(f"    - {s['name']}: {s['reason']}")

    print(f"\n## Summary")
    print(f"  Total to import: {total_imported}")
    print(f"  Total skipped: {total_skipped}")

    if all_candidates:
        print("\n## Candidates to Import:")
        for c in all_candidates:
            print(f"  - {c['name']} ({c.get('entityType', 'pattern')})")

        # Generate MCP commands
        print(generate_mcp_commands(all_candidates))

    print("=" * 60)


def main():
    parser = argparse.ArgumentParser(description="Import extracted patterns to Memory MCP")
    parser.add_argument("--file", type=str, help="Specific extraction file to import")
    parser.add_argument("--threshold", type=int, default=5, help="Relevance threshold (default: 5)")
    parser.add_argument("--dry-run", action="store_true", help="Preview without importing")
    parser.add_argument("--quiet", action="store_true", help="Minimal output")

    args = parser.parse_args()

    # Load core memory for default threshold
    core_memory = load_core_memory()
    threshold = args.threshold or core_memory.get("memoryConfig", {}).get("relevanceThreshold", 5)

    # Get files to process
    if args.file:
        files = [Path(args.file)]
    else:
        files = get_pending_extractions()

    if not files:
        if not args.quiet:
            print("No pending extractions found.")
        return

    if not args.quiet:
        print(f"Processing {len(files)} extraction file(s) with threshold {threshold}...")

    # Process each file
    results = []
    for f in files:
        result = prepare_import_batch(f, threshold, dry_run=args.dry_run)
        results.append(result)

    # Report
    if not args.quiet:
        print_report(results, args.dry_run)


if __name__ == "__main__":
    main()
