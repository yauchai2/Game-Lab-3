"""Generate tiny, exact UI geometry from the canonical Godot palette.
No editing of source artwork; generated SVGs remain inspectable native UI parts.
"""
import re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=(root/'godot/scripts/combat/ui/ui_theme.gd').read_text()
colors=dict(re.findall(r'const (\w+)\s*:=\s*Color\("([0-9a-f]+)"\)',source))
out=root/'godot/assets/ui/ink'
def save(name,w,h,body):
 (out/name).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n')
for active in [False,True]:
 fill=colors['TEAL'] if active else colors['NIGHT'];edge=colors['TEAL'] if active else colors['EDGE'];thumb=colors['INK'] if active else colors['PAPER'];x=26 if active else 4
 save('toggle-on.svg' if active else 'toggle-off.svg',46,24,f'<rect x="1" y="1" width="44" height="22" fill="#{fill}" stroke="#{edge}" stroke-width="2"/><rect x="{x}" y="4" width="16" height="16" fill="#{thumb}"/>')
for name,color in [('slider-thumb.svg','PAPER'),('slider-thumb-focus.svg','TEAL'),('slider-thumb-disabled.svg','EDGE')]:
 save(name,18,26,f'<path d="M3 1H17V22L14 25H1V4Z" fill="#{colors[color]}" stroke="#{colors["INK"]}" stroke-width="2"/>')
save('select-arrow.svg',12,8,f'<path d="M0 0H12L6 8Z" fill="#{colors["PAPER"]}"/>')

for active in [False,True]:
 x=26 if active else 4
 save('toggle-on-disabled.svg' if active else 'toggle-off-disabled.svg',46,24,f'<rect x="1" y="1" width="44" height="22" fill="#{colors["NIGHT"]}" stroke="#{colors["EDGE"]}" stroke-width="2"/><rect x="{x}" y="4" width="16" height="16" fill="#{colors["EDGE"]}"/>')
