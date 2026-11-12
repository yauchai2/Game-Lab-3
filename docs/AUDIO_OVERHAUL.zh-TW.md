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

## 音樂（Starjunk 95，Alan 提供，允許自由剪輯）
- 剪輯器：`tools/build_music_loops.py`（原曲 mp3 不入庫）。小節對齊、接縫 12 ms 等功率交叉淡化，loudnorm I=-17。出處與切點見 `godot/audio/music/provenance.json`。
- 戰鬥 pool（每場新比賽輪流，暫停／回合間不換曲）：`fight_a_drop`（Beat Keep Rockin 第一段 drop，140 BPM、16 小節）→ `fight_b_groove`（State Your Name 主段，125 BPM、16 小節）→ 既有 Groove District。
- 主選單：沿用 Berlin。結算畫面：`result_breakdown`（Groove District 第 24–31 小節 breakdown，8 小節循環）。
- 開場動畫的配樂不在此改動（PR #10）。

## 驗證（誠實說明）
- `godot/tools/verify_combat_sfx.gd`：32/32（載入、輪替、暫停保曲、結算換曲）。
- `verify_unified_audio.gd` 引擎混音 PCM 擷取：無削波。
- `verify_music_audio.gd` 這套舊測試在改動前就是 12/20，現為 13/20；失敗項是舊斷言（假設兩曲固定、暫停會 pause 串流）。未修改。
- **沒有人耳驗證**：Claude 聽不到聲音，新音效只以頻譜數字（高頻能量、attack 時間）對照舊版調整；實際聽感、Mac 真實喇叭、音樂接縫、曲目輪替的觀感都需要 Alan 試聽。

## 重擊／大招（Alan 要求暴力誇張）
heavy×3、slam×2、launch、release（特殊／超載釋放，爆炸前有 0.2 s 反向吸氣）、charge（電弧劈啪 + 上升音）、ko 全部改為多層疊加：2–3 層真實拳擊錯開 20–40 ms、真實爆炸本體、0.3–0.7 s 低頻下墜轟鳴、衝擊波噪聲和較長殘響（KO 2.0 s，三重爆炸 + 人體倒地）。起音的脆裂層刻意放在轟鳴之前，避免整體變悶。這些仍只以頻譜／包絡數字檢查，沒有人耳驗證。
