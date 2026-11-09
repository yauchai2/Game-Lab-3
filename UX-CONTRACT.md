# Native game UI contract

## Current override: readable pixel typography (2026-11-10)

Keep the640×360 shared framebuffer. Minimum authored copy is24logical pixels; default body controls28, primary actions32 (12/14/16 internal pixel nominal sizes). `ui_theme.gd` owns these tokens. Use the14px/16px readable bitmap derivatives for body/small display text; large headings retain the original24px display source. The secondary panel is780×510 logical with14px item gaps and6px label line spacing. Source reference art remains; native large shortcuts, Pause and Enter/Esc hints replace the tiny baked text in those regions. Never solve readability by shrinking labels to fit: widen, wrap and scroll. See docs/UI_READABILITY.zh-TW.md for actual captures and hardware limits.


## Current override: unified pixel runtime (2026-11-10)

The complete world, UI, fonts and VFX composite at 640×360 with nearest integer viewport scaling. Controls retain 1280×720 authoring coordinates mapped to the internal framebuffer; pointer/keyboard mapping is tested at three window sizes. The former world-only retro toggle is retired. Display/body use locally generated binary-alpha BMFont derivatives of bundled Barlow Condensed Black Italic and DejaVu Sans Condensed Bold; these are JSR-inspired adaptations, not the official JSR font. Reference title art stays intact. Roster cards and hero use five isolated, bounded, low-resolution real-model SubViewports, updated at15Hz only on the roster page, with four different showcase poses. Menu focus has a short stepped pointer kick; reduced effects removes it. Audio has exactly two music decks plus ten effects voices, with named buses. Settings exposes Test Sound, Restore Sound and output status; silent title preferences show a recovery action. Transport continues through pause and mute. Details/evidence: docs/UNIFIED_PIXEL_RUNTIME.zh-TW.md. Earlier contradictory descriptions below are historical.


## Approved five-action reference flow — 2026-11-09

Current UI policy is [REFERENCE_UI.md](docs/REFERENCE_UI.md). Title has exactly Fight/Fighters/Training/Settings/AI Demo. Fixed English art may contain static labels, but each hit target is a real named native Button. Native focus selects the actual Enter action; background art is not an extra gameplay controller. Roster/Grid is owned by fight_hud.gd native Buttons, reference_art.gd paints it, simulation/preferences own P1/P2 choices. Dynamic HP/energy/time/combo still belong to native drawing and true data.

Settings retain native difficulty/partner dropdowns, sliders, focus and bounded scrolling. The old language dropdown/two character dropdowns are replaced by English and a four-card roster. Their old harnesses remain historical; verify_reference_ui.gd exercises current behavior.

Music policy overrides every earlier pause-silence/playhead clause: pause/help/settings duck rather than pause; mute/zero silence gain while transport advances. Context song changes crossfade over1.2s on two dedicated players. Reverse a rapid navigation fade; retire only a silent old deck. Gameplay pause still freezes simulation. Native checks assert transport and gain, not human audio acceptance.


## Current JSR native UI and profiles — 2026-11-09

The JSR direction is implemented in the canonical native theme/HUD/copy/session owners. Generated art decorates actual Buttons, bars and clock; all labels, HP, energy, time, combo counts and input remain live. Native settings/roster dropdowns retain keyboard/popup behavior. Energy thresholds are exact 50/75 markers on a continuous 0–100 bar. Roster shows the actual selected fighter traits and signature names; changes update both the live model and simulation profile, and persist. Four distinct profiles supersede the old shared-stats copy.

Retro low resolution is an independent persisted setting: nearest 640×360 world sampling beneath the high-resolution UI. Berlin plays at title; Groove District during play. Pause/settings preserve the playing song and playhead; returning to title switches to Berlin. Only one music player exists; looping uses a duplicate stream, leaving source resources unchanged.

