#!/usr/bin/env python3
"""
Safe File Deletion Script
Safely deletes files with backup options and detailed logging.
"""

import os
import shutil
import argparse
import json
from pathlib import Path
from datetime import datetime


class SafeDeleter:
    def __init__(self, project_root, backup_dir=None, dry_run=False):
        self.project_root = Path(project_root).resolve()
        self.backup_dir = Path(backup_dir).resolve() if backup_dir else None
        self.dry_run = dry_run
        self.deletion_log = []
        
    def delete_files(self, file_list, mode='delete'):
        """
        Delete files safely
        
        Args:
            file_list: List of file paths relative to project root
            mode: 'delete' (remove permanently), 'move' (move to backup), or 'git' (stage for git commit)
        """
        print(f"Safe Deletion Started - Mode: {mode}")
        print(f"Dry Run: {self.dry_run}")
        print("=" * 60)
        
        if mode == 'move' and not self.backup_dir:
            # Create default backup directory
            self.backup_dir = self.project_root / f".cleanup-backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
            print(f"Creating backup directory: {self.backup_dir}")
            if not self.dry_run:
                self.backup_dir.mkdir(parents=True, exist_ok=True)
        
        success_count = 0
        error_count = 0
        
        for file_rel in file_list:
            try:
                result = self._process_file(file_rel, mode)
                if result:
                    success_count += 1
                    print(f"✓ {file_rel}")
                else:
                    error_count += 1
                    print(f"✗ {file_rel} - skipped or failed")
            except Exception as e:
                error_count += 1
                print(f"✗ {file_rel} - Error: {e}")
                self.deletion_log.append({
                    'file': file_rel,
                    'status': 'error',
                    'error': str(e),
                    'timestamp': datetime.now().isoformat()
                })
        
        print("\n" + "=" * 60)
        print(f"Deletion Summary:")
        print(f"  Success: {success_count}")
        print(f"  Errors: {error_count}")
        print(f"  Total: {len(file_list)}")
        print("=" * 60)
        
        return success_count, error_count
    
    def _process_file(self, file_rel, mode):
        """Process a single file deletion"""
        file_path = self.project_root / file_rel
        
        # Check if file exists
        if not file_path.exists():
            self.deletion_log.append({
                'file': file_rel,
                'status': 'not_found',
                'timestamp': datetime.now().isoformat()
            })
            return False
        
        # Check if it's a file (not directory)
        if not file_path.is_file():
            self.deletion_log.append({
                'file': file_rel,
                'status': 'not_a_file',
                'timestamp': datetime.now().isoformat()
            })
            return False
        
        if self.dry_run:
            self.deletion_log.append({
                'file': file_rel,
                'status': 'would_delete',
                'mode': mode,
                'timestamp': datetime.now().isoformat()
            })
            return True
        
        # Perform the actual operation
        if mode == 'move':
            return self._move_to_backup(file_path, file_rel)
        elif mode == 'delete':
            return self._delete_file(file_path, file_rel)
        elif mode == 'git':
            return self._git_rm(file_path, file_rel)
        
        return False
    
    def _move_to_backup(self, file_path, file_rel):
        """Move file to backup directory preserving structure"""
        backup_path = self.backup_dir / file_rel
        
        # Create parent directories in backup
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Move file
        shutil.move(str(file_path), str(backup_path))
        
        self.deletion_log.append({
            'file': file_rel,
            'status': 'moved_to_backup',
            'backup_location': str(backup_path),
            'timestamp': datetime.now().isoformat()
        })
        
        return True
    
    def _delete_file(self, file_path, file_rel):
        """Permanently delete file"""
        file_path.unlink()
        
        self.deletion_log.append({
            'file': file_rel,
            'status': 'deleted',
            'timestamp': datetime.now().isoformat()
        })
        
        return True
    
    def _git_rm(self, file_path, file_rel):
        """Stage file for deletion in git"""
        import subprocess
        
        try:
            subprocess.run(
                ['git', 'rm', str(file_path)],
                cwd=self.project_root,
                check=True,
                capture_output=True
            )
            
            self.deletion_log.append({
                'file': file_rel,
                'status': 'git_rm',
                'timestamp': datetime.now().isoformat()
            })
            
            return True
        except subprocess.CalledProcessError as e:
            # If git rm fails, just delete the file
            file_path.unlink()
            
            self.deletion_log.append({
                'file': file_rel,
                'status': 'deleted_no_git',
                'note': 'git rm failed, deleted manually',
                'timestamp': datetime.now().isoformat()
            })
            
            return True
    
    def export_log(self, output_path='deletion_log.json'):
        """Export deletion log to JSON file"""
        log_file = self.project_root / output_path
        
        with open(log_file, 'w') as f:
            json.dump({
                'summary': {
                    'total_files': len(self.deletion_log),
                    'successful': sum(1 for log in self.deletion_log if log['status'] in ['moved_to_backup', 'deleted', 'git_rm']),
                    'failed': sum(1 for log in self.deletion_log if log['status'] in ['error', 'not_found']),
                    'dry_run': self.dry_run,
                    'backup_dir': str(self.backup_dir) if self.backup_dir else None,
                    'timestamp': datetime.now().isoformat()
                },
                'log': self.deletion_log
            }, f, indent=2)
        
        print(f"\nDeletion log exported to: {log_file}")
        return log_file
    
    def create_undo_script(self, output_path='undo_deletion.sh'):
        """Create a bash script to undo the deletion"""
        if not self.backup_dir or self.dry_run:
            return None
        
        script_file = self.project_root / output_path
        
        with open(script_file, 'w') as f:
            f.write('#!/bin/bash\n')
            f.write('# Undo script for file deletion\n')
            f.write(f'# Created: {datetime.now().isoformat()}\n\n')
            f.write(f'BACKUP_DIR="{self.backup_dir}"\n')
            f.write(f'PROJECT_DIR="{self.project_root}"\n\n')
            f.write('echo "Restoring files from backup..."\n\n')
            
            for log_entry in self.deletion_log:
                if log_entry['status'] == 'moved_to_backup':
                    file_rel = log_entry['file']
                    f.write(f'# Restore {file_rel}\n')
                    f.write(f'cp -v "$BACKUP_DIR/{file_rel}" "$PROJECT_DIR/{file_rel}"\n\n')
            
            f.write('echo "Restore complete!"\n')
        
        # Make script executable
        os.chmod(script_file, 0o755)
        
        print(f"Undo script created: {script_file}")
        print(f"To undo deletion, run: {script_file}")
        
        return script_file


