#!/usr/bin/env python3
"""Copy raw Tripo prop GLBs untouched into source/, then write derived GLBs whose
base-colour texture is reduced to 256x256 (Jet Set Radio-like crunch; the game uses
nearest filtering). Raw files are never modified. Usage: tools/downscale_story_props.py RAW_DIR"""
import io, json, shutil, struct, sys
from pathlib import Path
from PIL import Image

NAMES = {  # Tripo convert id prefix -> prop name
    "f2238f60": "traffic_light", "89988ed4": "boombox", "48fdb3c6": "wall_fan", "3cf7e913": "red_car",
    "8ff788b6": "case_open", "5441c467": "drawer_cabinet", "21aebe08": "workbench", "97673abd": "case_closed",
    "798c6930": "shelf_bottles", "b0bae194": "pegboard_tools", "531e78f0": "shop_front"}
SIZE = 256
root = Path(__file__).resolve().parent.parent / "godot/assets/story_opening"

def derive(raw: bytes) -> bytes:
    n = struct.unpack("<I", raw[12:16])[0]
    j = json.loads(raw[20:20 + n])
    binc = raw[20 + n + 8:]
    views = [binc[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]] for v in j["bufferViews"]]
    for im in j["images"]:
        i = Image.open(io.BytesIO(views[im["bufferView"]])).convert("RGB")
        i = i.resize((SIZE, SIZE), Image.LANCZOS)
        out = io.BytesIO(); i.save(out, "PNG", optimize=True)
        views[im["bufferView"]] = out.getvalue(); im["mimeType"] = "image/png"
    blob = b""
    for v, data in zip(j["bufferViews"], views):
        blob += b"\0" * (-len(blob) % 4)
        v["byteOffset"] = len(blob); v["byteLength"] = len(data); blob += data
    blob += b"\0" * (-len(blob) % 4)
    j["buffers"] = [{"byteLength": len(blob)}]
    js = json.dumps(j, separators=(",", ":")).encode(); js += b" " * (-len(js) % 4)
    total = 12 + 8 + len(js) + 8 + len(blob)
    return (b"glTF" + struct.pack("<II", 2, total) + struct.pack("<I", len(js)) + b"JSON" + js +
            struct.pack("<I", len(blob)) + b"BIN\0" + blob)

for f in sorted(Path(sys.argv[1]).glob("*tripo_convert_*.glb")):
    prefix = next((k for k in NAMES if f.name.split("tripo_convert_")[1].startswith(k)), None)
    if prefix is None:
        continue
    raw = f.read_bytes()
    shutil.copyfile(f, root / "source" / ("tripo_convert_" + f.name.split("tripo_convert_")[1]))
    (root / f"{NAMES[prefix]}.glb").write_bytes(derive(raw))
    print(NAMES[prefix], len(raw), "->", (root / f"{NAMES[prefix]}.glb").stat().st_size)
