# 場景、UI 與近身交鋒完善

本輪只更新 `codex/street-combat` 的 Godot 原始碼；不更新公開 Web。已完成超過三小時的累計互動開發與驗證，中途等待使用者繼續的空檔不計入；工作段見 [worklog](evidence/extended-polish/worklog.json)，運行觀察見[統整數據](evidence/extended-polish/stability.json)與[曲線](evidence/extended-polish/stability.png)。

[主選單前後](evidence/extended-polish/ui-before-after.jpg) · [招牌前後](evidence/extended-polish/facade-before-after.jpg) · [原生主選單](evidence/extended-polish/candidate/01_title_zh.png) · [新版設定頁](evidence/extended-polish/ui-review/1280x720_settings_top.png)

## 藍樓招牌

原本 2.35 × 8.2 m 的直牌是前輪新增的立面填充，佔用住宅窗列的位置，缺乏清楚的地舖對應。本輪移除它，補回第四列窗戶與風化細節。留白招牌改為地舖上方 1.81 × 0.43 m 的橫向位置，約高 3.46 m；`BlueCornerShopSign` 節點保存貼圖尺寸標記，等使用者供圖。沒有臆造中文字。兩側新增的低矮活動圍欄對應格鬥場邊，並避開斑馬線主要活動範圍。

## 操作與 UI

- 預設繁體中文，可在設定切換 English；所有固定文案集中於 `ui/ui_text.gd`。
- 主選單使用實時街景、原生焦點按鈕與兩層資訊；設定／操作頁可捲動，返回鍵固定。
- 戰鬥保留血量、能量、勝局、時間和交鋒壓力；輸入／連段資訊在練習時按 F9 展開。
- 對峙 J／Shift／E 可直接點按，首個選擇鎖定；練習有不限時閱讀與「開始」按鈕。
- F1 設定、H 操作，對戰中進入會暫停；Esc 返回再繼續。音樂與音效獨立音量保存，滑桿延遲合併寫入。
- F6 街區遊走使用同一套字體、語言與收起式提示，H 展開完整操作，可按右上角返回；M 靜音及音效音量也套用到飛機聲。
- 近身追鏡拉近，角色姿勢較清楚；拉開距離後自動退遠，跳躍／兩側場邊的角色包絡投影均避開 HUD。
- 結算時重新開始演出時鐘，短暫受擊反白會退去；勝出／落敗／平手均檢查，展示清理保留凍結的模擬資料。
- 字體含 OFL 繁中子集與 DejaVu 粗體，授權見 `references/ui-fonts/`；UI 契約及視覺規格見根目錄 `UX-CONTRACT.md`、`DESIGN.md`。

## 新增近身選擇

G 投技破解普通防禦，近距離、11 tick 起手、12 傷害、60 tick 冷卻；不能抓空中或受擊中的對手。看見伸手後按 G 拆投，或跳開／閃避。投技會失去防禦保護，普通攻擊可中斷；不把投技變成追擊連段的無解解法。

重擊高速撞到場邊可反彈一次，不額外扣血；E 可在短時間內以 20 能量受身離開。AI 同樣支付能量並有反應延遲。這是可見活動圍欄內的場邊機制，並非背景大廈破壞。

普通／挑戰 AI 的對峙姿勢可能是假動作（按同回合對峙序列每四次一次／每兩次一次），真正選擇在玩家輸入前已承諾；放鬆與所有練習保持提示可信。結算會標明假動作，設定與操作頁解釋規則。

## 場景繪圖

僅在格鬥背景把支援 toon shader 的 219 個靜態 BoxMesh 合為 16 組 MultiMesh，保留原節點、UV、硬邊、材質參數及碰撞，動畫飛機與角色不參與。可用 `static_batches_enabled=false` 比較；F6 街區遊走及 B 材質比較不變。

同相機原生擷取、繪圖統計及差異資料見 [static-batches](evidence/extended-polish/static-batches/)。這些是在雲端 llvmpipe 的實測，不能當成使用者顯卡的 FPS 保證。無視窗 Dummy renderer 不提供 MultiMesh transform readback，因此批次幾何檢查必須用原生 Compatibility 視窗執行。

固定交手機位從 978 降至 311 次繪圖呼叫，寬景 1045 → 351；批次較粗的剔除也讓提交三角面略增，因此只把這結果當成繪圖呼叫的改善。四個機位的 PNG 差異小於 0.14% 像素，但不是逐像素完全一致；幾何世界包絡、硬法線、UV、材質參數及碰撞另有 13 項原生檢查。

## 實際檢查

