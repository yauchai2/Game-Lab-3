# Afterhours / Game-Lab-3

最新[空中街鬥原型](docs/AERIAL_STREET.md)：主選單 **F11 空中訓練**，Space 蓄勢起跳、S 急降、W＋K 挑空 → E 追擊 → J 空中三連、↓＋K 暴扣及一次反彈。新增程序姿態、空中構圖及快速組合鍵修正；F2 減少演出。正式模式保留原玩法，**公開 Web 不更新**。

前輪規劃：[空中戰、誇張動作及聲畫整合](docs/AERIAL_ACTION_AUDIO_PLAN.zh-TW.md)／[wev 選曲與接入](docs/WEV_MUSIC_PLAN.md)。吸收新 R&D 參考並核對跳躍尺度，下一輪優先起跳、有限滯空與空連；**本輪未改遊戲**。wev 尚未取得授權，先完成候選曲／架構規劃，現有 CC0 音訊保留。

最新[動能換手與漫畫爆發演出](docs/KINETIC_OVERDRIVE.md)：**F10** 進有限格擋換手練習，Shift 接拳 → J 反擊 → 再格擋升級。正式對戰新增月牙衝擊弧、骨架殘影、三色階爆發、鏡頭反衝及可跳過的 KO 演出。F2 減少演出。只更新開發分支，**公開 Web 不更新**。

前輪[爽感與完整演出優化計劃](docs/GAME_FEEL_ROADMAP.zh-TW.md)：已吸收並保存兩份使用者參考，規劃有限格擋換手、蓄力、分層演出、選角／VS／KO 及驗收次序。**本輪只有文件更新，新系統尚未實作；現行三選對峙保留。公開試玩版不更新。**

**[在 GitHub 直接試玩](https://yauchai2.github.io/Game-Lab-3/)** · 電腦鍵盤、單人對 AI／無限練習、首次約 19 MB。GitHub Pages 已啟用。[操作與更新方法](docs/WEB_PLAYTEST.md)。

前輪[原生 UI 與近身交鋒完善](docs/EXTENDED_POLISH.md)：移除藍樓遮窗大牌，繁中／英文選單、可點按對峙、獨立音量、G 投技／拆投、E 場邊受身、較近的交手追鏡及靜態批次繪圖。只更新 `codex/street-combat` 原始碼，**公開試玩網址仍是舊版**。

[借勢街鬥核心原型](docs/PRESSURE_EXCHANGE.md)：三階壓力、高壓重踢 0.4 秒對峙、J 頂進／Shift 卸勢／E 抽身。主選單選「交鋒教室」，或 T → F8 → K 直接試。

前輪[分段打擊演出](docs/IMPACT_STAGING.md)：六種攻擊弧、頓幀接觸核心、釋放氣浪／碎片及方向反衝；只更新開發分支。

前輪[招牌整理、動態天空與新版 LLB 參考](docs/SCENE_COMPOSITION.md)：保留圖片天空並加入緩慢雲圖漂移，重整空白招牌及支架；只更新開發分支。

前輪[街角立面與兩側街區加密](docs/CORNER_DENSITY.md)只更新 Godot 原始碼，**公開試玩版未同步此輪場景**。在 GitHub Desktop 選 `codex/street-combat` 拉取後 F5 查看。

本分支在既有風格化街區上加入 **2.5D 近身格鬥**：玩家對 AI、連擊、挑空、防禦、能量技、動態頓幀和回合勝負。[操作與完整開發狀態](docs/COMBAT.md)。最新已按試玩回饋修正朝向、接入 14 段 CC0 動畫，改用[斑馬線上的統一透視與追鏡](docs/PLAYTEST_FIXES.md)，場景招牌先留白。[最新戰鬥完善](docs/COMBAT_POLISH.md)：無限練習、對手切換、快速重置、挑空跳躍追擊、AI 難度及設定保存。最新已[接回原圖片天空、車輛與街景細節](docs/SCENE_AUDIO_VFX.md)，修正倒飛與街道拉伸，加入 CC0 音樂／音效、精準防禦及更多局部 VFX。

以 Godot 4 製作風格化低空航道街區。AI 主導製作，使用者透過 Tripo 網頁生成與回傳模型，並提供美術及遊玩回饋。

目前包含六件資產的原型展示庫、已加入遊走場景的轎車及箱式貨車，以及 S1 街道白盒、四個固定視角與俯視布局。S2 基本遊走已實作並完成無視窗邏輯／物理檢查，入口附近的 S3 風格樣片已提供原始材質／兩段／三段比較；S4 飛機掠過、重播及合成測試音已實作；已預設使用原創圖片天空並可切換程序分層雲；已擴充港式店面、街道與飛機細節，已加入使用者提供的角色與暫用步態、低清環境貼圖；人工手感、收聽、最終美術及效能仍待驗收。

## 接續前先讀

- [協作規範](AGENTS.md)
- [交接與目前狀態](docs/HANDOFF.md)
- [待辦](docs/TODO.md)
- [白盒操作、預覽與重建](docs/WHITEBOX.md)
- [遊走原型操作與驗證](docs/WALK.md)
- [風格樣片、比較圖與驗證](docs/STYLE_SAMPLE.md)
- [JSR／BRC 製作規範](docs/JSR-BRC-style-reference.md)與[專案對照](docs/JSR-BRC-project-application.zh-TW.md)
- [飛機掠過原型與新截圖](docs/FLYBY.md)
- [天空樣片與比較圖](docs/SKY_SAMPLE.zh-TW.md)
- [角色與低清街景貼圖](docs/CHARACTER_TEXTURES.zh-TW.md)
- [街景優化、飛機影片與效能檢查](docs/STREET_POLISH.zh-TW.md)
- [GitHub Desktop 同步及 Godot 查看](docs/GITHUB_DESKTOP.zh-TW.md)
- [Tripo 轎車候選圖片及設定](docs/TRIPO_CAR.zh-TW.md)
- [下一個 Tripo 候選：箱式貨車](docs/TRIPO_TRUCK.zh-TW.md)
- [設計基準](docs/DESIGN.md) 與 [下一階段規格](docs/design/next-phase.zh-TW.md)
- [重要決策](docs/DECISIONS.md)
- [驗證結果與限制](docs/VALIDATION.md)
- [資產索引與來源雜湊](assets-manifest.json)

開始修改前確認目前分支、遠端最新提交及工作區變動；不要假設知道其他對話進度。保留現有內容，將重要決策與驗證同步到任務分支。

## 開啟專案

驗證版本為 Godot 4.6.3，以編輯器開啟 `godot/project.godot`，匯入後按 F5 進入格鬥主選單 `scenes/combat/street_fight.tscn`。J 輕攻擊、K 重攻擊、W+K 挑空、L 能量技、Shift 防禦／抓準時機反制、E 翻滾閃避、Space 跳躍；M 靜音、F4 音樂、F2 減少演出、O 場景描邊；遊戲內 F6 返回原街景 `scenes/street_walk.tscn`，再按 F6 回格鬥。

原街景操作：WASD 移動、滑鼠轉向、Space 跳躍、V 切換第一／第三人稱；按 `1–5`／`Tab` 查看固定視角，`0` 回到角色，`R` 重設，`B` 比較樣片材質，`P` 重播飛機，`C` 切換程序雲朵／純色天空，`N` 比較生成的天空圖片，`O` 開關實驗性描邊。原資產展示仍保留於 `scenes/review.tscn`。

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://verify.gd
```

上述命令驗證匯入和場景載入，不能代替 GPU 畫面、實際遊玩或效能測試。細節見 [Godot 專案說明](godot/README.md)。
