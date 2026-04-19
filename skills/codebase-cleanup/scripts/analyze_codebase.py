#!/usr/bin/env python3
"""
Codebase Analysis Script
Analyzes a codebase to identify unused, unnecessary, or redundant files.
"""

import os
import re
import json
import argparse
from pathlib import Path
from collections import defaultdict
from datetime import datetime
import hashlib

class CodebaseAnalyzer:
    def __init__(self, root_path, exclude_dirs=None):
        self.root_path = Path(root_path).resolve()
        self.exclude_dirs = set(exclude_dirs or [
            'node_modules', '.git', 'dist', 'build', '__pycache__',
            '.venv', 'venv', 'env', 'target', '.next', '.cache'
        ])
        
        # Results storage
        self.all_files = []
        self.import_graph = defaultdict(set)  # file -> set of files it imports
        self.imported_by = defaultdict(set)   # file -> set of files that import it
        self.entry_points = set()
        self.file_metadata = {}
        
        # Detection patterns
        self.patterns = self._initialize_patterns()
        
    def _initialize_patterns(self):
        """Initialize regex patterns for different languages"""
        return {
            'javascript': {
                'extensions': ['.js', '.jsx', '.ts', '.tsx', '.mjs'],
                'import_patterns': [
                    r'import\s+(?:.*?from\s+)?[\'"](.+?)[\'"]',
                    r'require\([\'"](.+?)[\'"]\)',
                    r'import\([\'"](.+?)[\'"]\)',
                ],
                'entry_indicators': ['index.js', 'main.js', 'app.js', 'server.js']
            },
            'python': {
                'extensions': ['.py'],
                'import_patterns': [
                    r'from\s+([\w.]+)\s+import',
                    r'import\s+([\w.]+)',
                ],
                'entry_indicators': ['__main__.py', 'main.py', 'app.py', 'manage.py']
            },
            'unnecessary': {
                'extensions': ['.bak', '.backup', '.tmp', '.temp', '.swp', '.log'],
                'filenames': ['.DS_Store', 'Thumbs.db', 'desktop.ini', '.~lock.*']
            }
        }
    
    def analyze(self):
        """Main analysis entry point"""
        print(f"Analyzing codebase at: {self.root_path}")
        print("=" * 60)
        
        # Step 1: Scan all files
        self._scan_files()
        
        # Step 2: Detect project type
        project_type = self._detect_project_type()
        print(f"\nProject type detected: {project_type}")
        
        # Step 3: Build import graph
        self._build_import_graph(project_type)
        
        # Step 4: Identify entry points
        self._identify_entry_points(project_type)
        
        # Step 5: Analyze file metadata
        self._analyze_file_metadata()
        
        # Step 6: Generate findings
        findings = self._generate_findings()
        
        return findings
    
    def _scan_files(self):
        """Recursively scan all files in the project"""
        print("Scanning files...")
        
        for root, dirs, files in os.walk(self.root_path):
            # Exclude specified directories
            dirs[:] = [d for d in dirs if d not in self.exclude_dirs and not d.startswith('.')]
            
            for file in files:
                if file.startswith('.') and file not in ['.gitignore', '.env.example']:
                    continue
                    
                file_path = Path(root) / file
                rel_path = file_path.relative_to(self.root_path)
                self.all_files.append(str(rel_path))
        
        print(f"Found {len(self.all_files)} files")
    
    def _detect_project_type(self):
        """Detect the primary project type"""
        markers = {
            'node': ['package.json', 'yarn.lock', 'package-lock.json'],
            'python': ['requirements.txt', 'setup.py', 'pyproject.toml', 'Pipfile'],
            'java': ['pom.xml', 'build.gradle', 'settings.gradle'],
            'rust': ['Cargo.toml'],
            'go': ['go.mod'],
            'ruby': ['Gemfile'],
            'php': ['composer.json']
        }
        
        for proj_type, marker_files in markers.items():
            for marker in marker_files:
                if (self.root_path / marker).exists():
                    return proj_type
        
        return 'unknown'
    
    def _build_import_graph(self, project_type):
        """Build graph of file dependencies"""
        print("Building import graph...")
        
        patterns = self.patterns.get('javascript', {}) if project_type == 'node' else \
                  self.patterns.get('python', {}) if project_type == 'python' else {}
        
        if not patterns:
            print("Warning: No import patterns for this project type")
            return
        
        extensions = patterns.get('extensions', [])
        import_regexes = [re.compile(p) for p in patterns.get('import_patterns', [])]
        
        for file_rel in self.all_files:
            file_path = self.root_path / file_rel
            
            # Only analyze source files
            if not any(str(file_path).endswith(ext) for ext in extensions):
                continue
            
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    
                for regex in import_regexes:
                    matches = regex.findall(content)
                    for match in matches:
                        # Resolve import to actual file
                        imported_file = self._resolve_import(match, file_path, project_type)
                        if imported_file:
                            self.import_graph[file_rel].add(imported_file)
                            self.imported_by[imported_file].add(file_rel)
            except Exception as e:
                print(f"Warning: Could not analyze {file_rel}: {e}")
    
    def _resolve_import(self, import_path, from_file, project_type):
        """Resolve an import statement to an actual file path"""
        # Skip external packages
        if not import_path.startswith('.') and not import_path.startswith('/'):
            return None
        
        # Get directory of importing file
        base_dir = from_file.parent
        
        # Try to resolve the path
        if import_path.startswith('.'):
            resolved = (base_dir / import_path).resolve()
        else:
            resolved = Path(import_path)
        
        # Try different extensions
        extensions = ['.js', '.ts', '.jsx', '.tsx', '.py'] if project_type in ['node', 'python'] else []
        
        for ext in ['', *extensions]:
            test_path = resolved.with_suffix(ext) if ext else resolved
            
            # Try as file
            if test_path.exists() and test_path.is_file():
                try:
                    return str(test_path.relative_to(self.root_path))
                except ValueError:
                    continue
            
            # Try as directory with index
            if test_path.is_dir():
                for index_name in ['index.js', 'index.ts', '__init__.py']:
                    index_path = test_path / index_name
                    if index_path.exists():
                        try:
                            return str(index_path.relative_to(self.root_path))
                        except ValueError:
                            continue
        
        return None
    
    def _identify_entry_points(self, project_type):
        """Identify entry point files that should never be deleted"""
        print("Identifying entry points...")
        
        # Common entry point indicators
        entry_indicators = [
            'index.', 'main.', 'app.', 'server.',
            '__main__.py', 'manage.py',
            'webpack.config.', 'vite.config.',
            'tsconfig.json', 'package.json', 'setup.py'
        ]
        
        for file in self.all_files:
            filename = Path(file).name
            if any(filename.startswith(ind) or filename == ind for ind in entry_indicators):
                self.entry_points.add(file)
        
        # Files in src/ or public/ root are often entry points
        for file in self.all_files:
            parts = Path(file).parts
            if len(parts) == 2 and parts[0] in ['src', 'public', 'app']:
                self.entry_points.add(file)
    
    def _analyze_file_metadata(self):
        """Analyze metadata for each file"""
        print("Analyzing file metadata...")
        
        for file_rel in self.all_files:
            file_path = self.root_path / file_rel
            
            try:
                stat = file_path.stat()
                
                # Get file size
                size = stat.st_size
                
                # Get last modified time
                mtime = datetime.fromtimestamp(stat.st_mtime)
                
                # Count lines for text files
                lines = 0
                if file_path.suffix in ['.js', '.jsx', '.ts', '.tsx', '.py', '.java', '.go', '.rs', '.rb']:
                    try:
                        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                            lines = sum(1 for line in f)
                    except:
                        lines = -1
                
                # Calculate file hash for duplicate detection
                file_hash = None
                if size < 1_000_000:  # Only hash files < 1MB
                    try:
                        with open(file_path, 'rb') as f:
                            file_hash = hashlib.md5(f.read()).hexdigest()
                    except:
                        pass
                
                self.file_metadata[file_rel] = {
                    'size': size,
                    'modified': mtime.isoformat(),
                    'lines': lines,
                    'hash': file_hash
                }
            except Exception as e:
                print(f"Warning: Could not analyze metadata for {file_rel}: {e}")
    
    def _generate_findings(self):
        """Generate findings from analysis"""
        print("\nGenerating findings...")
        
        findings = {
            'summary': {
                'total_files': len(self.all_files),
                'analyzed_date': datetime.now().isoformat(),
                'project_root': str(self.root_path)
            },
            'orphaned_files': [],
            'unnecessary_files': [],
            'empty_files': [],
            'duplicate_files': [],
            'old_files': [],
            'entry_points': list(self.entry_points)
        }
        
        # Find orphaned files (not imported by anyone and not entry points)
        for file in self.all_files:
            if file not in self.entry_points and file not in self.imported_by:
                # Check if it's a source file that should be imported
                if Path(file).suffix in ['.js', '.jsx', '.ts', '.tsx', '.py']:
                    metadata = self.file_metadata.get(file, {})
                    findings['orphaned_files'].append({
                        'path': file,
                        'lines': metadata.get('lines', 0),
                        'size': metadata.get('size', 0),
                        'modified': metadata.get('modified', 'unknown')
                    })
        
        # Find unnecessary files (temp, backup, etc.)
        unnecessary_patterns = self.patterns['unnecessary']
        for file in self.all_files:
            path = Path(file)
            if (path.suffix in unnecessary_patterns['extensions'] or
                any(re.match(pattern, path.name) for pattern in unnecessary_patterns['filenames'])):
                metadata = self.file_metadata.get(file, {})
                findings['unnecessary_files'].append({
                    'path': file,
                    'size': metadata.get('size', 0),
                    'modified': metadata.get('modified', 'unknown')
                })
        
        # Find empty or near-empty files
        for file, metadata in self.file_metadata.items():
            lines = metadata.get('lines', -1)
            if 0 <= lines <= 5:
                findings['empty_files'].append({
                    'path': file,
                    'lines': lines,
                    'size': metadata.get('size', 0)
                })
        
        # Find duplicate files
        hash_to_files = defaultdict(list)
        for file, metadata in self.file_metadata.items():
            if metadata.get('hash'):
                hash_to_files[metadata['hash']].append(file)
        
        for file_hash, files in hash_to_files.items():
            if len(files) > 1:
                findings['duplicate_files'].append({
                    'files': files,
                    'size': self.file_metadata[files[0]]['size']
                })
        
        # Find old files (not modified in 1+ years)
        one_year_ago = datetime.now().timestamp() - (365 * 24 * 60 * 60)
        for file, metadata in self.file_metadata.items():
            try:
                mod_time = datetime.fromisoformat(metadata['modified']).timestamp()
                if mod_time < one_year_ago:
                    # Only flag config and source files
                    if Path(file).suffix in ['.js', '.ts', '.py', '.json', '.config.js']:
                        findings['old_files'].append({
                            'path': file,
                            'modified': metadata['modified'],
                            'size': metadata.get('size', 0)
                        })
            except:
                continue
        
        # Calculate totals
        findings['summary']['orphaned_count'] = len(findings['orphaned_files'])
        findings['summary']['unnecessary_count'] = len(findings['unnecessary_files'])
        findings['summary']['empty_count'] = len(findings['empty_files'])
        findings['summary']['duplicate_sets'] = len(findings['duplicate_files'])
        findings['summary']['old_files_count'] = len(findings['old_files'])
        
        total_waste = sum(f['size'] for f in findings['unnecessary_files'])
        total_waste += sum(f['size'] for f in findings['empty_files'])
        findings['summary']['potential_space_savings_mb'] = round(total_waste / (1024 * 1024), 2)
        
        return findings
    
    def export_report(self, findings, output_path='cleanup_report.json'):
        """Export findings to JSON file"""
        output_file = self.root_path / output_path
        with open(output_file, 'w') as f:
            json.dump(findings, f, indent=2)
        print(f"\nReport exported to: {output_file}")
        return output_file


