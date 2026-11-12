# 開機劇情開場（18 秒六鏡，即時 3D）

2026-11-11，依使用者提供的參考影片、六格分鏡及 18 秒鏡頭表製作。分支 `claude/project-thread-frl810`，草稿 PR 指向 `codex/combat-escalation-next`（基線 e725c99）。未合併、未更新公開 Web。

## 流程

啟動遊戲 → 18 秒開場（可跳過）→ 主選單 → 開始故事 → 第一章。

- 只在「這個場景就是正在執行的遊戲」時自動播放（`get_tree().current_scene==self`），工具／測試自行 instantiate 場景時仍直接進主選單，既有測試不受影響。
- 預設只在第一次啟動播放，看完或跳過後寫入 `user://neon_lab/story_opening.cfg`（與 progression.cfg 同目錄、獨立檔案，不改 XP 存檔格式，也不與 PR #8 的 `story_cleared` 衝突）。`story_opening_every_boot=true` 可改成每次啟動都播。
- 主選單 FREE PLAY 頁的 `WATCH OPENING` 可隨時重看（原本埋在 SETTINGS 最底，已移走，不重複放）。看完回主選單。
- Enter／Space 跳過，Esc 暫停／恢復，F2 即時切換減少特效，M 靜音。開場期間其他按鍵不會啟動任何模式。
- 「真正第一拳」留給之後「開始故事」的黑衣人上門短動畫，本輪未做。

## 六個鏡頭

| 時間 | 鏡頭 | 畫面 | 聲音 |
|---|---|---|---|
| 0–3 | 城市醒著 | 從高架列車旁俯衝，穿過電線落向街角與維修場；魚眼、放射模糊、速度線 | 列車轟鳴、街聲、俯衝風聲；主選單曲當作地下電台逐漸清楚 |
| 3–6 | 四人的生活 | 橫移加兩次甩鏡：RIVET 修車、LOOP 搞音響、HUSH 喝飲料；角色名牌 | 棘輪、音響雜訊、吸管。LOOP：「件貨呢？」 |
| 6–9 | ZIP 回來了 | 貼地廣角鞋底踏入、抬鏡露出 ZIP 與黑箱；箱子砸桌、工具震起、煙塵、短震 | 腳步、低音鼓與金屬同時砸下。ZIP：「到咗。」 |
| 9–12 | 送錯貨 | 兩個箱扣彈開，硬切魚眼俯拍：兩件槍形裝備、清單、四人停住；日光燈閃爍 | 9.75 秒音樂抽走，只剩燈管與箱扣回音。LOOP：「……我買音響喎。」 |
| 12–15 | 有人來收貨 | 黑車煞停、三門齊關、三人同步踏步、推近領頭人墨鏡反光與拉手套 | 煞車、車門、鞋踏、手套，逐步收緊成節拍，低頻上升 |
| 15–18 | 標題落下 | 由箱內仰拍箱蓋壓向鏡頭，黑場定格 0.1 秒撞擊畫面，切入黑白城市、桃紅天空、四人純色剪影與 AFTERHOURS | 合箱疊金屬重擊與低音爆發，音樂隨標題回來並直接接主選單 |

## 擁有者與檔案