Fighter 4 is slightly shorter (1.98/2.1). All characters retain shared basic inputs and defense windows. Character-specific startup/damage/reach/lift/speed/energy are owned by fighter_profiles.gd and resolved by the simulation; presentation reads the same move snapshot. Generated attack sprites are driven by real events and never cause independent damage. See docs/JSR_RUNTIME.md.

## Cannon input — 2026-11-09

W+L or Up+L snapshots the modifier at key-down and requests a 75-energy overdrive in arcade play. Ordinary L retains its 50-energy command. This is a committed fixed windup, not variable hold-to-charge. Pending cannon input survives cinematic holds and held J. Underfunded input reports 75 without spending energy; pause/reset/title clear presentation. A beam denotes actual hit release, not an independent projectile or automatic damage. F2 keeps the real move and reduced presentation.


## Shared pacing update — 2026-11-09

Main combat and Demo share a wall-time scheduler around fixed 60Hz simulation ticks. It holds both actors, slows to 0.22x, then releases at up to 2x; at most two steps per physics call. Pending input survives a hold. Pause freezes rhythm and red clocks; restart/title clear accumulated time; F2 restores one step, street and ordinary camera. Music stays at original speed. This changes real-time timing for both sides, not per-tick rules. Skill 1s, hit .65s, BREAK 1.1s, KO 1.2s, result 1.4s; Enter can skip results. Nonlethal timeout/draw never produces red KO.


## Roster — 2026-11-09

Title → Fighters opens two native four-item selectors with live model previews and persistence. Back returns focus to Fighters; the Fight action starts the chosen pair. Fight, practice and endless Demo retain those choices; changing a model is rejected outside the title. Both sides may select the same model. New GLBs use the existing moves and stats; the copy says so. Exploration keeps the original model. Model replacement clears per-instance materials, active limb scaling and retarget caches; combat simulation is untouched.


## Current Rush flow — 2026-11-09

Main gameplay authority is now [docs/RUSH_REWORK.md](docs/RUSH_REWORK.md) plus simulation; pressure choices remain a specialist lab. Hold J chains only confirmed legal attacks, K selects grounded launcher or aerial meteor, L queues a paid burst even while J is held. First-round energy allows L immediately. Landing protection and finite aerial limits preserve an escape.

F12 starts endless live AI combat. Only R/restart, pause/settings, F2 and F12/exit transport controls act on it; N and player attacks do not. No chapters or timed resets. Live hits and infinity replace round progress. Endless BREAK is an actual-hit presentation event, never a fake KO. Real KO alone ends a formal round.

Red-stage clock is visual-only: pause freezes it; F2/title/restart clear environment override, hidden city/shadows and bone enlargement. KO hides the HUD during its 0.64-second red stage, then restores the city before the 0.82-second result menu. Evidence: rush-rework/final-native and red-native. Earlier chapter/lab-only statements below are superseded.


Authoritative gameplay rules: docs/PRESSURE_EXCHANGE.md and simulation. This contract describes interface behavior; it does not override gameplay.

| Capability | Canonical owner | Source of truth | Allowed variants | Verification |
| --- | --- | --- | --- | --- |
| Select/Listbox | Godot OptionButton with shared Theme | ui_theme.gd / ui_text.gd | language, difficulty, partner | native keyboard and popup capture |
| Scrollbar | Shared Godot Theme | ui_theme.gd | bounded help/settings/practice panels | narrow capture, keyboard focus |
| Toast | HUD notice / localized event mapping | fight_hud.gd / ui_text.gd | outcome, information, unavailable energy | simulation-to-HUD integration |

## Flow ownership

Title offers Fight, Free training, practice-only Kinetic rally lab (F10) and Pressure dojo. Help and Settings use one page mechanism. From play, opening either pauses first; Escape returns to pause, then Escape resumes. From title or result, Back returns to that originating screen. Option popups consume their own Escape before page navigation. Back retains the originating action's focus. All settings have the same native control, label and persistence behavior regardless of entry screen.

