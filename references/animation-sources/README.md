# 動畫來源

作者：Quaternius。官方頁面：https://quaternius.com/packs/universalanimationlibrary.html ，2026-11-07 查閱標示 License CC0，並寫明可用於個人、教育與商業專案。

本次由 `quaternius.json` 記錄的固定 GitHub 鏡像提交取得 Standard glTF，原14段現擴充為19段動作、剔除網格並保留原始和衍生 SHA-256；授權全文在 `godot/assets/animations/LICENSE-Quaternius.txt`。骨架轉接、插值和時序調整由本專案執行。

動作資料沒有改寫來源角色 GLB；重踢與挑空為自製疊加調整。工具 `tools/extract_combat_motions.py` 可從固定原始 glTF / bin 重建。

2026-11-09：重新讀取官方頁確認 CC0，從相同固定來源新增 Dance_Loop、Crouch_Idle_Loop、Spell_Simple_Idle_Loop、Sword_Attack、Idle_Loop。四人姿態差異另有自製程序疊加；沒有 Mixamo 帳戶下載。Crouch clip保留供後續使用，護目鏡最終採直立Idle。
