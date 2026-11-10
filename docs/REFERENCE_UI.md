# Reference UI reproduction, continuous music and VFX review

2026-11-09. This replaces the previous approximate JSR UI and the old pause-silence policy. Public Web remains unchanged.

## Interface

The title uses the exact approved original PNG, with real native hit targets aligned to FIGHT, FIGHTERS, TRAINING, SETTINGS and AI DEMO. Other title actions are removed. Each invisible-text Button still has an English name, pointer cursor and keyboard behavior; the reference drawer supplies its visible focus. Enter dispatches the focused action instead of always forcing Fight.

Fighters uses four selectable cards with independent P1/P2 selectors. The full original goggles composition is retained for fighter4; the other three choices use newly generated matching sticker portraits on an emptied backplate. Native P1/P2 tags show the actual saved choices. The old SAME MOVES / SAME STATS claim is replaced with the real profile trait. All four maintain their actual model/profile; artwork does not change source rigs.

The combat HUD follows the reference proportions: headset badges, slanted paired health bars, orange center clock, compact HITS sticker, PAUSE target and cropped English command ribbon. Health, energy, time and combo count remain live. The50/75 thresholds follow the real energy data. The playable world remains the existing 3D scene, with the existing configurable low-resolution treatment; it is not the static HUD reference screenshot.

Settings, pause, help and result use the same orange/purple radio-board language with native controls and scrolling. English is now the default maintained interface; the old saved Chinese preference cannot silently override this screen design. Old lab/exploration keyboard entry points remain for specialist work but are not extra main-menu options.

The initial title matches the supplied art directly. A native1280×720 capture has mean absolute RGB differences around1.14/255 against Pillow bilinear scaling of the source (GPU sampling differs). This supports fidelity of that state, not a claim that every live HUD frame or every newly composed character state is pixel-identical to a still image.

## Music transport

Berlin and Groove District each retain a dedicated stream on two bounded AudioStreamPlayers. Title/play song changes crossfade over1.2 seconds; rapid navigation reverses an existing fade rather than restarting either audible head. Old decks stop only after becoming silent. Pause/help/settings lower the envelope toward−23dB vs play−13dB before the user level; returning restores gain smoothly. Music does not follow combat time scaling.

Pause, settings, resume, retry and mode changes do not pause transport. Explicit mute and zero volume silence the gain while the song continues. Song loop resources remain duplicates; original audio files/import flags are unchanged. Both decks release playback on scene exit. Dummy audio tests establish transport/gain behavior, not listening or a target-device mix.

## Attack review and changes

All13 attack identifiers were reviewed in actual swing/contact/release captures, plus each character's special/overdrive pair:19 real attack routes,57 staged captures. Legacy heavy is exercised in its actual lab mode because arcade K intentionally becomes launcher; it is not mislabeled as a launcher hit. Seven defense/movement samples are explicitly isolated rendering diagnostics, not fake gameplay success events.

The old generated combat atlases are no longer drawn. They had noisy edges and looked like detached stamps when combined with vector arcs. Retained source files are archival. The active renderer uses authored six-cel vector shapes: flat silhouettes, controlled cream cores and fixed per-move dimensions. Boxer shock stars, dancer twin crescents, bass angular waves and spark zigzags carry character identity. Their presence never adds damage.

Removed extra release arcs/ground rings and skeleton-stick echoes. Craters now come from actual hard landing/ground-bounce events, not an airborne hit projected to the floor. Red stages and hold/slow/release rhythm remain; reducing clutter does not remove the intended impact contrast. F2 remains available.

| Family | Reviewed moves | Art decision |
|---|---|---|
| Quick strikes | jab, cross, air_jab | compact contact core, brief directional arc |
| Kick/finish | finisher, heavy, air_kick, air_finisher | wider directional crescent, bounded debris |
| Vertical | launcher, meteor, air_counter | angled stroke; landing geometry only after real landing |
| Grapple | grab | compact hit shape, no giant airborne shock crater |
| Energy | special, overdrive | four authored signature families; hand/contact-aligned cannon |

## Validation

[Evidence and images](evidence/ui-replica/README.md):37/37 native UI, pointer/keyboard, popup, scrolling, F2 and continuous/crossfade music assertions;19/19 true contact routes,3 stages each. Existing combat headless144/144 and rhythm/red-stage native47/47 pass. Tests are injected, not human feel judgments.40 runtime scripts load. Premium static audit is auxiliary and does not establish Godot accessibility.

An early Enter path still forced Fight after keyboard navigation; it was fixed to dispatch the focused native action. Early manual portrait masks showed paper fragments and were replaced. An audio teardown warning was traced to replacing streaming resources; fixed dedicated-stream decks and a post-free mixer flush complete cleanly. Failed diagnostics are preserved, and historical evidence remains unchanged.

Source models, original image/audio files and the prior generated atlases remain byte-identical. Only source branch updates, no gh-pages deployment and no user-PC synchronization claim.
