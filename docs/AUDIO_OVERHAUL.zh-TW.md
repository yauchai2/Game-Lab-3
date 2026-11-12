# 全遊戲音樂與戰鬥音效重做（2026-11-12）

## 為什麼悶
量測舊版 Kenney 拳擊音效：頻譜重心約 85–160 Hz、峰值要 20–40 ms 才出現、6 kHz 以上幾乎沒有能量，加上低頻都在 0–150 Hz，所以打擊聽起來像隔著牆。揮拳／衝刺也是 76–93 Hz 的低頻咚聲。

## 新音效（2026-11-12 第二版：真實 CC0 錄音 + 程序合成低頻）
Alan 要求「真正格鬥遊戲的音效」，第一版純合成聽起來仍像合成器，所以改用 BigSoundBank（Joseph Sardin，CC0）的真實錄音：真人出拳（Punch #5–#14）、巴掌／拍擊、風切（Whoosh）、人體倒地、爆炸。因為遊戲是徒手街頭格鬥，已移除劍、鐵砧、鈴、鑼、鈸、玻璃等不合題材的音源（Alan 2026-11-12 指正）；格擋／格擋成功／破防改用拍擊、肉體與衝擊聲。另以 Alan 提供的 Lethal League Blaze 影片只量測打擊瞬間的頻譜（中位數 0–150／150–500／500–2k／2–6k／6k+ Hz = -2／-10／-9／-11／-18 dB，重心約 725 Hz）來校準中頻量感，不取樣其聲音，經 `tools/build_real_sfx.py` 切取最強起音、疊層、補高頻齒擦與低頻重量後輸出。來源 id 與授權見 `godot/audio/sfx/SOURCES.md`。原始錄音不入庫（腳本按 id 下載）。以下為第一版合成器說明（仍用於能力類音效與低頻層）：
- 產生器：`tools/build_combat_sfx.py`（NumPy + SciPy + ffmpeg），輸出 `godot/audio/sfx/*.ogg`（44.1 kHz，Vorbis q6）。
- 結構：每個打擊 = 1–2 ms 瞬間 click + 2–11 kHz 脆裂層 + 中頻拍擊層 + 較短的低頻身體；峰值在 2 ms 內出現。
- 18 種音效全換：hit×3、heavy×2、block、parry（鐘響＋金屬）、guard_break（玻璃碎）、swing×2 與 dash／chase／launch（掃頻風聲）、step×2、land、jump、release、ko、charge、slam、rally、sub。
- `fight_audio.gd`：優先載入新檔，缺檔時退回 Kenney CC0，再退回舊合成音。SFX 音量基準 -4→-3 dB，SFX bus limiter 由 -6/-6 改為 ceiling -2 / threshold -3，避免把瞬間峰值壓平。
- 保留 `cinematic_duck`、`music_gain_db` 兩個屬性（開場動畫使用）。

## 音樂（2026-11-12 更新：全部改用 Alan 提供的合輯 mp3）
來源：「High-Energy Hip Hop Breakbeat Playlist — Music Inspired by Jet Set Radio」（Alan 提供，約 80 分鐘；曲目作者與授權未知，視為使用者提供並授權用於本遊戲，**不聲稱 CC0**，檔案不入庫）。這份合輯前 ~40 分鐘整段重複一次，只用 0–2430 秒。
- 分析：16 秒視窗估速度 → 11 個穩定速度段（100–131.5 BPM，整數 BPM，數位製作）→ 以 0.01 BPM 擬合節拍格線 → 以每小節 mel 相似度找「N 小節後重複」的段落當循環（相似度 0.85–0.99），接縫 12 ms 等功率交叉淡化，接縫處波形跳變不大於該檔 99.9 百分位。切點表在 `tools/build_playlist_music.py`，每檔時間資訊在 `godot/audio/music/music.json`。
- 情境：主選單 `menu`（第 1 首 116 BPM：4 小節前奏 + 16 小節循環）、戰鬥 `fight_a`（130 BPM）、`fight_b`（131.5 BPM）、`fight_c`（113 BPM），每開新一場輪流；結算 `result`（110 BPM、能量較低的段落）。每檔約 0.5–0.7 MB。
- **前奏只播一次：** 前奏與循環放在同一個 OGG，Godot 用 `loop_offset` 只循環 16 小節循環段。第一次進主選單從 0 秒（前奏）開始並寫入 `user://neon_lab/music.cfg`；之後每次進主選單，從循環段的隨機小節線開始，不再聽前奏。設定頁新增「重播音樂前奏」。
- 戰鬥曲永遠從小節頭開始；回合結算不換歌，整場結束才切結算曲。
- 舊的 Berlin／Groove District／WEV／Level 1 不再播放，檔案仍保留於 repo（`user-tracks/` 等），僅作為新檔缺失時的 fallback。
- 開場動畫（PR #10）自己的音訊未改；它只調整 `cinematic_duck` 與 `music_gain_db`，選單音樂在開場期間靜音播放，所以第一次的前奏會在開場動畫中被消耗，不衝突。

