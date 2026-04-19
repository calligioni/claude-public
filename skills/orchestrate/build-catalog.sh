#!/usr/bin/env bash
# build-catalog.sh — regenerate skill-catalog.json from ~/.claude-setup/skills/*/SKILL.md
# Called by /orchestrate Pre-Flight step. Fast (<200ms target).
set -eu

SKILLS_DIR="${HOME}/.claude-setup/skills"
OUT="${HOME}/.claude-setup/skills/orchestrate/skill-catalog.json"

python3 - <<'PY' "$SKILLS_DIR" "$OUT"
import json, os, re, sys, datetime

skills_dir, out_path = sys.argv[1], sys.argv[2]

def parse_frontmatter(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            text = f.read()
    except Exception:
        return None
    m = re.match(r'^---\n(.*?)\n---', text, re.DOTALL)
    if not m:
        return None
    fm = m.group(1)
    fields = {}
    for line in fm.splitlines():
        m2 = re.match(r'^([a-z\-]+):\s*(.*)$', line)
        if m2:
            key, val = m2.group(1), m2.group(2).strip()
            if val.startswith('"') and val.endswith('"'):
                val = val[1:-1]
            fields[key] = val
    return fields

skills = []
for entry in sorted(os.listdir(skills_dir)):
    if entry == 'orchestrate':
        continue
    skill_path = os.path.join(skills_dir, entry, 'SKILL.md')
    if not os.path.isfile(skill_path):
        continue
    fm = parse_frontmatter(skill_path)
    if not fm:
        continue
    if fm.get('user-invocable', 'true').lower() == 'false':
        continue
    skills.append({
        'name': fm.get('name', entry),
        'description': fm.get('description', ''),
        'model': fm.get('model', 'unknown'),
        'effort': fm.get('effort', 'unknown'),
        'argument_hint': fm.get('argument-hint', ''),
    })

out = {
    'generated_at': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'count': len(skills),
    'skills': skills,
}
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(out, f, indent=2)
print(f'Catalog rebuilt: {out_path} ({len(skills)} skills)')
PY
