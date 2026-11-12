# City progression expansion evidence

Godot 4.7.2, Linux Compatibility, Mesa llvmpipe, Dummy audio. New default viewport: 960×540; logical UI 1280×720, nearest textures, bitmap fonts, MSAA and screen AA disabled. This is an implemented progression loop with placeholder district scenery; not final art, a giant Boss, human balance, Mac hardware or FPS acceptance.

Screens: [main](main-menu.png), [city](city.png), [960 battle](battle-960.png), [48-node talent tree](talent-tree.png), [real item comparison](gear-comparison.png), [contracts](contracts.png), [contract fight](contract-fight.png).

- [Rules](rules.json) / [log](rules.log): 86 checks. Graph composition/connectivity/budget/keystones, live build effects, seeded role caps, permanent vs run progress, loot/stash/pity/loadouts, transaction rollback, legacy backup migration, corruption recovery, contract entry/retries/guaranteed advancement, first-region four-hero ordinary-input play, real parry/chase refunds and shared splash hit/resource budgets. Full-story completion and endgame reward checks use explicit completion fixtures.
- [Native](native.json) / [log](native.log): 22 checks. Actual 960 viewport, main Story pointer, real damage input, city skill station, 48-node board/Connect/wheel/right drag, dealer/compare/equip, contract entry/defeat and real disk reload. Endgame progress/funding are explicit fixtures; no claim of human endgame clears.
- [Strict](strict/strict.json) and [seven city scripts](city-strict.log): 18 scripts compile with four warning categories fatal.
- [Regressions](regressions/summary.json): original M1 37, double jump 62, combat 34, nine-core rules 75. The four rule suites keep source assertions unchanged; temporary runner copies redirect evidence output to preserve historical records. Native presentation 15 and Ink UI 10 also pass, with their two framebuffer expectations updated from 640×360 to the new 960×540 contract; other assertions remain unchanged.

359 accepted checks, no ERROR/SCRIPT ERROR in final logs. Native unsupported VSync warning retained. During iteration a test-local untyped array-size variable failed parsing; corrected before accepted runs. Historical city-v1 fixtures are preserved in godot/tools/archive/city-v1; public verify_city_campaign/native entry points now run the current expanded suites.

Run: `godot --headless --path godot --script res://tools/verify_city_expansion.gd`; native display required for `verify_city_expansion_native.gd`. `python tools/verify_city_compile.py --godot <binary> --output <path>` handles seven city scripts; `tools/verify_godot_warnings.py` covers the existing eleven.
