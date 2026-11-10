# LAST SERVICE：新四角色與成長驗證

[功能／操作／數值／完成範圍](../../LAST_SERVICE_RUNTIME.zh-TW.md) · [295項總表](summary.json)

## 原生畫面

- [ZIP選角](roster-0.png)／[RIVET](roster-1.png)／[HUSH](roster-2.png)／[LOOP](roster-3.png)：真GLB及不同程序pose，不是角色圖片假預覽。
- [正常戰鬥](fight.png)／[LOOP接點](loop-node.png)／[HUSH–LOOP自由AI](hush-loop-demo.png)
- [技能頁初始狀態](skills-fresh.png)／[一個解鎖節點的隔離UI fixture](skills-one-unlock.png)
- [真接觸後的街區結算](run-result.png)／[指標操作解鎖並裝備後](skills-earned.png)：低血站樁對手只為測試結算流程，不能當作打完整難度街區的證據。
- [無臉封面來源圖](../../../godot/assets/ui/last_service/cover.png)：由實際ZIP／HUSH模型渲染，原始GLB不變，UI按鈕仍原生。

## 自由AI影片

- [ZIP vs RIVET／15秒](zip-rivet-demo.mp4)
- [HUSH vs LOOP／15秒](hush-loop-demo.mp4)／[時間軸抽樣](demo-contact.jpg)
- [事件及命中統計](demo-report.json)／[引擎log](demo.log)

這是兩組獨立、無剪接自由AI片段；各900個固定1/60秒wall steps、225幀／15fps、無聲。正常輸入、正常角色資源及命中規則，沒有低血fixture或安排必中連技。虛擬wall time不等於軟件繪圖測試機穩定60fps。

## 檢查範圍

- [46項新角色／存檔規則](rules.json)／[log](rules.log)：真接觸、有限連踢、兩階預壓、取樣、節點擺放／格擋／拆除／到期／共同接觸互打、Encore上限、12節點效果、存檔、重複獎勵及重置。
- [22項原生整合](native-checks.json)／[log](native.log)：四模型映射、真指標操作、三站流程、技能生效／模式隔離、蓄力與active-frame特效同步、自由AI及材質退休。
- [28項大招檢查](signatures/checks.json)／[log](signature.log)：新四角色付費出招／慢鏡／鏡頭／body bounds，另有明示的投影／中斷狀態fixture。
- [53項原生介面／材質回歸](regression-native/summary.json)：包括不同視窗尺寸、選角、音樂pause仍連續、換角材質生命週期。選角斷言已按新需求由永久剪影改為完整貼圖。
- [134項舊規則回歸](regression-legacy/summary.json)：保留legacy profile作舊規則對照，不能拿這些當成新角色的平衡證明。
- [12項探索介面回歸](regression-walk/summary.json)：探索預設模型改ZIP，既有控制及回戰鬥入口保持。
- [骨架／權重／來源SHA](../../../references/characters/last-service/inspection.json)／[原生骨映射](models.json)／[擷取log](capture.log)

Godot4.7.2 Linux Compatibility／Mesa llvmpipe。嚴格檢查ERROR／SCRIPT ERROR；V-Sync不支援提示保留。退出前等待音訊混音器清理，避免把尚待釋放的Ogg播放資源當成模型洩漏。沒有目標Mac硬件、喇叭或真人手感／平衡評分。歷史證據及舊.import設定在測試後還原。
