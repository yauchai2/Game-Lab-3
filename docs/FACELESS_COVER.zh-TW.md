# 無臉半身剪影封面

2026-11-10。使用者提供兩段TR3B低多邊形影片，要求不見人臉；後續修正為低調酷、插袋行走姿勢、只見上半身。

已生成並接入新版主選單：黑白切面城市與電線、桃紅天空、兩位青色／螢光綠上半身人物。人物肩膀放鬆、頭略低、手收在外套口袋，腰部由畫面底部裁掉；沒有戰鬥架勢、腿或鞋。頭部保持單一色塊，不畫眼鼻口或膚色。右側大剪影、左側留黑，讓Logo及選項清楚。

原Logo沿用；FIGHT／FIGHTERS／TRAINING／SETTINGS／AI DEMO使用大字原生繪製及真正Button互動，焦點會變色。MAIN_RECTS改為1280×720logical座標直接對齊控制項，選角頁仍保留既有fit mapping。全畫面依然640×360，音樂transport及音量規則不改。

封面範圍之外的3D選角及戰鬥模型保持。沒有刪除原始title.png，也沒有從參考影片剪人物直接放進遊戲；新圖為ImageGen原創構圖。來源、影片SHA、6點取樣預覽、生成prompt及使用者修正紀錄在 `references/faceless-cover-2026-11-10/`。兩段影片以等間距靜幀檢視，沒有宣稱逐幀／連續觀看或研究音訊；本輪為靜態封面，沒有冒稱已做影片中的角色動畫。

Godot4.7.2 Linux native Compatibility／Mesa llvmpipe覆核：37／37原生鍵盤／滑鼠、三視窗尺寸、選角、Demo及音樂連續播放檢查通過。檢查log無ERROR，只有環境V-Sync提示。人工檢視新底圖及640×360實機構圖，確認頭部無五官；不把這當作自動人臉辨識保證。底圖alpha全255，舊世界的角色臉不會從封面透出。目標Mac未實測。

[主選單畫面與檢查](evidence/faceless-cover/README.md)。只更新原始碼分支供GitHub Desktop Pull；gh-pages及公開試玩版保持不變。
