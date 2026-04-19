#!/usr/bin/env python3
"""
Generate a human-readable markdown report from analysis JSON
"""

import json
import argparse
from pathlib import Path
from datetime import datetime


def format_size(bytes_size):
    """Format bytes to human readable size"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes_size < 1024.0:
            return f"{bytes_size:.1f} {unit}"
        bytes_size /= 1024.0
    return f"{bytes_size:.1f} TB"


def format_date(iso_date):
    """Format ISO date to readable format"""
    try:
        dt = datetime.fromisoformat(iso_date)
        return dt.strftime('%Y-%m-%d')
    except:
        return iso_date


def generate_report(findings, output_path='cleanup_report.md'):
    """Generate markdown report from findings"""
    
    summary = findings.get('summary', {})
    
    report = []
    report.append("# Codebase Cleanup Report")
    report.append(f"\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append(f"\nProject: `{summary.get('project_root', 'Unknown')}`")
    report.append("\n---\n")
    
    # Summary section
    report.append("## Summary")
    report.append(f"- **Total files analyzed**: {summary.get('total_files', 0):,}")
    report.append(f"- **Orphaned files**: {summary.get('orphaned_count', 0)}")
    report.append(f"- **Unnecessary files**: {summary.get('unnecessary_count', 0)}")
    report.append(f"- **Empty/near-empty files**: {summary.get('empty_count', 0)}")
    report.append(f"- **Duplicate file sets**: {summary.get('duplicate_sets', 0)}")
    report.append(f"- **Old files (1+ year)**: {summary.get('old_files_count', 0)}")
    report.append(f"- **Potential space savings**: {summary.get('potential_space_savings_mb', 0):.2f} MB")
    
    total_issues = (summary.get('orphaned_count', 0) + 
                   summary.get('unnecessary_count', 0) + 
                   summary.get('empty_count', 0))
    
    if total_issues == 0:
        report.append("\n🎉 **Great news!** Your codebase looks clean with no obvious issues found.")
        risk = "None"
    elif total_issues < 10:
        risk = "Low"
    elif total_issues < 50:
        risk = "Medium"
    else:
        risk = "High"
    
    report.append(f"- **Risk level**: {risk}")
    report.append("\n---\n")
    
    # Orphaned files
    orphaned = findings.get('orphaned_files', [])
    if orphaned:
        report.append("## 1. Orphaned Files (High Confidence)")
        report.append("\nThese files are not imported or referenced anywhere in the codebase:\n")
        
        for file_info in sorted(orphaned, key=lambda x: x.get('lines', 0), reverse=True)[:20]:
            path = file_info['path']
            lines = file_info.get('lines', 0)
            size = format_size(file_info.get('size', 0))
            modified = format_date(file_info.get('modified', 'unknown'))
            report.append(f"- `{path}` ({lines} lines, {size}, modified {modified})")
        
        if len(orphaned) > 20:
            report.append(f"\n*... and {len(orphaned) - 20} more orphaned files*")
        
        report.append("\n---\n")
    
    # Unnecessary files
    unnecessary = findings.get('unnecessary_files', [])
    if unnecessary:
        report.append("## 2. Temporary/Backup Files (High Confidence)")
        report.append("\nThese are temporary, backup, or system files that are safe to delete:\n")
        
        # Group by type
        by_type = {}
        for file_info in unnecessary:
            ext = Path(file_info['path']).suffix or Path(file_info['path']).name
            if ext not in by_type:
                by_type[ext] = []
            by_type[ext].append(file_info)
        
        for ext, files in sorted(by_type.items()):
            total_size = sum(f.get('size', 0) for f in files)
            report.append(f"\n### {ext} files ({len(files)} files, {format_size(total_size)})")
            for file_info in files[:10]:
                path = file_info['path']
                size = format_size(file_info.get('size', 0))
                report.append(f"- `{path}` ({size})")
            if len(files) > 10:
                report.append(f"  *... and {len(files) - 10} more*")
        
        report.append("\n---\n")
    
    # Empty files
    empty = findings.get('empty_files', [])
    if empty:
        report.append("## 3. Empty or Near-Empty Files (Medium Confidence)")
        report.append("\nThese files have 5 or fewer lines:\n")
        
        for file_info in sorted(empty, key=lambda x: x.get('lines', 0))[:15]:
            path = file_info['path']
            lines = file_info.get('lines', 0)
            report.append(f"- `{path}` ({lines} lines)")
        
        if len(empty) > 15:
            report.append(f"\n*... and {len(empty) - 15} more empty files*")
        
        report.append("\n---\n")
    
    # Duplicate files
    duplicates = findings.get('duplicate_files', [])
    if duplicates:
        report.append("## 4. Duplicate Files (Medium Confidence)")
        report.append("\nThese files have identical content:\n")
        
        for dup_group in duplicates[:10]:
            files = dup_group['files']
            size = format_size(dup_group.get('size', 0))
            report.append(f"\n### Duplicate set ({size} each):")
            for file_path in files:
                report.append(f"- `{file_path}`")
        
        if len(duplicates) > 10:
            report.append(f"\n*... and {len(duplicates) - 10} more duplicate sets*")
        
        report.append("\n---\n")
    
    # Old files
    old_files = findings.get('old_files', [])
    if old_files:
        report.append("## 5. Old Files (Low Confidence - Review Required)")
        report.append("\nThese files haven't been modified in over a year:\n")
        
        for file_info in sorted(old_files, key=lambda x: x.get('modified', ''))[:15]:
            path = file_info['path']
            modified = format_date(file_info.get('modified', 'unknown'))
            size = format_size(file_info.get('size', 0))
            report.append(f"- `{path}` (last modified {modified}, {size})")
        
        if len(old_files) > 15:
            report.append(f"\n*... and {len(old_files) - 15} more old files*")
        
        report.append("\n---\n")
    
    # Recommendations
    report.append("## Recommendations\n")
    
    if unnecessary or empty:
        report.append("### ✅ Safe to Delete (High Confidence)\n")
        if unnecessary:
            report.append(f"- **{len(unnecessary)} temporary/backup files** - These can be safely deleted")
        if empty:
            report.append(f"- **{len(empty)} empty files** - Unless they serve a specific purpose, these can be removed")
    
    if orphaned:
        report.append("\n### ⚠️  Review Before Deleting (Medium Confidence)\n")
        report.append(f"- **{len(orphaned)} orphaned source files** - Verify these aren't dynamically imported")
    
    if duplicates or old_files:
        report.append("\n### 🔍 Manual Review Required (Low Confidence)\n")
        if duplicates:
            report.append(f"- **{len(duplicates)} duplicate file sets** - Decide which copies to keep")
        if old_files:
            report.append(f"- **{len(old_files)} old files** - Determine if still needed")
    
    report.append("\n---\n")
    
    # Next steps
    report.append("## Next Steps\n")
    report.append("1. **Review this report** - Understand what files are flagged and why")
    report.append("2. **Create a backup** - Run `git commit` or create a backup branch")
    report.append("3. **Start with high-confidence deletions** - Begin with temporary/backup files")
    report.append("4. **Test after each deletion batch** - Verify your application still works")
    report.append("5. **Iterate** - Move to medium and low confidence files gradually")
    
    report.append("\n---\n")
    
    # Entry points reminder
    entry_points = findings.get('entry_points', [])
    if entry_points:
        report.append("## Protected Entry Points\n")
        report.append("These files are marked as entry points and will NOT be suggested for deletion:\n")
        for ep in sorted(entry_points)[:10]:
            report.append(f"- `{ep}`")
        if len(entry_points) > 10:
            report.append(f"\n*... and {len(entry_points) - 10} more entry points*")
    
    # Write report
    with open(output_path, 'w') as f:
        f.write('\n'.join(report))
    
    return output_path


def main():
    parser = argparse.ArgumentParser(description='Generate markdown report from analysis JSON')
    parser.add_argument('json_file', help='Path to the analysis JSON file')
    parser.add_argument('--output', default='cleanup_report.md', help='Output markdown file')
    
    args = parser.parse_args()
    
    # Load findings
    with open(args.json_file, 'r') as f:
        findings = json.load(f)
    
    # Generate report
    output = generate_report(findings, args.output)
    
    print(f"\nMarkdown report generated: {output}")
    print(f"View it with: cat {output}")


if __name__ == '__main__':
    main()
