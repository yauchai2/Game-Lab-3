# RESULT修復、決勝KO與四面反彈 — 2026-11-11

RESULT曾只剩背景與標題：過場結束前先設了finish_menu_open，但rebuild在active演出期間把控制項隱藏，完成後沒有再建立。本輪把結果操作的建立移到演出釋放後，並修復「旗標完成但選單不可見」狀態。原生畫面與callback測試驗證下一回合／重賽確實可按，涵蓋正常播完、暫停／恢復、F2及跳過。

## 最新規則

- 正式兩勝制：普通回合1.4秒短結算；只有決勝回合零生命才播完整8.2秒爆城／飛機KO與勝者離場。超時不冒充KO。
- AI Demo：同一規則，普通回合自動繼續，決勝KO播完才開始下一場，保留選角、無XP。
- Street Run：早站短結算，最後站或本次Run敗退結束才播完整KO。
- 正式Rush、Demo、Street Run及自由練習有四面反彈盒：左右x±8.2、腳部y0–5.6，頂框8m。普通跳躍也受天花限制；重擊／挑空／終結擊／符合推力的招式真命中才進入反彈。
- 法線碰撞反射保留78–86%該分量，無額外碰牆傷害。最多6次接觸或180個物理tick；hitstop／暫停不消耗。再次命中不刷新該次預算，落地後重置；耗盡自動恢復並保護18tick。
- 每次撞擊後18tick可按E花20能量受身，AI有有界反應延遲；F2保留物理，減少翻滾／格線等效果。

真3D透明線框圍場、四面各一個重用撞擊格、軀幹中心翻滾、既有速度尾跡／煙塵／SFX。高速飛行即時以兩人body bounds退鏡，目標留白x10–90%、y24–82%；反彈字卡移到底部，保留高處角色可見。

## 觀看

- [9秒四角色反彈預覽](ricochet-preview.mp4)：ZIP→RIVET、HUSH→LOOP，普通合法launcher命中。站立CPU與近身位置是明示fixture，不注入傷害／速度／碰撞；不輸入E讓完整連續反彈可見。[接觸時序](capture.json)。兩次皆真接觸天花→右牆→地面→天花→左牆→地面。
- [56.7秒完整自然AI match循環](demo/full-match-loop.mp4)：正常生命、普通回合短結算，決勝完整KO和離場，再接下一場；沒有注入命中／傷害，記錄到20次arena接觸及15次真受身。[事件記錄](demo/capture.json)。
- [普通結果頁](round-result.png)／[決勝結果頁](match-result.png)：包含真正原生可按controls。
- [撞天花](bounce-ceiling.png)／[右牆](bounce-right.png)／[地面](bounce-floor.png)／[左牆](bounce-left.png)。

## 驗證與範圍

[最終聚合](final-checks.json)：513項focused checks全數通過。新純規則18項、原生結果／鏡頭24項、自然Demo回合24項；既有勝者86、KO165、FX20、UI37、Demo輸入11、Demo規則7、二段跳62、重砲10、結果15及戰鬥34。10000步正常AI確定性、單次合法挑空多面碰撞、不新增health傷害、四面E消耗、hitstop及預算耗盡均有驗證。自然Demo原生檢查約55.45虛擬秒完成三回合，前兩回合短結算、第三回合唯一完整KO，再進下一場。

初跑KO paid-hit測試未設決勝分數，及舊重砲測試仍期待endless battle而未調用下一回合，已依最新契約修正，失敗保留在native／headless初次資料夾。最終報告在native-final、headless-final及framing-final。最初未設定可寫XDG userdata導致引擎啟動失敗，修正環境後執行；原log保留。沒有冒稱全套歷史suite零失敗。

Godot4.6.3 Linux Compatibility／Mesa llvmpipe／Dummy audio，影片是640×360／30fps固定時間步Movie Writer與H264/AAC轉碼，SFX保留、BGM僅於錄像靜音。不是目標硬件FPS、使用者Mac或真人手感／音訊裝置驗收；現行傷害／資源價格保持，反彈改了正式擊退路徑，真人平衡仍待試玩。原始模型不變；來源同codex/combat-escalation-next／PR #6，公開Web不更新。
