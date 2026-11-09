# Afterhours — interface design

## Current override: readable pixel typography (2026-11-10)

Keep the640×360 shared framebuffer. Minimum authored copy is24logical pixels; default body controls28, primary actions32 (12/14/16 internal pixel nominal sizes). `ui_theme.gd` owns these tokens. Use the14px/16px readable bitmap derivatives for body/small display text; large headings retain the original24px display source. The secondary panel is780×510 logical with14px item gaps and6px label line spacing. Source reference art remains; native large shortcuts, Pause and Enter/Esc hints replace the tiny baked text in those regions. Never solve readability by shrinking labels to fit: widen, wrap and scroll. See docs/UI_READABILITY.zh-TW.md for actual captures and hardware limits.


## Current override: unified pixel runtime (2026-11-10)

The complete world, UI, fonts and VFX composite at 640×360 with nearest integer viewport scaling. Controls retain 1280×720 authoring coordinates mapped to the internal framebuffer; pointer/keyboard mapping is tested at three window sizes. The former world-only retro toggle is retired. Display/body use locally generated binary-alpha BMFont derivatives of bundled Barlow Condensed Black Italic and DejaVu Sans Condensed Bold; these are JSR-inspired adaptations, not the official JSR font. Reference title art stays intact. Roster cards and hero use five isolated, bounded, low-resolution real-model SubViewports, updated at15Hz only on the roster page, with four different showcase poses. Menu focus has a short stepped pointer kick; reduced effects removes it. Audio has exactly two music decks plus ten effects voices, with named buses. Settings exposes Test Sound, Restore Sound and output status; silent title preferences show a recovery action. Transport continues through pause and mute. Details/evidence: docs/UNIFIED_PIXEL_RUNTIME.zh-TW.md. Earlier contradictory descriptions below are historical.


## Current approved reference UI — 2026-11-09

The user now requests direct reproduction of the supplied three screens, English, and only five title actions. Main is the exact original raster artwork under aligned native targets. Roster is a native four-card/P1/P2 grid with reference art and live profile data; HUD uses reference geometry and fixed crops around native dynamic values. `reference_art.gd` is the canonical HUD's drawing helper, not a second interaction controller. The durable palette stays in ui_theme.gd; display type is now OFL Barlow Condensed Black Italic, body remains the bundled UI font. The historical DejaVu/left match-card descriptions below are superseded.

Music continues through pause/settings with smooth gain and two dedicated crossfade decks. Combat raster stamps and stick ghosts are retired; six-cel vector VFX preserve controlled silhouettes. See [REFERENCE_UI.md](docs/REFERENCE_UI.md).


## Current JSR implementation — 2026-11-09

The approved original-JSR / Hong Kong underground-radio direction is now live. Generated AFTERHOURS lettering, sticker Buttons, a compact radio clock and empty health frame decorate native live controls; no concept screenshot is used as an interactive background. Native OptionButton and CheckButton surfaces stay quiet and readable. Labels remain upright, bundled, Traditional Chinese / English, with explicit focus and outlined shortcut text. All title, roster, settings, pause and result screens use the same theme owner.

World-only postprocessing samples a 640×360 nearest grid; UI and font rendering remain at the logical 1280×720. This is deliberate visual pixelation, not an internal-resolution performance claim. A persisted Retro low resolution toggle is available. F2 retains its effects/pacing purpose and does not change this aesthetic preference.

Four profiles now differ in speed, actual move data, energy gain and procedural silhouettes. Fighter 4 scale is 1.98 vs 2.1 (~94%); this overrides the historical 1.4 value below. Animation selection expands from 14 to 19 licensed CC0 clips; distinct kicks/hammer/drive are authored overlays, not four newly downloaded full movesets. Berlin is the menu song; Groove District is the fight/training/Demo song. See [JSR_RUNTIME.md](docs/JSR_RUNTIME.md).

## Charged cannon — 2026-11-09

[CHARGED_CANNON.md](docs/CHARGED_CANNON.md) adds a 75-energy W+L commitment with a longer windup, double-palm release and muzzle-aligned beam after real contact. Normal L remains. Cannon, meteor and counter use low, downward and reverse-orbit camera treatments respectively; launch has its own coiled/uppercut pose. These are shared moves and procedural poses, not character-specific animation assets.


## Combat rhythm update — 2026-11-09

[COMBAT_RHYTHM.md](docs/COMBAT_RHYTHM.md) defines the latest shared combat clock and longer red-stage cuts. Light strings establish flow; launch/parry/burst use distinct hold, 0.22x slow motion and accelerated release. Full-screen shutters, contraction rings and release lines replace continuous clutter. Camera orbit, roll and FOV follow the beat. F2 restores normal pacing. Goggle fighter 4 is 2/3 of its previous height without rewriting the source model.


## Four-character roster — 2026-11-09

The title now offers Fighters, with independent player/rival OptionButtons, a live world preview and saved choices. Preview uses the existing left-side match-card layout, leaves the right side undimmed and moves the camera slightly closer. These are shared-moveset character models; character-specific abilities and a full cinematic selection flow remain future work. See [docs/CHARACTER_ROSTER.md](docs/CHARACTER_ROSTER.md).


## Current combat update — 2026-11-09

[docs/RUSH_REWORK.md](docs/RUSH_REWORK.md) is the current main-game contract: hold J for confirmed ground/air strings and paid pursuit, K launch/slam, L burst. The pressure-choice system remains in its dedicated lab. F12 is an endless live duel, with compact restart/exit controls and no chapters. Red-stage skills, BREAK and KO use actual actors against a temporary flat environment; KO removes the HUD and changes the camera. F2 restores the ordinary street presentation. Older lab-only/chapter descriptions below are historical.