- `godot/scripts/combat/cinematic/story_opening.gd`：唯一導演。無狀態時間線 `sample(t)`、鏡頭、鏡頭後製、字幕／名牌／漫畫線、存檔旗標、音樂 duck。`clear()` 還原相機 transform／fov／near／far／environment、街景與人物可見性、lens、score 及 duck。
- `godot/scripts/combat/story_opening/stage.gd`：程序化場景（街道、高架與列車、樓群、維修場、機車、音響、沙發、黑箱、黑車、路人、標題天台）。沿用既有貼圖與 PROP／VEH 包裝場景。
- `godot/scripts/combat/story_opening/actor.gd`：演出角色。包裝既有 FighterVisual（四位主角原 GLB 與修補版黑衣人，原檔不動），無狀態取樣共用 CC0 動作再疊加肢體瞄準與雙骨 IK。
- `godot/shaders/story_opening_lens.gdshader`：魚眼、放射／橫向模糊、色散、閃白、反相、標題的黑白＋純色 ink 分級。
- `godot/audio/story_opening/score.wav`＋`cues.json`：18 秒配樂加音效，由 `tools/build_story_opening_audio.py` 產生（seed 20261112）。音樂是使用者提供的 Starjunk 95〈Beat Keep Rockin〉（`godot/audio/user-tracks/beat_keep_rockin.ogg`，140 BPM，3 秒＝7 拍）：0–3 秒為第一次 drop 前的鋪陳經收音機濾波，3.0 第一次 drop，6.0–7.5 沉底，7.5 倒帶抽空，8.0 黑箱重砸時同一 drop 再下，9.75 tape stop 抽音，12.0–16.1 第二段鋪陳由遠而近，16.1 標題接第二次 drop。音效：合成、既有 Kenney CC0、BigSoundBank CC0 節選（`references/story-opening-audio/`）。主選單曲開場期間靜音，17.6 秒起淡入，transport 從不停止。
- `godot/assets/fonts/StoryOpeningHK.otf`：字幕用 Noto Sans HK Bold 子集（OFL），`tools/subset_story_opening_font.py` 產生，來源雜湊見 `references/ui-fonts/story-opening-subset.json`。
- 改動既有檔案：`fight_session.gd`（建立、開機判斷、輸入攔截、`replay_story_opening`）、`fight_hud.gd`（`opening` 畫面不建選單、繪製轉交、設定頁重播鍵）、`combat_motions.gd`（一行：演出角色可用 `cinematic_clip` 指定動作，戰鬥不會設定此鍵）。`fight_simulation.gd`、XP、原始 GLB 均未改。

## 驗證與限制

- `godot/tools/verify_story_opening.gd`：37/37 通過（Godot 4.6.3 Linux、Compatibility／llvmpipe、Dummy 音訊），結果在 `docs/evidence/story-opening/`。
- 以 Movie Maker 模式實際從啟動錄下整段開場到主選單（含混音），抽格見 `storyboard.jpg`；第二次啟動直接到主選單見 `second-launch-menu.png`。
- 回歸：verify_reference_ui 37/37、verify_ability_draw 69、verify_black_suit 35 通過；verify_round_flow 23/24，唯一失敗項在未修改的 e725c99 上同樣失敗。
- 未驗證：真人實聽（混音平衡、抽音與標題重擊的觀感）、使用者本機 Mac／GPU／Godot 4.7.2、4.7.2 warning-as-error 工具。對白只有字幕，沒有配音。
- 與參考影片的差異：場景為程序幾何而非影片的精細美術；角色用現有動作庫加程序姿勢，沒有手 K 表演；影片結尾的室內第一拳依鏡頭表留到故事開始。
- 之後接 PR #8：開場在主選單之前，與 STORY 入口互不相干，合併時 `fight_hud.gd` 設定頁那一行可能需要手動對齊。

## 對照參考影片 v4（2026-11-12）

Alan 指出開場未完全跟 03e5fa13 參考影片：場景欠缺、有不相關加入。本輪調整（分支 `claude/opening-fidelity`）：

- **色調**：舊版是淺紫灰平面光；參考影片是暗黃昏＋髒舊車房。`stage.gd` 的 `TONE=0.72` 壓低所有程序材質亮度，太陽改暗粉色 0.85，環境光改 0x9a86b4 / 0.62，車房燈提高到 1.7。
- **新增（對應影片）**：柱子上的便利貼／馬賽克貼紙（程序貼圖）、粉紅星芒海報（取代原塗鴉貼圖）、生鏽工作台貼圖、層架瓶罐、Boombox、抽屜櫃、旁邊小桌與碗、地上紙片／電線／警示地墊、牆上抽風扇、紅綠燈（5 組）、街上紅色小車、手提箱內橙色彈匣。
- **移除（影片沒有）**：漫畫字 DOM／BAM!／SKRRRT／KRAK!／KLAK、角色名牌（RIVET／LOOP／HUSH／ZIP 滑入牌）。保留衝擊光芒但無字。
- **字幕**：改成影片樣式（小白字說話者名稱在上、對白置中，無黑框）；英文副字幕保留。
- **未改**：18 秒六段結構與時間、第一拳留到開始故事、音樂與音效、標題剪影。
- **對白差異（待 Alan 決定）**：Alan 的 18 秒表寫「件貨呢？／到咗。／……我買音響喎。」，影片畫面字幕為「開工？！…」等；本輪沿用 Alan 的表，未改字。
- Tripo 資產清單：`docs/STORY_OPENING_TRIPO.zh-TW.md`（尚未有新模型，runtime 仍是程序低模）。
- 驗證：Linux llvmpipe，非 Mac／真人／真聲音驗證。
