# 動畫來源

作者：Quaternius。官方頁面：https://quaternius.com/packs/universalanimationlibrary.html ，2026-11-07 查閱標示 License CC0，並寫明可用於個人、教育與商業專案。

本次由 `quaternius.json` 記錄的固定 GitHub 鏡像提交取得 Standard glTF，原14段現擴充為19段動作、剔除網格並保留原始和衍生 SHA-256；授權全文在 `godot/assets/animations/LICENSE-Quaternius.txt`。骨架轉接、插值和時序調整由本專案執行。

動作資料沒有改寫來源角色 GLB；重踢與挑空為自製疊加調整。工具 `tools/extract_combat_motions.py` 可從固定原始 glTF / bin 重建。

2026-11-09：重新讀取官方頁確認 CC0，從相同固定來源新增 Dance_Loop、Crouch_Idle_Loop、Spell_Simple_Idle_Loop、Sword_Attack、Idle_Loop。四人姿態差異另有自製程序疊加；沒有 Mixamo 帳戶下載。Crouch clip保留供後續使用，護目鏡最終採直立Idle。

2026-11-13：RIVET地面首切片重用既有Punch_Enter／Punch_Jab／Punch_Cross並建立站姿來源遮罩與分段取樣，未修改19clip資料或原始GLB。官方來源候選與帳戶／授權待辦見docs/RIVET_MOTION_SLICE.zh-TW.md；Web工具本輪可查Mixamo／AccuRIG／Rokoko／Fab官方資料，但尚未下載或錄用這些商品。不要把來源研究寫成已接入新mocap。

2026-11-13 第二輪：已真正取得新CC0來源，見street-library.json與docs/STREET_MOTION_LIBRARY.zh-TW.md。Quaternius UAL2 Standard勾拳／回收與KayKit1.1踢擊／移動，原始固定鏡像提交／bytes／SHA及作者／授權齊備；10個來源clip＋1全身反射，離線60Hz轉成原canonical rig，street_library.json無網格。原19clip檔及英雄GLB保持。這不是Mixamo／ActorCore／Rokoko／Fab商品；帳戶來源仍待取得。
