"""Install the user's generated throw library into the bundled animation directory.

Usage: python3 tools/install_mixamo_throw.py ~/Downloads/mixamo_shoulder_throw.json
Restart the game afterwards. Original FBX are never overwritten.
"""
import argparse
import json
import os
import shutil
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('library', type=Path)
args = parser.parse_args()
source = args.library.expanduser().resolve()
data = json.loads(source.read_text())
if data.get('schema') != 1 or data.get('first') != 61 or data.get('last') != 121:
    parser.error('Expected the paired shoulder throw library, schema 1, frames 61–121.')
for role in ['aggressor', 'victim']:
    actor = data.get('actors', {}).get(role, {})
    if len(actor.get('bones', [])) != 65 or len(actor.get('frames', [])) != 61:
        parser.error(f'{role}: missing expected bones/frames')
os.umask(0o077)
target = Path(__file__).resolve().parents[1] / 'godot/assets/animations/mixamo_shoulder_throw.json'
target.parent.mkdir(parents=True, exist_ok=True)
if source != target:
    if target.exists():
        backup = target.parents[2] / '.godot/animation_backups' / target.name
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(target, backup)
    temp = target.with_suffix('.json.tmp')
    shutil.copyfile(source, temp)
    temp.chmod(0o600)
    temp.replace(target)
target.chmod(0o600)
print(f'Installed throw library: {target}\nRestart Godot/game to reload it. The bundled game reads this file directly.')
