#!/usr/bin/env python3
"""Summarize native observation logs without treating in-progress runs as passed."""
from __future__ import annotations
import argparse
import datetime as dt
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/"docs/evidence/extended-polish"
RUNS=[("baseline-soak",10800,"baseline render/Timer",False),
      ("candidate-soak",3600,"final render/Timer before reconnect",False),
      ("candidate-resumed",1800,"final render/Timer after reconnect",True),
      ("native-input-soak",1200,"native input/physics",True)]


def summarize(folder: Path, requested: int, label: str) -> dict:
    samples=[json.loads(line) for line in (folder/"samples.jsonl").read_text().splitlines() if line.strip()]
    complete=json.loads((folder/"complete.json").read_text()) if (folder/"complete.json").exists() else {}
    tail=samples[-10:]
    memory=[row["static_memory"] for row in tail]
    objects=[row.get("object_count",row.get("objects")) for row in tail]
    orphans=[row.get("orphan_nodes",row.get("orphans",0)) for row in samples]
    result={"label":label,"duration_requested_seconds":requested,
            "completed":bool(complete.get("completed")) and complete.get("elapsed_seconds",0)>=requested,
            "elapsed_seconds":complete.get("elapsed_seconds",samples[-1]["elapsed_seconds"]),
            "sample_count":len(samples),"orphan_nodes_max":max(orphans),
            "late_memory_mib_range":[round(min(memory)/2**20,4),round(max(memory)/2**20,4)],
            "late_memory_spread_kib":round((max(memory)-min(memory))/1024,3),
            "late_objects_range":[min(objects),max(objects)],
            "metadata":json.loads((folder/"metadata.json").read_text())}
    result["status"]="complete" if result["completed"] else ("interrupted by environment" if result["metadata"].get("environment_interrupted") else "in progress")
    if folder.name=="native-input-soak":
        result["rounds"]=complete.get("rounds",samples[-1].get("rounds"))
        result["matches"]=complete.get("matches",samples[-1].get("matches"))
        result["input_events"]=complete.get("input_events",samples[-1].get("input_events"))
        result["physics_ticks"]=complete.get("physics_ticks",samples[-1].get("physics_ticks"))
    else:
        result["result_restarts"]=complete.get("matches",samples[-1].get("matches"))
        result["counter_note"]="The legacy matches field counts result/restart cycles, not complete first-to-two matches."
        result["clashes"]=complete.get("clashes",samples[-1].get("clashes"))
        result["menu_cycles"]=complete.get("menu_cycles",samples[-1].get("menu_cycles",0))
        result["recoveries"]=complete.get("recoveries",samples[-1].get("recoveries",0))
    return result


def plot(target: Path, summary: dict) -> None:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig,axes=plt.subplots(len(RUNS),2,figsize=(12,12),constrained_layout=True)
    colors=["#287f86","#d06948","#4a8c58","#6b6c9f"]
    for i,(name,_,label,_) in enumerate(RUNS):
        samples=[json.loads(line) for line in (BASE/name/"samples.jsonl").read_text().splitlines() if line.strip()]
        minutes=[row["elapsed_seconds"]/60 for row in samples]
        memory=[row["static_memory"]/2**20 for row in samples]
        objects=[row.get("object_count",row.get("objects")) for row in samples]
        for j,values in enumerate([memory,objects]):
            ax=axes[i,j]
            ax.plot(minutes,values,color=colors[i],linewidth=1.6)
            status=summary["runs"][name]["status"]
            ax.set_title(label+(" / memory" if j==0 else " / objects")+"\n"+status,fontsize=10)
            ax.set_xlabel("Wall-clock minutes")
            ax.set_ylabel("MiB" if j==0 else "Objects")
            ax.grid(alpha=.2)
            ax.spines[["top","right"]].set_visible(False)
    progress="REQUIRED RUNS COMPLETE" if summary["all_required_runs_complete"] else "IN PROGRESS"
    fig.suptitle(f"Native stability observations / {progress}\nInterrupted runs retained separately; software GL, not an FPS benchmark",fontsize=14)
    fig.savefig(target,dpi=140)
    plt.close(fig)


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--allow-incomplete",action="store_true")
    parser.add_argument("--plot",action="store_true")
    parser.add_argument("--output",type=Path,default=BASE/"stability.json")
    args=parser.parse_args()
    runs={name:summarize(BASE/name,requested,label) for name,requested,label,_ in RUNS}
    worklog=json.loads((BASE/"worklog.json").read_text())
    now=dt.datetime.now(dt.timezone.utc)
    started=dt.datetime.fromisoformat(worklog["started_utc"].replace("Z","+00:00"))
    minimum=dt.datetime.fromisoformat(worklog["minimum_finish_utc"].replace("Z","+00:00"))
    active_seconds=0.0
    for segment in worklog.get("active_work_segments",[]):
        a=dt.datetime.fromisoformat(segment["started_utc"].replace("Z","+00:00"))
        b=dt.datetime.fromisoformat(segment["ended_utc"].replace("Z","+00:00")) if segment.get("ended_utc") else now
        active_seconds+=max(0,(b-a).total_seconds())
    active_met=active_seconds>=10800 if worklog.get("active_work_segments") else now>=minimum
    summary={"created_utc":now.isoformat(),"all_required_runs_complete":all(runs[name]["completed"] for name,_,_,required in RUNS if required),
             "interrupted_runs":[name for name,run in runs.items() if run["status"]=="interrupted by environment"],
             "minimum_task_time_met":now>=minimum and active_met,"task_wall_elapsed_seconds":round((now-started).total_seconds(),3),
             "active_work_seconds_lower_bound":round(active_seconds,3),"idle_gap_excluded":bool(worklog.get("active_work_segments")),
             "runs":runs,"scope":"Wall-time process observation. Timer runs are frame-limited and differ from the native physics/input run. Not human balance testing, listening or target-GPU performance."}
    if not args.allow_incomplete and not summary["all_required_runs_complete"]:
        raise SystemExit("Required observations are still running; no completed stability report written.")
    if not args.allow_incomplete and not summary["minimum_task_time_met"]:
        raise SystemExit("The user's minimum work duration is not yet met; no final report written.")
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(summary,indent=2)+"\n")
    if args.plot:plot(args.output.with_suffix(".png"),summary)
    print(json.dumps(summary,indent=2))
    return 0


if __name__=="__main__":raise SystemExit(main())
