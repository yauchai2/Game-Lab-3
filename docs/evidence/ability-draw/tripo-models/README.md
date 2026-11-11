# 使用者Tripo NPC與機身 — 實際引擎證據

[有聲過場](tripo-ability-draw.mp4)使用本次上傳的原NPC skin／65骨及機殼，另加獨立輪盤、輪子、拉桿及出貨蓋；不是舊程序角色或影片貼片。背景沿當局World3D。明示1:1邊界fixture，非自然完整match；BGM只於錄製靜音。

- 原檔：[正面](source-models-front.png)／[斜側面](source-models-angle.png)／[檢查log](source-inspection.log)。
- 過場：[空場](00-empty.png)／[拖行](01-entry.png)／[落地](02-landing.png)／[拍機](03-slap.png)／[代幣](04-offer.png)／[輪盤](05-reels.png)／[鎖停](06-lock.png)／[爆獎](07-jackpot.png)／[獎品卡](08-core.png)。
- [22項模型檢查](model-verification.json)／[log](verify-models.log)，包括真65骨動作、CC0 gait重定向、原貼圖、獨立機構、姿態有限、二骨手腕接觸、代幣跟手、暫停／退出，及實際渲染中輪盤可見性的像素檢查。
- [52項流程回歸](verification.json)／[log](verify-flow.log)：原入口、跨場景、一次獎勵／真規則、Street Run／Demo、mute／F2／pause／clear保持。
- [可見性檢查畫面](reel-visibility-check.png)／[擷取時序](capture.json)／[實際混音PCM量測](audio.json)／[Movie Writer](movie-writer.log)。

最終22＋52共74項通過，最終log無ERROR／SCRIPT ERROR／SHADER ERROR及退出洩漏。來源原檔hash與metadata在references/ability-draw/tripo/uploaded-models.json，兩份均與上傳檔逐byte一致。

早期模型測試有型別推斷parse錯誤；第一輪開窗描邊shader因varying宣告順序出錯，即使模型旗標22/22也不當該次嚴格通過。機殼原窗口是多層封面，單靠縮小後移會完全遮住輪盤；最終在衍生材質及outline同時按來源局部座標開窗，不修改來源GLB，並加實際渲染可見性驗證。

新模型完整回歸52項後，Ogg arrival／intro播放實例在快速反覆重開時仍退出滯留；顯式stream模式未解決。最終短過場cue採既有原創OGG解碼的PCM WAV（不改曲目／內容、原OGG保留，長BGM維持串流），重跑74項及Movie Writer退出乾淨。initial-attempts保留錯誤與Ogg診斷節錄；不是宣稱修好Godot整體Ogg解碼器。

Godot4.6.3 Linux Compatibility／Mesa llvmpipe／Dummy audio，640×360、30fps固定步長錄製再nearest放大1280×720；不是使用者Mac、真人混音／觸感或目標GPU效能驗收。骨骼手腕接觸不等於完整手指物理解算，衣袖／指節與原片仍有差異。裝備動畫仍僅分鏡，未在本次暗中實作。未發佈Web。
