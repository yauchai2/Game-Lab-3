# UI可讀性與Godot4.7.2材質診斷

2026-11-10，基線e457043。使用者回報文字太細及截圖中的兩個GDScript警告／四個renderer空材質錯誤。

## 可讀性調整

前輪許多文字只有13–20 logical pixels，經640×360合成後名義字級只剩6.5–10內部像素，實際大寫高度更小。保留整體低解析風格，增加文字尺寸及空間，而非提高世界解析度或加模糊濾鏡。

| 項目 | 前輪 | 本輪 |
| --- | --- | --- |
| 設定控制項字級 | 17 logical | 28 logical（14內部像素名義尺寸） |
| 輔助說明／音量標籤 | 13–17 | 最低24（12內部像素） |
| 主要按鈕 | 20 | 32（16內部像素） |
| 次頁面板 | 610×490 | 780×510 logical |
| 內容間距 | 9 | 14 logical；Label行距6 |
| 遊戲Pause及底部鍵位列 | 細小圖片裁切 | 較大原生字體／有底色的真控制項或鍵位標籤 |
| 選角頁Enter／Esc提示 | 背景小字 | 大字原生底板，保留真鍵盤操作 |

RadioPixelBodyReadable／DisplayReadable是同一授權字體來源的14px／16px binary-alpha衍生，使常用28／32字級經半尺寸合成後正好對應原始像素，不反覆縮小舊atlas。大標題／巨大數字繼續使用原24px display來源，避免把小atlas放得太粗。原始字型、舊衍生檔、Logo及參考圖保留；不是官方JSR字型。

設定頁保持可滾動、鍵盤焦點會跟隨；同時提高淡色說明的對比。底部四操作維持J RUSH／K LAUNCH／L BURST／W+L CANNON，沒有改鍵位或判定。主選單仍5項，四人3D選角及現有戰鬥節奏不變。

## 截圖6項診斷

1. `fight_audio.gd`：內層swap改為獨立reversal_deck，避免與外層swap混淆。兩deck交叉淡入、暫停持續播放保持。
2. `street_dressing.gd`：以明確Mesh基底變數及if賦值選ArrayMesh／BoxMesh，移除不相容三元運算。
3. 重複場景／選角壓力測試重現了完全相同的四個renderer報錯。首次繪製前替換模型時，舊材質已被釋放，但Compatibility renderer仍要處理舊實例的材質依賴；只檢查surface的Material物件非null並不足夠。
4. `fighter_visual.gd`現在將換模的舊ShaderMaterial放進共用短暫保留佇列，等`RenderingServer.frame_post_draw`後清空，讓舊render RID在該幀仍有效。單一一次性回呼，不增加每幀永久工作；headless路徑不等待不會發生的GPU繪製。`roster_preview.gd`也改為首次使用才建立正確hero，不再先建預設角色然後立即丟棄。
5. 加固程序mesh的基礎材質、先設override再綁MultiMesh、先完成surface新材質才釋放舊override。沒有隱藏引擎錯誤或停用警告。
6. 新增`verify_material_lifecycle.gd`，涵蓋3次場景建立／釋放、首選0／1／3、24次選角、重套街景材質及真實繪製。6項檢查確認live materials及保留佇列清空。回歸runner現在把stderr的ERROR／SCRIPT ERROR視為失敗，防止再次出現「state檢查過了，但renderer仍報錯」的假陽性。

修正前原生壓力測試有12條material null錯誤；修正後同版測試6／6通過、engine_errors為空、各循環pending=0。保留[修正前log](evidence/readable-ui/material-before.log)及[嚴格回歸結果](evidence/readable-ui/material-suite/summary.json)。這證明Linux同版Compatibility下的重現及修正；Mac硬件仍須本機覆核。Pull後重新開啟Godot讓新字體匯入。

## 驗證

- Godot4.7.2-stable.ed1daf0bf，Linux x86_64，native OpenGL Compatibility／Mesa llvmpipe。引擎來源與binary SHA在 `references/readable-ui-2026-11-10/engine.json`。沒有把Linux測試說成Mac實測。
- 43個遊戲腳本載入，零parse錯誤。
- 22／22呈現／可讀性／surface材質檢查；4人真3D預覽、背景暫停、有界節點、音訊恢復沿用。
- 6／6材質生命週期檢查；同時檢查stderr engine errors，不能只看JSON state。
- 37／37原生鍵盤／滑鼠／三視窗尺寸／暫停音樂transport／實際Demo檢查。
- 144／144戰鬥回歸（同4.7.2），不更改遊戲判定。
- 6／6實際引擎PCM音訊檢查；Dummy是混音訊號測試，並非Mac喇叭試聽。
- 嚴格靜態設計規範稽核，不能替代原生檢查。
- 第一次呈現擷取退出仍有8個ObjectDB清理警告；後續最終原生／材質嚴格回歸沒有再出現。仍記錄為間歇退出清理待追蹤，沒有冒稱整個引擎零警告。Xvfb V-Sync不支援提示亦保留。

[前後畫面及證據](evidence/readable-ui/README.md)。所有此前遊戲原始模型／圖像／音樂／字體檔均保持，新增字體衍生有生成器與來源SHA。

## 同步

只推送 `codex/street-combat`，供GitHub Desktop Pull。在使用者電腦沒有執行同步／聆聽；沒有更新gh-pages或公開Web試玩版。