def main():
    parser = argparse.ArgumentParser(description='Safely delete files with backup options')
    parser.add_argument('project_root', help='Root path of the project')
    parser.add_argument('--files-list', required=True, help='JSON file containing list of files to delete')
    parser.add_argument('--backup-dir', help='Directory to move files to (instead of deleting)')
    parser.add_argument('--mode', choices=['delete', 'move', 'git'], default='move',
                       help='Deletion mode: delete (permanent), move (to backup), git (git rm)')
    parser.add_argument('--dry-run', action='store_true', help='Simulate deletion without actually deleting')
    parser.add_argument('--log-file', default='deletion_log.json', help='Output log file')
    
    args = parser.parse_args()
    
    # Load files list
    with open(args.files_list, 'r') as f:
        data = json.load(f)
        if isinstance(data, list):
            files_to_delete = data
        elif isinstance(data, dict) and 'files' in data:
            files_to_delete = data['files']
        else:
            print("Error: Invalid files list format")
            return 1
    
    print(f"Loaded {len(files_to_delete)} files to delete")
    
    # Create deleter
    deleter = SafeDeleter(
        project_root=args.project_root,
        backup_dir=args.backup_dir,
        dry_run=args.dry_run
    )
    
    # Confirm with user
    if not args.dry_run:
        print("\nWARNING: This will modify/delete files!")
        print(f"Mode: {args.mode}")
        if args.mode == 'move':
            print(f"Backup directory: {deleter.backup_dir or 'auto-generated'}")
        response = input("\nProceed? (yes/no): ")
        if response.lower() != 'yes':
            print("Cancelled by user")
            return 0
    
    # Perform deletion
    success, errors = deleter.delete_files(files_to_delete, mode=args.mode)
    
    # Export log
    deleter.export_log(args.log_file)
    
    # Create undo script if backup was used
    if args.mode == 'move' and not args.dry_run:
        deleter.create_undo_script()
    
    return 0 if errors == 0 else 1


if __name__ == '__main__':
    exit(main())
