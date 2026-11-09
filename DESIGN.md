# Afterhours — interface design

This is a native Godot 4 game, with a playable Hong Kong street as its setting. The maintained game/world design is [docs/DESIGN.md](docs/DESIGN.md); current mechanics are in [docs/PRESSURE_EXCHANGE.md](docs/PRESSURE_EXCHANGE.md). The user requested a full UI improvement on 2026-11-09 and allows scene changes. Public Web publishing remains opt-in.

## North star

A street fight should remain visible. Menus feel like the printed match card at the edge of the crossing; fighting UI is an instrument panel, not a document. The world supplies the artwork. The distinctive device is the clipped end of bars and panels, echoing road markings and the sharp geometry of the scene.

## Runtime owner

`godot/scripts/combat/ui/ui_theme.gd` owns the palette, type and native control theme. `fight_hud.gd` owns fight layout and `ui/street_hud.gd` owns exploration layout in a 1280×720 logical coordinate system, scaling to the native viewport. `ui_text.gd` owns keyed Traditional Chinese / English copy. This is a native game, not an HTML application; no CSS or browser UI is added for this work.

| Token | Hex | Role |
| --- | --- | --- |
| NIGHT | #0a2028 | Menu dimmer and deepest surfaces |
| INK | #102c34 | Flat plates, text on light controls |
| PAPER | #f4ead8 | Main text and primary actions |
| MUTED | #aec3c5 | Supporting text |
| TEAL | #57dfcc | Player, choice commitment, hover |
| CORAL | #ff785d | Rival, high-pressure state |
| GOLD | #eebd4c | Energy, decision timer, match outcomes |
| EDGE | #48636a | Boundaries and empty meters |

Body: bundled OFL Noto Sans CJK HK subset, derivative family Afterhours UI HK. Display: bundled DejaVu Sans Condensed Bold for the English brand, clock and large numerals. Both have local license/source records, with Chinese drawn through the CJK face. No platform-dependent font selection for the combat UI.

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