A clash choice is committed through fight_session.commit_clash_choice by both keyboard and native Button. The first valid pending choice wins; subsequent keys/clicks cannot replace it. Read-first controls are disabled until K or Start triggers the actual heavy. Non-clash actions cannot be buffered through the decision window.

The pause menu's Restart names the affected scope; Reset training is separate. All are reversible game/session actions, not external publication. No extra approval dialog is added. Leaving play clears the correct simulation and presentation state.

## Locale and persistence

Traditional Chinese is the default; English is selectable and persisted. Translation is view-owned; simulation keys, log fields and game input identifiers remain stable. Fixed user-event notices are translated when rendered. Unknown diagnostic strings are not invented as translated game rules.

Music/effects levels update immediately in the native sliders; writes debounce rather than rebuilding the page on each drag. Language changes rebuild the page while retaining focus and scroll. Muting and reduced effects stay available via existing shortcuts.

Leaving a scene flushes a pending volume write. F6 exploration shares language, mute and effects volume; H expands its compact controls. Escape frees the pointer, and the native return button or F6 returns to the fight title. M in exploration also persists the shared mute state and cancels pending 3D flyby playback.

## Evidence boundary

The frontend-design-premium static audit primarily recognizes web source formats. It is recorded as an auxiliary static check, not proof of native accessibility. Godot import, GDScript strict compilation, project integration checks, real X11 viewport input, pointer callbacks, popup captures and native long-run telemetry provide the runtime evidence. Linux software rendering does not establish user-PC or target-GPU performance. No public site is updated by this work.

## Kinetic lab and finish

F10 starts the mutually exclusive practice rally; F5 returns to ordinary practice, F8 enters the original pressure dojo. A new Shift edge opens/replies to a parry, J commits a quick counter, and holding guard cannot repeatedly parry. The active lab panel replaces the ordinary pressure display and keeps owner, tier and timing visible. The lab does not offer the planned held-K or relay-throw branches yet.

The simulation confirms KO first. A bounded 0.82 second presentation precedes the result menu; Enter can skip to the proper next round or restart a completed match. Reset/skip/title transitions discard pending cosmetic effects and camera/grade state. Reduced effects bypasses the animated finish presentation and shows result controls immediately.

## Air lab

F11 starts practice-only Air lab with a standing partner; F5 exits it, F10 switches to the separate rally. Changing the partner in Settings preserves Air lab and pause. Space is a fresh jump command; S is a fresh fast-fall command. W/Down modifiers are captured at K-down so a quick release before the physics tick retains the intended move. The HUD distinguishes a chase costing 20 energy from ordinary dashing and the free manual jump chase; invalid chase attempts show feedback.

Air camera framing uses both players' vertical bounds and viewport aspect. The combo counter leaves room for the practice context. F2 keeps phase/owner prompts and basic poses while disabling strong stretch, spin, grade and shake.

## Air reversal iteration

Air counter dojo starts from F11 → F8. K begins/retries the read-first lesson; Shift arms a six-tick attempt costing 25 energy. During the 18-tick hold, J/E and native buttons submit the same first-choice lock. No choice defaults to escape. Pause freezes the hold; mode changes/retry clear pending choices and effects. See [AIR_REVERSAL](docs/AIR_REVERSAL.md).

## Two-agent demo

Demo uses F12 / native title entry. N advances, R restarts, Escape pauses, F12 exits. Three native transport buttons share those session actions. Gameplay keys and practice shortcuts cannot override either agent. Pause freezes the director, result advances after 2.5 seconds, mode changes clear effects/input, original partner preference survives. Existing F9 remains unchanged outside Demo.

## Forgiving defense

Earned parry feedback shows J to counter for 36 simulation ticks, frozen while paused. Queued J can start while Shift remains held; a released tap does not swallow Jump. Only a real damaging contact yields COUNTER SUCCESS; ordinary block earns NICE BLOCK. Air choice lasts 30 ticks, high-pressure choice 36; earlier timing descriptions are historical. F2 preserves these messages.
