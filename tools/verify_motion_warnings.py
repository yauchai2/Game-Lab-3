"""Compile motion runtime scripts with the project's seven warning categories fatal."""
from pathlib import Path
import json
import subprocess
import sys
import tempfile
sys.dont_write_bytecode = True
from verify_godot_warnings import CATEGORIES

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ['combat_motions.gd', 'fighter_visual.gd', 'neon/neon_signature_motion.gd',
           'last_service/rivet_motion.gd', 'last_service/street_motion.gd', 'last_service/counter_motion.gd', 'ink_fx/fx_recipes.gd', 'fighter_effect_style.gd', 'neon/neon_signature_camera.gd', 'fight_audio.gd', 'neon/neon_effect_director.gd']
output = Path(sys.argv[1]).resolve()
output.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='street-motion-strict-') as temp:
    project = Path(temp)
    for item in (ROOT/'godot').iterdir():
        if item.name not in ['project.godot', 'override.cfg']:
            (project/item.name).symlink_to(item, target_is_directory=item.is_dir())
    (project/'project.godot').write_bytes((ROOT/'godot/project.godot').read_bytes())
    (project/'override.cfg').write_text('[debug]\ngdscript/warnings/enable=true\n'+''.join(f'gdscript/warnings/{name}=2\n' for name in CATEGORIES))
    (project/'check.gd').write_text('extends SceneTree\nfunc _initialize() -> void:\n    var paths='+json.dumps(['res://scripts/combat/'+s for s in SCRIPTS])+'\n    for path in paths:\n        var script=GDScript.new()\n        script.source_code=FileAccess.get_file_as_string(path)\n        if script.reload()!=OK:\n            quit(1)\n            return\n        print("MOTION_STRICT ",path," PASS")\n    quit()\n')
    result = subprocess.run(['godot', '--headless', '--path', str(project), '--script', 'res://check.gd'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=60)
output.write_text(result.stdout)
print(result.stdout)
sys.exit(0 if result.returncode == 0 and 'SCRIPT ERROR' not in result.stdout and '\nERROR:' not in result.stdout else 1)