- [規則與整合 374 項](evidence/extended-polish/final-suite/headless/summary.json)；包含 20,000 步可重播混合戰鬥，本輪自然出現 18 次對峙。
- [原生介面與輸入 104 項](evidence/extended-polish/final-suite/native/summary.json)；最後捲動條調整再以 [53 項針對性檢查](evidence/extended-polish/final-suite/slim-scrollbar-native/summary.json)確認。
- [實際 X11 視窗失焦 7 項](evidence/extended-polish/focus-flow.json)、[512 次頁面／語言切換](evidence/extended-polish/ui-lifecycle.json)、[19 份執行腳本嚴格編譯](evidence/extended-polish/strict-compile.json)。
- [72 場打法診斷](evidence/extended-polish/combat-styles.json)，共 64,269 步，狀態／資源／位置均有界；它不是真人平衡性結論。
- [20 分鐘原生輸入觀察](evidence/extended-polish/native-input-soak/complete.json)：31 回合、13 場先取兩勝、6,698 次鍵盤轉換事件、27,670 次實際 physics tick。走正常遊戲的結算／重賽和設定暫停流程。
- [原有 33 個二進位資產完整性](evidence/extended-polish/source-preservation.json)；新字體的來源與授權獨立記錄。
- [結算演出 15 項](evidence/extended-polish/result-presentation.json)，無視窗及原生模式均通過；補修後另跑 [69 項相關回歸](evidence/extended-polish/final-suite/result-fix/summary.json)。

部分舊快速測試在首幀渲染／實際混音完成前便退出，留下清理訊息。已在測試工具加入首幀 draw fence 及真實時間的混音清理；[渲染重測](evidence/extended-polish/final-suite/native-cleanup/summary.json)與[音訊重測](evidence/extended-polish/final-suite/audio-cleanup/summary.json)通過且不再有該些退出錯誤。保留原始失敗／診斷紀錄，不把它們改寫為成功。軟體 GL 的 V-Sync 提示仍屬此環境限制。

小視窗與 4:3 的[英文畫面](evidence/extended-polish/ui-review/captures.json)保留實際 window size、影像大小及 canvas transform。PNG 是渲染內容，不含作業系統外框／黑邊；4:3 的留邊偏移另以原生滑鼠事件確認，沒有把街景拉長。

## 動作預覽

[投技 GIF](evidence/extended-polish/previews/throw.gif)／[MP4](evidence/extended-polish/previews/throw.mp4) · [場邊受身 GIF](evidence/extended-polish/previews/edge_recovery.gif)／[MP4](evidence/extended-polish/previews/edge_recovery.mp4) · [分段畫面](evidence/extended-polish/previews/combat-contact-sheet.jpg)

以上是 Godot 固定步進擷取後編碼：每張前進兩個 60 Hz 模擬 tick，90 張編成三秒預覽；GIF 縮為 640×360，MP4 保留 960×540。它們不是即時 FPS 量測、真人錄影或音訊收聽。

## 重現

先在 repo 根目錄匯入，再執行適合環境的檢查；新 runner 會備份／恢復既有證據，當輪結果放到指定新目錄。

```sh
godot --headless --editor --path godot --import --quit
python tools/verify_game_polish.py --mode headless
python tools/verify_game_polish.py --mode native
```

原生模式需要可用視窗系統，Linux 可指定 `DISPLAY` 與 `LIBGL_ALWAYS_SOFTWARE=1`。`--only verify_game_ui,verify_ui_input` 可針對變更重測。不同機器的預設輸出放在帶時間戳的新目錄，不會自動加入 Git。

## 驗證界線

香港時間 11 月 9 日 04:03，環境重新連線後，既有 Xorg／Godot 程序已停止；日誌明確顯示 X 連線被關閉。舊版本基線留下 155.3 分鐘觀察，當時候選版本留下 30.1 分鐘觀察，但兩者都沒有完成標記，不能當作連續長測通過。所有資料與中斷訊息均保留。

同一份 `b6e439b` 另開的[恢復後觀察](evidence/extended-polish/candidate-resumed/complete.json)已完整完成 1,800.025 秒：21 次回合重開、7 次設定／語言循環、5 次受身；孤兒節點峰值為 0，暖機後物件數保持穩定。其後的 `a238e3e` 只補修結算演出時鐘與反白，另有 15 項原生檢查和 69 項相關回歸；不把先前長測說成新修正已連跑一小時。

原生 Godot 截圖、注入鍵鼠事件、模擬規則及長時間自動觀察會分別記錄。自動輸入不是人工手感驗收，長測 Timer 在軟體渲染下受實際幀率限制；不聲稱 60 FPS 玩了同等時間，也未操作使用者電腦。現有音訊沿用有授權素材，本輪靜音自動測試不能代表已人工收聽。

Timer 觀察的舊欄位 `matches` 實際計算結算後的回合重開，不能當成完整先取兩勝的場數；真正場數見 native-input-soak。中途因 UI 微調而停止的候選觀察另放在 `candidate-v*-smoke`，不列為已完成長測。

真人手感、目標顯卡及 AI 難度仍需調校。打法診斷顯示部分固定輕拳節奏能壓制挑戰 AI；這輪不以少量機器對局把難度當成已定級。兩位角色仍共用現有模型與動作庫，投技是在 CC0 全身動作上加方向調整；不是兩套完成的獨立角色。