This is a native Godot 4 game, with a playable Hong Kong street as its setting. The maintained game/world design is [docs/DESIGN.md](docs/DESIGN.md); current mechanics are in [docs/PRESSURE_EXCHANGE.md](docs/PRESSURE_EXCHANGE.md). The user requested a full UI improvement on 2026-11-09 and allows scene changes. Public Web publishing remains opt-in.

## North star

A street fight should remain visible. Menus feel like underground-radio flyers at the edge of the crossing; fighting UI is an instrument panel, not a document. The world supplies the artwork. The distinctive device is the clipped end of bars and panels, echoing road markings and the sharp geometry of the scene.

## Runtime owner

`godot/scripts/combat/ui/ui_theme.gd` owns the palette, type and native control theme. `fight_hud.gd` owns fight layout and `ui/street_hud.gd` owns exploration layout in a 1280×720 logical coordinate system, scaling to the native viewport. `ui_text.gd` owns keyed Traditional Chinese / English copy. This is a native game, not an HTML application; no CSS or browser UI is added for this work.

| Token | Hex | Role |
| --- | --- | --- |
| NIGHT | #160c23 | Menu dimmer and deepest surfaces |
| INK | #20102f | Flat plates, text on light controls |
| PAPER | #fff1d0 | Main text and primary actions |
| MUTED | #d1becb | Supporting text |
| TEAL | #4acfe0 | Player, choice commitment, hover |
| CORAL | #ff765e | Rival, high-pressure state |
| GOLD | #ff6a00 | Energy, decision timer, match outcomes |
| EDGE | #62536e | Boundaries and empty meters |
| LIME | #d7f400 | Selection, live energy and signature accents |

Body: bundled OFL Noto Sans CJK HK subset, derivative family Afterhours UI HK. Display: bundled OFL Barlow Condensed Black Italic for the English brand, clock and large numerals. Both have local license/source records, with Chinese drawn through the CJK face. No platform-dependent font selection for the combat UI.

## Hierarchy

- Title: live world on the right, one left column with Fight, Free training, paired Kinetic rally / Air lab actions and Pressure dojo entry actions. Settings and instructions are separate pages.
- Fight: paired health, two energy segments corresponding to a 50-energy special, round wins and a central clock. Pressure stays small until it asks for a decision.
- Clash: three actionable native buttons, a readable cue, fixed countdown and a committed-choice state. Labels explain what each action defeats. Read-first drill has no timer.
- Practice: one short context label. Detailed input history and combo data are optional (F9).
- Pause/result: a contained native panel; retain the match context behind it. Settings/help own a bounded scroll surface with a persistent Back action outside that scroller.

## Behavior and accessibility

Native Buttons, OptionButtons, CheckButtons and HSliders retain keyboard behavior and visible focus. Mouse targets have hover/pressed/disabled states and a pointing cursor where active. A choice can be made by keyboard or pointer; both feed the same first-commitment function. A disabled choice cannot fire. Back restores the originating menu control; settings adjustment should retain focus and scroll position. Reduced effects applies to camera motion and hit/clash presentation. Language and audio levels persist locally.

Desktop keyboard/mouse is the supported interaction target. Verify 1280×720 and 960×540, Chinese/English, ordinary fight, read-first drill, active clash, pause, result, settings, help and open dropdown. Native Godot viewport tests replace browser-flow checks; web publishing and mobile controls remain separate work.

## Avoid

Full-width opaque control manuals during combat, unexplained decorative numbers, gradient/glow-heavy panels, tiny English-only controls, fake non-functional buttons, changing labels between pages, generated text inside scene signs, and pixel-filtered UI fonts. Scene signs remain blank until user artwork arrives.

## Kinetic presentation extension

The practice-only rally and comic staging are specified in [docs/KINETIC_OVERDRIVE.md](docs/KINETIC_OVERDRIVE.md). A world grading CanvasLayer sits below the unchanged HUD; the drawing pass adds bounded edge rays and a center opening around the fight. F2 disables grading, echoes, shake and zoom. A short confirmed KO finish precedes the result panel, with Enter available to skip. The title's native action stack keeps space above the footer and fits without mandatory scroll.

The practice-only Air lab (F11) is specified in [docs/AERIAL_STREET.md](docs/AERIAL_STREET.md). Its context panel replaces the pressure gauge; live air phases, chase eligibility/cost and a short move route stay visible. Rally and Air buttons share one row to keep the title free of forced scrolling.

## Air reversal iteration

The aerial lab now includes a read-first air counter dojo: F11 → F8 → K, then Shift and J/E. See [AIR_REVERSAL](docs/AIR_REVERSAL.md). The 18-tick hold retains world positions; a 10-tick kick windup permits evasion.

## Two-agent demo

F12 starts the two-agent showcase: 23 labeled presets plus real AI command decisions, free exchange and a knockout. Visible scripted-demo labeling distinguishes coverage from competitive AI. The existing title footer row now pairs Demo and Explore without increasing menu height.

## Forgiving defense

Default defense now favors readable success: 12-tick ground/air parries, 36-tick earned counter cue, 14-tick input buffer, 30-tick air choice and 36-tick pressure decision. Success copy reports actual blocks and contacts; it never substitutes fake damage. See docs/FRIENDLY_DEFENSE.md for current values overriding earlier timing notes.
