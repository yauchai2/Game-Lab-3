# 分段打擊演出

2026-11-09，香港時間。延續更新 LLB 參考中的硬邊色塊、局部頓幀、釋放段及碎片消散，轉譯至本作的近身格鬥。

## 改動

六招使用不同的原創向量動畫設定：jab 短弧、cross 較長斜弧、finisher 大弧、heavy 橫向扁弧、launcher 向上斜弧、special 最大弧。每段分六個離散畫格，早段以隊伍色＋暖白雙層塗抹，後段拆成分離菱片；不靠透明度淡出。這是程序向量畫格，不是下載或繪製的貼圖 flipbook。

命中時先顯示隊伍色／白核心和深色尖角輪廓；角色物理的 hitstop 繼續由既有 60 Hz simulation 控制。核心在停頓期間保持，演出時鐘繼續播放；hitstop 最後一 tick 才移除核心，生成橢圓氣浪及碎片。每個命中只釋放一次，交換命中保留雙方的接觸點。KO 進結算會立即清空待釋放核心並播放釋放形狀，不把它留在選單背後。

釋放時加入依攻擊方向的小幅鏡頭反衝，0.24 秒內阻尼回彈；挑空偏垂直。重擊／能量技的既有釋放音效與較低音量的 sub 層也在此時播放，避免先前 `last_impact_strength` 殘值令下一次擋格停頓誤播重擊釋放聲。沒有新增音檔，沿用已附授權的 CC0 聲庫及原創合成低頻。

F2 會縮小新畫格、減少碎片和套色，停用新增反衝；既有防禦／彈反護盾保留。特效依角色投影比例做有上限的縮放，避免鏡頭遠近變化時大幅蓋住角色。沒有全屏閃白、紅黑 Eclipse 或柔邊煙霧。畫格和氣浪是演出，不表示攻擊判定範圍。

練習重置、下一回合、重新開始及返回主選單都會清除待播放命中與鏡頭偏移。傷害、攻擊起手／判定幀、擊退、hitstop 長度及原始 simulation 檔案不變；天空、招牌和場景也保持前輪版本。

## 原生預覽與驗證

- [重踢分段短動畫](evidence/impact-staging/heavy-sequence.gif)：真實 Godot 60 Hz 固定步進，隔 tick 擷取後轉為 GIF；不是即時執行 FPS 或錄音。
- [輕擊／重踢／挑空接觸與釋放](evidence/impact-staging/contact-release.jpg)。
- [能量技／減少演出／揮空與換邊](evidence/impact-staging/special-and-whiffs.jpg)。

新 24 項檢查：432 組左右向量畫格（含六種招式、三種段落、六個時點、普通／減少演出）有限、可三角化及完全不透明；換邊、碎裂段；真實 simulation 命中後的停頓、只釋放一次、暫停、交換命中、揮空／擋格、練習重置／主選單／換回合／KO；F2 關閉鏡頭偏移。另格鬥 34、練習 35、場景／音訊 33、天空 18、X11 viewport 自動輸入 11，合共 155 項通過。

順便修正天空驗證：F2／暫停的接線檢查現在呼叫真正會推進天空的 `_process`，取代只更新角色及相機的 `_present`。前輪相同 18 項結果重新跑過；新報告保存於本輪，不改歷史報告。

16 張原生 Godot 4.6.3 Compatibility／Mesa llvmpipe 擷取、32 張重擊序列幀轉 GIF。自動驗證不代表真人手感、實聽混音、目標 GPU 或使用者電腦已驗收。舊場景／音訊快速測試仍有 ObjectDB／resource 退出清理訊息；沒有宣稱全面修復。來源、雜湊及日誌見 `evidence/impact-staging/`。

```sh
godot --headless --path godot --audio-driver Dummy --script res://tools/verify_impact_staging.gd
# Native display required. This task used Xorg :95 and software GL.
DISPLAY=:95 LIBGL_ALWAYS_SOFTWARE=1 godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x720 --script res://tools/capture_impact_staging.gd
```

## 交付及後續

只推送 `codex/street-combat`，GitHub Desktop Pull 後 Godot F5，J／K／W+K／L 比較，F2 減少演出，T 進練習、F5 重置。沒有匯出或部署 Web，公開 gh-pages 保持 2908503。沒有代操作使用者電腦。

下一步優先真人調校攻擊弧大小、音畫重量及近距離遮擋，再評估受擊地面撞擊段與方向性音效混音。暫不需要 Tripo 模型；正式招牌仍待使用者貼圖。
