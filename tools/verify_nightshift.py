#!/usr/bin/env python3
"""Focused hub + existing campaign regression; preserve historical evidence files."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]
CASES=[
    ('verify_nightshift_hub','nightshift-reference/verification.json',True),
    ('verify_campaign_complete_native','campaign-complete/native.json',True),
    ('verify_city_expansion_native','city-expansion/native.json',True),
    ('verify_campaign_complete','campaign-complete/rules.json',False),
    ('verify_city_expansion','city-expansion/rules.json',False),
]
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--only',help='Comma-separated script names')
    args=parser.parse_args();selected=set(args.only.split(',')) if args.only else {c[0] for c in CASES}
    if selected-{c[0] for c in CASES}:parser.error('Unknown case')
    out=ROOT/'docs/evidence/nightshift-reference/regression';out.mkdir(parents=True,exist_ok=True);results=[]
    for name,report,native in CASES:
        if name not in selected:continue
        if native and not os.environ.get('DISPLAY'):parser.error('Native checks require DISPLAY')
        # Restore screenshots AND auxiliary reports, not only the primary JSON.
        directory=ROOT/'docs/evidence'/Path(report).parent
        before={p:p.read_bytes() for p in directory.rglob('*') if p.is_file()} if name!='verify_nightshift_hub' else {}
        primary=ROOT/'docs/evidence'/report;old=primary.read_bytes() if primary.exists() else None
        old_mtime=primary.stat().st_mtime_ns if primary.exists() else None
        cmd=['godot','--path','godot','--audio-driver','Dummy']+(['--rendering-method','gl_compatibility'] if native else ['--headless'])+['--script',f'res://tools/{name}.gd']
        try:
            with (out/(name+'.log')).open('w') as log_file:
                try:
                    result=subprocess.run(cmd,cwd=ROOT,stdout=log_file,stderr=subprocess.STDOUT,text=True,timeout=240)
                except subprocess.TimeoutExpired:
                    from types import SimpleNamespace
                    result=SimpleNamespace(returncode=124)
                    log_file.write('\nHARNESS TIMEOUT\n')
            log=re.sub(r'\x1b\[[0-9;]*[A-Za-z]','',(out/(name+'.log')).read_text());(out/(name+'.log')).write_text(log)
            written=primary.exists() and primary.stat().st_mtime_ns!=old_mtime
            data=json.loads(primary.read_text()) if written else {};checks=data.get('checks',[])
            errors=re.findall(r'^(?:ERROR|SCRIPT ERROR):.*',log,re.M)
            passed=sum(c.get('passed',False) for c in checks)
            record=dict(name=name,passed=passed,total=len(checks),exit_code=result.returncode,engine_errors=errors,report_written=written,success=result.returncode==0 and written and bool(checks) and passed==len(checks) and not errors)
            results.append(record);(out/(name+'.json')).write_text(json.dumps(data,indent=2));print(record,flush=True)
        finally:
            if name!='verify_nightshift_hub':
                for p,content in before.items():p.write_bytes(content)
                for p in directory.rglob('*'):
                    if p.is_file() and p not in before:p.unlink()
    summary_path=out/'summary.json'
    previous=json.loads(summary_path.read_text()) if summary_path.exists() else []
    merged={r['name']:r for r in previous}
    merged.update({r['name']:r for r in results})
    summary_path.write_text(json.dumps(list(merged.values()),indent=2))
    return 0 if results and all(c['success'] for c in results) else 1
if __name__=='__main__':raise SystemExit(main())
