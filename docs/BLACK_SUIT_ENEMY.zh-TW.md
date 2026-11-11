# 黑衣人：敵人與可重用演出角色

最新現況：[群戰與後頸／領帶修補](BLACK_SUIT_SQUAD.zh-TW.md)。runtime現用derived修補GLB，FIGHTERS另有SQUAD入口；下方保留首版整合紀錄，模型面數／材質及無群戰描述以最新頁為準。

2026-11-11，Asia/Taipei。使用者上傳 `tripo_convert_6bb9e9c2-dd66-4f86-864f-2ceab3aa0a09.glb`，要求接入遊戲作敵人及其他用途。本輪基於 main `738c740`，來源分支 `codex/black-suit-enemy`；不合併 main、不更新公開 Web。

## 現在可以玩

1. 進入 **FIGHTERS**，在右側按 **BLACK SUIT / P2**。
2. 右側真 3D 預覽會切成黑衣人；四張主角卡不變。選 P2 再點主角卡，可換回原對手。
3. 按 **FIGHT** 即可與黑衣人 AI 對戰。回主選單後也可選 **TRAINING** 或 **AI DEMO**，沿用此配搭。
4. 對手選擇會保存。戰鬥中不能換角色；Street Run 仍是既有三站／其他三名主角，離開後還原黑衣人對手。

敵人為近身「COLLECTOR／收貨員」：共用輕連段、重踢、挑空、追擊、投技、防禦、招架、跳躍與二段跳。50 能量 **FORCED RECEIPT**：18 tick 起手、6 active、34 recovery、2.5 reach、原始傷害 24；75 能量 **SIGNED OFF**：28／8／44 tick、2.8 reach、原始傷害 38。實際傷害仍經連段衰減等共用規則，不是保證傷害。HP 100、速度 .98、回能 1.0，未經真人平衡驗收。

AI 沿既有合法輸入決策，不直接改血量、命中或位置。沒有 ZIP 路線、RIVET 預壓、HUSH 取樣、LOOP 接點或成長技能。效果色淡紫；西裝、白襯衫、墨鏡及紫領帶保留原貼圖，不被 P2 隊色染成橙色。

## 模型與來源

- 原始 GLB 位於 `godot/assets/characters/black_suit/source/`，逐位元保留；原檔約 173 KiB，1,116 三角面、976 vertices、1 skin／65 joints、1 張 1024×1024 JPEG、沒有內建動畫。
- UUID `6bb9e9c2-dd66-4f86-864f-2ceab3aa0a09`；來源 SHA-256、貼圖尺寸／雜湊及權重檢查見 [inspection.json](../references/characters/black-suit/inspection.json)，由 `tools/inspect_black_suit.py` 重建。
- runtime 以 2.15 包裝縮放，原始模型高度約 .998；沒有改原始幾何、骨架或貼圖。
- 52 骨重定向到已有 Quaternius CC0 動作庫。沿現有程序姿態、命中反白／輪廓、Neon 演出；針對長手臂調低防守時手肘，保持手套靠近面部。
- 敵人索引 4 獨立於四名主角；`fighter_roster.gd` 的四個 `ENTRIES` 和成長 ID 保持不變，P1 仍只允許 0–3，P2 額外允許 4。舊偏好不用搬移；存檔沒有第五個主角成長紀錄。

## 劇情、背景與動畫重用

在 Godot 場景中實例化 **`res://scenes/characters/black_suit_actor.tscn`**。

- `posture`：`idle`／`walk`／`guard`，可放置多個實例。
- `animation_enabled`：是否自行更新；導演可關閉並逐格呼叫 `advance(delta)`。
- `neon_enabled`：選擇目前 Neon 材質或原 Toon 材質。
- 根節點的位置、旋轉和縮放由場景或導演控制；走路為原地動畫，位移另由導演處理。
- 這是有骨架動畫的外觀角色，沒有戰鬥碰撞、AI、傷害、輸入或 XP；不能把它當一個完整自主戰鬥敵人。

可用於黑車下客、店外站崗、門口威脅與日後開場分鏡。本輪沒有把未製作的軍火／槍械系統、六章故事、維修場、黑車追逐、警方或 18 秒啟動動畫宣稱已接入。

## 驗證

詳見 [畫面與檢查](evidence/black-suit/README.md)。Godot 4.6.3 Linux Compatibility／Mesa llvmpipe，Dummy audio。

- 新敵人原生整合 32 項：實際指標選擇、三視窗尺寸、52 骨映射、各攻擊姿態、真命中／招架、30 秒自由 AI 互打、對手保存、成長隔離、Street Run 還原及多次換模清理。
- 原有四角技能規則 46 項；二段跳 62 項、防禦 25 項；原生 UI 37 項、材質生命週期 6 項。共 208 項檢查通過。
- 不是使用者 Mac／硬件 GPU／真人手感或喇叭驗收。保留 llvmpipe 不支援 VSync 的警告；引擎 ERROR／SCRIPT ERROR 必須獨立檢查，不能只看 JSON。
