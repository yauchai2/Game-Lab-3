# 黑衣人群戰、後頸與領帶修補

2026-11-11（Asia/Hong_Kong）。接續 `codex/black-suit-enemy`，回應使用者要求成群敵人、難度調校，以及截圖中的後頸斷裂／領帶缺片。未合併 main、未發佈 Web。

## 操作

**FIGHTERS → SQUAD** 開始一場群戰。難度沿 SETTINGS 的 Easy／Normal／Hard；新一場採用新難度。方向鍵／A、D 移動，J 連打、Shift 防禦、E 閃步、K 挑空、Space 跳躍，原角色操作不變。暫停可重開；結算按 Enter 或重賽按鈕重開群戰。

BLACK SUIT / P2 仍可用於原有一對一 FIGHT、TRAINING、AI Demo。群戰是額外的原生可玩入口，不修改四張主角卡與主角成長紀錄。

## 群戰規則與起始難度

| 難度 | 同場敵人 | 每人 HP | 敵方原招式傷害倍率 | 額外起手／恢復 |
|---|---:|---:|---:|---|
| Easy | 3 | 35 | .45（每招至少3） | +7／+8 tick |
| Normal | 4 | 45 | .55 | +5／+6 tick |
| Hard | 5 | 55 | .65 | +3／+4 tick |

以上是初始調校，不是經真人驗收的平衡結論。AI 仍使用既有三階難度策略，沒有讀取玩家 pending 指令。正常對戰的黑衣人100 HP／招式數值不變。

- 多名敵人同場，各自保存位置、HP、受擊、倒地與動畫。等待者會在玩家兩側走位；不是背景裝飾，也不是擊倒後換皮重設血量。
- 同時只准當前進攻者發起攻勢，換手有24–50 tick準備。普通攻擊可在實際距離／方向／高度內打中多名敵人，每次出招對同一人只結算一次。
- 摔投與專屬連踢／大招追擊保持單一目標；LOOP節點的有效範圍可作用於多名敵人。空中反制仍綁定目前交手的一人。
- 自動選取近身敵人，移動方向可引導選取；出招、反擊窗口或連段中保持對手，避免鏡頭與追擊突然換人。
- 玩家被真命中後，下一輪敵方主動進攻至少等100／80／60 tick，並有36／30／24 tick保護，減少輪番硬直。實際攻擊仍可招架、防守或閃避。
- 總時限180秒；擊倒全部敵人才勝利。玩家KO或時間到而仍有敵人即敗北。無XP／掉落／雲端存檔獎勵。
- 頭頂血條與白色焦點標記顯示各敵人狀態，起手顯示「!」。暫停凍結全部敵人；重開、退出、轉回一般對戰／Demo會清除群戰狀態與額外角色。

實作以 `squad_simulation.gd` 協調獨立敵人資料，重用原兩方 simulation 的真命中、格擋、招架、空中、連段與角色資源規則。玩家每 tick 只推進一次；等待敵人各自推進移動／受擊，不以多個 simulation 重複消耗玩家時間。演出／音效按事件所屬敵人綁定，鏡頭一般構圖考慮全隊範圍，招式特寫仍服務當前交手。

## 模型修補

- 原始檔仍在 `assets/characters/black_suit/source/`，SHA-256未變。
- runtime 改用 **`res://assets/characters/black_suit/derived/black_suit_repaired.glb`**：1,208三角面、65關節，5個mesh，沒有內建動畫，沿用52骨重定向。
- 後頸97個頂點移除肩膀的交叉拉扯，重新分配到Neck／Head；加入封閉八邊形頸部接合，隨骨架一起變形。
- 原 .012 厚度的 inverted-hull 輪廓在凹入下顎／領口產生粗黑縫。只對黑衣人局部頸部降低膨脹量；頸部與布料補片不再各自疊粗輪廓。其他角色輪廓設定保持原值。
- 領帶不再依賴破碎的原紫色貼圖片：加入封閉的白襯衫內片、紫色領結與領帶長片，使用乾淨材質並綁定胸骨。原貼圖本身保留，沒有用生成圖重新塗抹角色。
- 共用 FighterVisual 現可保留修補材質的 base color，避免沒有貼圖的紫領帶／皮膚被當成白色。
- 可重用 `black_suit_actor.tscn` 自動使用修補版；待機／走路／防守與原場景transform契約仍有效。

可用 Blender 執行 `blender -b --python tools/repair_black_suit.py` 重建衍生檔；工具不覆寫來源。追溯見 [repair.json](../references/characters/black-suit/repair.json) 與 [repair-validation.json](../references/characters/black-suit/repair-validation.json)。

## 驗證與限制

[畫面與297項檢查](evidence/black-suit-squad/README.md)。Godot4.6.3 Linux Compatibility／Mesa llvmpipe／Dummy音訊，最終log無ERROR／SCRIPT ERROR；VSync不支援警告保留。

包括35群戰規則、9原生群戰／生命週期、32修補版單敵整合、46四角資源、45正式戰鬥、62二段跳、25防禦、37原生UI與6材質生命週期。封閉補片、權重和、關節／頂點索引與有限值另行檢查。

純站立玩家診斷中，Easy／Normal／Hard均收到真實攻擊；1200 tick樣本的最短連續受擊間距為123／92／68 tick。此為固定條件診斷，不能當成人類難度、硬件FPS或最終混音驗收。尚待使用者Mac與真人試玩；沒有新增槍械、多人連線、故事或新地圖。
