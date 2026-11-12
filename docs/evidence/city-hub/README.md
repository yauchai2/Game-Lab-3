# City hub evidence

Godot 4.7.2 Linux, Compatibility renderer, Mesa llvmpipe, Dummy audio. This is an implemented prototype with placeholder art, not final Hades-like content or a hardware performance/human playtest claim.

- [Safe block](safe-block.png), [main menu](main-menu.png), [city map](city-map.png), [skills](skills.png), [talent circuit](talent-circuit.png), [dealer](dealer.png), [radio](radio-story.png), [actual encounter](expedition.png).
- [Rules](rules.json) / [log](rules.log): 62 checks. Durable progress, one settlement, corrupt-save recovery, rollback, pity, skill gates/held-J, actual combat stats, six-region settlement, four heroes clearing district one on Easy through ordinary commands without gear/healing. Save errors use explicit fault injection. Higher-region progression uses explicit completion fixtures.
- [Native input](native.json) / [log](native.log): 17 checks. Real pointer main entry/map/shop/talent/skill, WASD/E/Enter, actual J damage, return/death/isolation. Completion and shop funding fixtures are explicitly marked in the runner. Captures show the runtime viewport.
- [Strict warnings](strict/strict.json) / [new city scripts](city-strict.log): 11 existing and 3 new scripts compile with four warning categories fatal.
- [Regressions](regressions/summary.json): original three-wave M1 37, double jump 62, combat 34. Test copies only redirect output paths; source assertions are unchanged. No historical evidence overwritten.

226 accepted checks, no ERROR/SCRIPT ERROR in accepted logs; native VSync unsupported warning is retained. Initial display authorization, a camera/test locator failure and intentional fault logs are preserved under initial-attempts. A later percentage-formatting error was corrected; that intermediate log was not retained. An intermediate native run caught an off-screen shop pointer; dealer actions were moved above the fold and the test now scrolls controls into view. Accepted results supersede those attempts.

Run `godot --headless --path godot --script res://tools/verify_city_campaign.gd`; use a real native display for `verify_city_native.gd`. The native runner uses an isolated verification profile; it never modifies the player's campaign save.
