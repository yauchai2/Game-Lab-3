"""Bundle an already installed, generated Mac backwalk alongside the current game motions.

Run on the machine that actually has the 24-clip library, then commit/push the updated JSON.
This copies only MX_WalkBack; newer bundled GetUp/KnockedOut curves stay intact.
"""
import argparse
import hashlib
import json
import os
import shutil
from pathlib import Path

repo = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('source', nargs='?', type=Path, default=repo/'godot/.godot/private_animation/mixamo_fighters.json')
args = parser.parse_args()
if not args.source.is_file():
    parser.error(f'Installed extension library not found: {args.source}')
target = repo/'godot/assets/animations/mixamo_fighters.json'
base = json.loads(target.read_text())
extension = json.loads(args.source.read_text())
if extension.get('schema') != 1 or extension.get('kind') != 'mixamo_fighters' or extension.get('base_sha256') != base['base_sha256']:
    parser.error('Expected the compatible generated motion library')
if 'MX_WalkBack' not in extension.get('clips', {}) or 'MX_WalkBack' not in extension.get('markers', {}):
    parser.error('Source has no MX_WalkBack; use the library from the Mac backwalk task')
base['clips']['MX_WalkBack'] = extension['clips']['MX_WalkBack']
base['markers']['MX_WalkBack'] = extension['markers']['MX_WalkBack']
base['manifest'] = [m for m in base.get('manifest', []) if m['clip'] != 'MX_WalkBack']
base['manifest'] += [m for m in extension.get('manifest', []) if m['clip'] == 'MX_WalkBack']
os.umask(0o077)
backup = repo/'godot/.godot/animation_backups/before-backwalk.json'
backup.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(target, backup)
temp = target.with_suffix('.json.tmp')
temp.write_text(json.dumps(base, separators=(',', ':'))+'\n')
temp.replace(target)
evidence = repo/'docs/evidence/motion-completion'
manifest_path = evidence/'bundle-manifest.json'
if manifest_path.is_file():
    manifest = json.loads(manifest_path.read_text())
    for row in manifest['runtime_assets']:
        if row['file'] == target.name:
            row.update(bytes=target.stat().st_size, sha256=hashlib.sha256(target.read_bytes()).hexdigest())
    manifest['bundled_optional_extension'] = 'MX_WalkBack'
    manifest_path.write_text(json.dumps(manifest, indent=2)+'\n')
if (evidence/'clips.json').is_file():
    (evidence/'clips.json').write_text(json.dumps({'base_sha256':base['base_sha256'], 'clips':base['manifest'], 'markers':base['markers']}, indent=2)+'\n')
print(f'Bundled {len(base["clips"])} clips at {target}; commit/push this file to share the backwalk.')
print('Run the animation checks and commit updated provenance too; existing reports describe their original input bundle.')
