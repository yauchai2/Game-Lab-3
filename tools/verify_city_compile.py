#!/usr/bin/env python3
"""Compile new city scripts with screenshot warning categories fatal."""
from pathlib import Path
import tempfile,subprocess,argparse
parser=argparse.ArgumentParser()
parser.add_argument("--godot",default="godot")
parser.add_argument("--output",type=Path,default=Path(__file__).resolve().parents[1]/"docs/evidence/campaign-complete/city-strict.log")
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]/'godot'
with tempfile.TemporaryDirectory() as temp:
 p=Path(temp)
 for item in root.iterdir():
  if item.name not in ('project.godot','override.cfg'):(p/item.name).symlink_to(item,target_is_directory=item.is_dir())
 (p/'project.godot').write_text((root/'project.godot').read_text())
 (p/'override.cfg').write_text('[debug]\n'+''.join('gdscript/warnings/'+x+'=2\n' for x in ['static_called_on_instance','incompatible_ternary','shadowed_variable_base_class','integer_division']))
 (p/'city-check.gd').write_text('extends SceneTree\nfunc _initialize() -> void:\n    var failed:=0\n    for path in '+repr(['res://scripts/combat/city/'+n+'.gd' for n in ['city_profile','city_hub','city_campaign','city_builds','city_loot','city_contracts','city_talent_tree','city_balance','city_story','campaign_stage_view','campaign_visuals','nightshift/workshop','nightshift/reference_workshop','nightshift/preview']]+['res://scripts/combat/story/campaign_rules.gd'])+':\n        var script:=GDScript.new()\n        script.source_code=FileAccess.get_file_as_string(path)\n        var code:=script.reload()\n        print("CITY_STRICT ",path," ",code==OK)\n        if code!=OK:failed+=1\n    quit(failed)\n')
 result=subprocess.run([args.godot,'--headless','--path',str(p),'--script','res://city-check.gd'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
 print(result.stdout);args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(result.stdout)
 raise SystemExit(result.returncode or int('ERROR:' in result.stdout))
