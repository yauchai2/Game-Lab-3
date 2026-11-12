# 黑衣人手槍（BLACK SUIT GUN）

2026-11-12，Alan 要求黑衣人用槍，但佔比不高。分支 `claude/project-thread-pib75q`。

## 規則（唯一 owner：`godot/scripts/combat/enemies/gun_shot.gd`）
- 只有角色 4（黑衣人）可用，且只由 AI 要求；玩家控制的黑衣人沒有槍鍵。新招式 `gun` 在 `MOVES`，近戰 hitbox 永不判定它（`_can_hit` 排除）。
- **前搖 30 tick（約 0.5 秒）**，群戰／故事因敵人縮放再加 3–7 tick。前搖中被打中就取消，不會出槍。第 30 tick 才出子彈，後搖 34 tick（arcade 約 19）可被反擊。
- **子彈**：一粒、15 u/s、高度 1.0。衝刺無敵幀、跳躍（腳高於 1.0）都會讓子彈飛過；衝刺閃避回 6 能量。
- **格擋**：站定舉盾擋下，只削 guard（傷害×2），不扣血；guard 歸零會破防。**完美格擋（12 tick 內）**彈開子彈、給 18 能量與反擊窗口，子彈折返以 14 傷害打回射手（射手仍在場才有效）。
- 傷害 10（群戰／故事按現有敵人倍率縮放），命中硬直 16、hitstop 6。
- **頻率**：每名敵人冷卻 8／6／4.5 秒（Easy／Normal／Hard）；全場任何一槍後 150 tick 內不能再開；出現後頭 2.5 秒不開槍；距離 3.4–9 才考慮，太近改打近戰；玩家被打倒、在空中、無敵時不開槍；每 0.75 秒擲一次 25／35／50% 機率。實測 60 秒內約 6 槍。
- 故事敵人只有 grunt、captain 會開槍；rusher、guard、heavy、jammer、boss 一律不用。
- AI 入口：`rush_agent.gd`（正式 arcade）和 `fight_simulation.ai_command`（舊路徑）都只呼叫 `GunShot.wants`。

## 表現（`enemies/gun_presentation.gd`，只讀模擬狀態／事件）
- 前搖：舉槍雙手姿勢（`combat_motions.gd`）、手槍低模方塊（`fighter_visual.gd`，只在出槍招式顯示）、**虛線瞄準線**由槍口沿射線延伸並變粗、最後 10 tick 變白閃爍、頭上 `!` 方塊。減少特效（F2）仍畫瞄準線，因為是公平性提示。
- 開槍：槍口星芒、鏡頭小震、後座力手臂上揚。子彈：墨邊硬色塊 + 三格階梯尾跡，被彈回時變青色。
- 命中／格擋／彈開各有火花、既有 hit／block／parry 特效與提示字（SHOT／BLOCKED／DEFLECT／REFLECTED／DODGE）。
- SFX 為程序合成原創（`tools/build_gun_sfx.py`）：`gun_aim_0`、`gun_shot_0`、`gun_hit_0`、`gun_ricochet_0`。**未有人聽過，音量與質感要靠 Alan 耳朵調。**

## 驗證
- `godot/tools/verify_gun_shot.gd`：21 項純模擬（只有黑衣人可用、前搖幀、子彈速度、命中、衝刺／跳躍閃避、擋、彈開折返、前搖被打斷、冷卻與頻率、近距離不開、群戰事件有效、故事角色排除、決定論）。
- `godot/tools/capture_gun_shot.gd`：xvfb＋llvmpipe 截圖（前搖／警告／槍口／飛行／命中／格擋／彈開），在 `docs/evidence/black-suit-gun/`。
- 已重跑 verify_squad_rules、verify_story_waves、verify_last_service_rules、verify_combat_sfx 均通過。
- **未驗證**：真人手感與平衡、Mac／GPU 畫面、真實喇叭音效、4.7.2。手槍模型位置／朝向只看過 llvmpipe 截圖。
- 玩家控制的黑衣人沒有槍；故事／群戰裡實際出槍頻率未做長時間統計（群戰測試 3600 tick 內沒有觸發槍擊，因為單進攻名額與開場延遲）。
