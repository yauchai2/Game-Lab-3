"""Build bitmap font derivatives from bundled licensed fonts, with binary alpha.
Typeface adaptation, not a claim to the official Jet Set Radio font.
"""
from PIL import Image,ImageFont,ImageDraw
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[1];out=root/'godot/assets/fonts';meta=[]
for name,source,point in [('RadioPixelDisplay','BarlowCondensed-BlackItalic.ttf',24),('RadioPixelBody','DejaVuSansCondensed-Bold.ttf',16)]:
 font=ImageFont.truetype(str(out/source),point);atlas=Image.new('RGBA',(512,256));chars=[];x=y=2;row=point+6
 for code in list(range(32,127))+[8734,8592,8594,8593,8595,183,8212,8211]:
  c=chr(code);box=font.getbbox(c,anchor='ls');w=max(1,box[2]-box[0]);h=max(1,box[3]-box[1]);advance=round(font.getlength(c))
  if x+w+3>=512:x=2;y+=row
  mask=Image.new('L',(w,h));ImageDraw.Draw(mask).text((-box[0],-box[1]),c,font=font,anchor='ls',fill=255)
  mask=mask.point(lambda n:255 if n>=96 else 0);glyph=Image.new('RGBA',(w,h),'white');glyph.putalpha(mask);atlas.paste(glyph,(x,y))
  chars.append(f'char id={code} x={x} y={y} width={w} height={h} xoffset={box[0]} yoffset={box[1]+point} xadvance={max(1,advance)} page=0 chnl=15');x+=w+4
 target=out/(name+'.png');atlas.save(target)
 text=f'info face="Afterhours {name}" size={point} bold=1 italic={int(name.endswith("Display"))} charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1\ncommon lineHeight={point+4} base={point} scaleW=512 scaleH=256 pages=1 packed=0\npage id=0 file="{name}.png"\nchars count={len(chars)}\n'+'\n'.join(chars)+'\n'
 (out/(name+'.fnt')).write_text(text)
 meta.append({'font':name,'source':source,'source_sha256':hashlib.sha256((out/source).read_bytes()).hexdigest(),'bitmap_size':point,'characters':len(chars),'atlas_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'derivation':'Binary-alpha bitmap rendering of licensed bundled typeface. Display preserves the heavy italic radio lettering; custom AFTERHOURS logo remains reference artwork.'})
(root/'references/unified-pixel-2026-11-10/fonts.json').write_text(json.dumps(meta,indent=2)+'\n')