def main():
    parser = argparse.ArgumentParser(description='Analyze codebase for unused files')
    parser.add_argument('path', help='Root path of the project to analyze')
    parser.add_argument('--exclude', nargs='*', help='Additional directories to exclude')
    parser.add_argument('--output', default='cleanup_report.json', help='Output file path')
    
    args = parser.parse_args()
    
    # Run analysis
    analyzer = CodebaseAnalyzer(args.path, exclude_dirs=args.exclude)
    findings = analyzer.analyze()
    
    # Export report
    analyzer.export_report(findings, args.output)
    
    # Print summary
    print("\n" + "=" * 60)
    print("ANALYSIS SUMMARY")
    print("=" * 60)
    print(f"Total files analyzed: {findings['summary']['total_files']}")
    print(f"Orphaned files: {findings['summary']['orphaned_count']}")
    print(f"Unnecessary files: {findings['summary']['unnecessary_count']}")
    print(f"Empty/near-empty files: {findings['summary']['empty_count']}")
    print(f"Duplicate file sets: {findings['summary']['duplicate_sets']}")
    print(f"Old files: {findings['summary']['old_files_count']}")
    print(f"Potential space savings: {findings['summary']['potential_space_savings_mb']} MB")
    print("=" * 60)


if __name__ == '__main__':
    main()
