# Native game UI contract

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
