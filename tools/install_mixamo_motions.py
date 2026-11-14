"""Install the user's private first-batch library; restart Godot/game afterwards.

python3 tools/install_mixamo_motions.py ~/Downloads/mixamo_fighters.json
Shoulder throw uses the separate install_mixamo_throw.py installer.
"""
import argparse
import hashlib
import json
import os
import shutil
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('library', type=Path)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
source = args.library.expanduser().resolve()
data = json.loads(source.read_text())
base = repo / 'godot/assets/animations/quaternius_combat.json'
if data.get('schema') != 1 or data.get('kind') != 'mixamo_fighters':
    parser.error('Expected a generated private mixamo_fighters library, schema 1')
if data.get('base_sha256') != hashlib.sha256(base.read_bytes()).hexdigest():
    parser.error('Canonical rig differs. Rebuild the private library for this checkout.')
if not data.get('clips') or set(data['clips']) != set(data.get('markers', {})):
    parser.error('Missing clip or contact metadata')
os.umask(0o077)
target = repo / 'godot/.godot/private_animation/mixamo_fighters.json'
target.parent.mkdir(parents=True, exist_ok=True)
if source != target:
    if target.exists():
        shutil.copyfile(target, target.with_suffix('.json.bak'))
    temp = target.with_suffix('.json.tmp')
    shutil.copyfile(source, temp)
    temp.chmod(0o600)
    temp.replace(target)
target.chmod(0o600)
print(f'Installed {len(data["clips"])} private clips: {target}\nRestart Godot/game. Keep this file outside Git.')
