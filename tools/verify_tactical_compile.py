"""Compile tactical integration under the project's seven fatal warning categories."""
from pathlib import Path
import argparse
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=ROOT / 'docs/evidence/tactics-expanded/changed-strict.log')
args = parser.parse_args()
FILES = [
    'tactics/skills', 'tactics/modules', 'tactics/enemy_response', 'tactics/expanded', 'tactics/presentation', 'last_service/presentation', 'last_service/rules', 'fight_simulation', 'fight_session',
    'motion_interpolation', 'fight_controls', 'fight_hud', 'fight_preferences', 'fighter_visual',
    'city/city_profile', 'city/city_campaign', 'city/city_hub', 'city/hub_pages',
    'city/story_guide', 'city/story_flow', 'city/city_loot', 'story/story_simulation', 'enemies/gun_shot',
]
CATEGORIES = ['static_called_on_instance', 'incompatible_ternary',
              'shadowed_variable_base_class', 'integer_division',
              'confusable_local_declaration', 'unused_parameter', 'standalone_ternary']
with tempfile.TemporaryDirectory(prefix='tactics-strict-') as folder:
    project = Path(folder)
    for item in (ROOT / 'godot').iterdir():
        if item.name not in ('project.godot', 'override.cfg'):
            (project / item.name).symlink_to(item, target_is_directory=item.is_dir())
    (project / 'project.godot').write_bytes((ROOT / 'godot/project.godot').read_bytes())
    (project / 'override.cfg').write_text('[debug]\ngdscript/warnings/enable=true\n' +
        ''.join(f'gdscript/warnings/{key}=2\n' for key in CATEGORIES))
    paths = ['res://scripts/combat/' + path + '.gd' for path in FILES]
    (project / 'tactics-check.gd').write_text('extends SceneTree\nfunc _initialize() -> void:\n'
        '    var failed:=0\n    for path in ' + repr(paths) + ':\n'
        '        var script:=GDScript.new()\n'
        '        script.source_code=FileAccess.get_file_as_string(path)\n'
        '        var code:=script.reload()\n'
        '        print("TACTICS_STRICT ",path," ",code==OK)\n'
        '        if code!=OK:failed+=1\n    quit(failed)\n')
    result = subprocess.run(['godot', '--headless', '--path', folder, '--script',
                             'res://tactics-check.gd'], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, timeout=90)
output = args.output
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(result.stdout)
print(result.stdout)
raise SystemExit(result.returncode or int('ERROR:' in result.stdout))
