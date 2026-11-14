"""Build an OFL UI subset from the installed Debian Noto Sans CJK HK font.
Run again after adding UI copy; source package/hash and licenses are retained.
"""
from pathlib import Path
import hashlib,json,subprocess,sys
from fontTools.ttLib import TTFont
from fontTools import subset
root=Path(__file__).resolve().parents[1]
source=Path('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc')
text=''.join(p.read_text() for p in (root/'godot/scripts/combat').rglob('*.gd'))
text+=''.join(p.read_text() for p in (root/'godot/assets/localization').glob('*.json'))
text+=''.join(chr(i) for i in range(32,127))+'…→·：／％（）？！，。１２３'
font=TTFont(source,fontNumber=4,recalcTimestamp=False)
options=subset.Options()
options.name_IDs=['*'];options.name_legacy=True;options.name_languages=['*']
subsetter=subset.Subsetter(options=options);subsetter.populate(text=text);subsetter.subset(font)
for record in font['name'].names:
    if record.nameID in (1,4,6,16):record.string=('Afterhours UI HK' if record.nameID!=6 else 'AfterhoursUIHK').encode(record.getEncoding(),errors='replace')
output=root/'godot/assets/fonts/AfterhoursUIHK.otf'
output.parent.mkdir(parents=True,exist_ok=True);font.save(output)
manifest={'source':'https://github.com/notofonts/noto-cjk','package':'fonts-noto-cjk 1:20240730+repack1-1','source_collection_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'font_collection_index':4,'derivative_family':'Afterhours UI HK','license':'SIL OFL 1.1','generator':'tools/subset_ui_font.py','output':str(output.relative_to(root)),'output_sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'characters_requested':len(set(text)),'bytes':output.stat().st_size}
(root/'references/ui-fonts/noto-subset.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(manifest))
# Keep the runtime Chinese pixel atlas in step with every catalog/subset update.
subprocess.run([sys.executable,str(root/"tools/build_subtle_pixel_fonts.py")],check=True)