## 驗證（誠實說明）
- `godot/tools/verify_combat_sfx.gd`：49/49（音效載入、輪替、暫停保曲、結算換曲、前奏只播一次、隨機循環起點、前奏重播）。
- `verify_unified_audio.gd` 引擎混音 PCM 擷取：無削波。
- `verify_music_audio.gd` 這套舊測試在改動前就是 12/20，現為 13/20；失敗項是舊斷言（假設兩曲固定、暫停會 pause 串流）。未修改。
- **沒有人耳驗證**：Claude 聽不到聲音，新音效只以頻譜數字（高頻能量、attack 時間）對照舊版調整；實際聽感、Mac 真實喇叭、音樂接縫、曲目輪替的觀感都需要 Alan 試聽。

## 重擊／大招（Alan 要求暴力誇張）
heavy×3、slam×2、launch、release（特殊／超載釋放，爆炸前有 0.2 s 反向吸氣）、charge（電弧劈啪 + 上升音）、ko 全部改為多層疊加：2–3 層真實拳擊錯開 20–40 ms、真實爆炸本體、0.3–0.7 s 低頻下墜轟鳴、衝擊波噪聲和較長殘響（KO 2.0 s，三重爆炸 + 人體倒地）。起音的脆裂層刻意放在轟鳴之前，避免整體變悶。這些仍只以頻譜／包絡數字檢查，沒有人耳驗證。

## 介面音效與音樂切換修正
- 新增 5 個介面音效（ui_move／confirm／back／toggle／pause，原創合成，短而乾）：滑鼠移入、鍵盤焦點、按下按鈕、切換開關、拖音量條、暫停。選單重建時的程式焦點 250 ms 內不發聲，且同類音效 55 ms 節流。
- 修正：回合結算（round_over）不再換歌，只有整場結束（match_over）才切到結算曲；再戰才輪到下一首戰鬥曲。
- 驗證：`verify_combat_sfx.gd` 42/42。`verify_focus_flow.gd` 的 "leaving the OS window pauses active gameplay" 在未修改的程式碼上同樣失敗，與本次無關。

## 第二輪：打擊更兇（Alan 回饋「音效還不夠兇」）
- 音源：重擊／重摔／KO 再疊一層降八度的拳擊（重量）；所有打擊類音效（hit／block／parry／guard_break／heavy／slam／ko／launch／release）在 `tools/build_real_sfx.py` 中先把前 150 ms 的 RMS 拉到目標（普通 -12 dB，重擊／KO 約 -9.5 dB），再 tanh 軟削波，讓聲音密而不只是尖。量測：普通擊 RMS150 約 -9～-13 dB、重擊約 -9～-10 dB（舊版約 -15 dB）。
- 混音：`fight_audio.gd` 對打擊類音效只保留 35% 的衰減（呼叫端原本要求 -6～-12 dB，使打擊壓在音樂下面），基準 -3→-1 dB；SFX bus 在 limiter 前加壓縮器（-14 dB、4:1、attack 1.5 ms）；重擊／重摔／KO／破防的音樂閃避加深到 9 dB 且延長到 0.34 s，普通打擊 5 dB。
- 音樂備選：額外 6 段循環放在專案檔案 `audio-overhaul/music-candidates/`（不在 repo），供 Alan 選曲。
- 驗證：`verify_combat_sfx.gd` 49/49；`verify_unified_audio.gd` 無削波。仍然沒有人耳驗證，響度與聽感需 Alan 試聽；若太吵或失真，調整點是 `IMPACT_TARGET`、`peak` 與壓縮器 threshold。
