#!/usr/bin/env python3
"""Export Godot Web and package a lossless, static-host-compatible engine.
Requires Godot 4.6.3 with official Web templates; Python standard library only.
"""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=ROOT / 'build/web')
args = parser.parse_args()
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
subprocess.run(['godot', '--headless', '--path', str(ROOT / 'godot'), '--export-release', 'Web', str(output / 'game.html')], check=True)
wasm = output / 'game.wasm'
raw = wasm.read_bytes()
compressed = gzip.compress(raw, compresslevel=9, mtime=0)
assert gzip.decompress(compressed) == raw
(output / 'game.wasm.gz').write_bytes(compressed)
wasm.unlink()
commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
# Evidence/log edits do not change the game; report uncommitted runtime sources.
changes = subprocess.check_output(['git','status','--porcelain','--untracked-files=all','--','godot','tools/build_web.py'],cwd=ROOT,text=True).splitlines()
source_dirty = any(not line.endswith('.uid') for line in changes)
html = (output / 'game.html').read_text().replace('__BUILD_ID__', commit[:7])
assert '$GODOT_' not in html
(output / 'index.html').write_text(html)
(output / 'game.html').unlink()
for filename in ['cover.webp', 'credits.html']:
    shutil.copyfile(ROOT / 'godot/web' / filename, output / filename)
licenses = output / 'licenses'
licenses.mkdir(exist_ok=True)
for filename in ['LICENSE-Juhani.txt', 'LICENSE-Kenney.txt']:
    shutil.copyfile(ROOT / 'godot/audio/open' / filename, licenses / filename)
shutil.copyfile(ROOT / 'godot/assets/animations/LICENSE-Quaternius.txt', licenses / 'LICENSE-Quaternius.txt')
# Keep a local cache once downloaded, so subsequent exports need no network.
copyright_file = ROOT / 'references/web/Godot-COPYRIGHT.txt'
if not copyright_file.exists():
    copyright_file.parent.mkdir(parents=True, exist_ok=True)
    url = 'https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/COPYRIGHT.txt'
    with urllib.request.urlopen(url, timeout=30) as response:
        copyright_file.write_bytes(response.read())
shutil.copyfile(copyright_file, licenses / 'Godot-COPYRIGHT.txt')
files = []
for path in sorted(output.rglob('*')):
    if path.is_file() and path.name != 'release-manifest.json':
        assert path.stat().st_size < 25 * 1024 * 1024, f'Hosting per-file limit: {path}'
        files.append({'file': path.relative_to(output).as_posix(), 'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
manifest = {'engine': 'Godot 4.6.3', 'upstream_repository': 'https://github.com/yauchai2/Game-Lab-3', 'upstream_commit': commit, 'source_dirty': source_dirty, 'threads': False, 'renderer': 'gl_compatibility', 'wasm_uncompressed_bytes': len(raw), 'wasm_uncompressed_sha256': hashlib.sha256(raw).hexdigest(), 'wasm_gzip_bytes': len(compressed), 'files': files, 'total_bytes': sum(p['bytes'] for p in files)}
(output / 'release-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print('WEB_BUILD', json.dumps({'directory': str(output), 'files': len(files) + 1, 'total_bytes': manifest['total_bytes'], 'source_commit': commit}))
