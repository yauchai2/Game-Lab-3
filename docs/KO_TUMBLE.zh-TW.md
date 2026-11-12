# KO 擊飛翻滾（presentation only）

回合結束、敗者 HP 歸零時，不再原地倒下。新模組 `godot/scripts/combat/ko_tumble.gd` 是這段「KO 身體軌跡」的唯一擁有者，只讀取敗者最後姿勢，不寫入任何 sim 狀態。

## 時間軸（共 1.31 秒，短於 FINISH_SECONDS 1.4）
| 階段 | 時間 | 內容 |
|---|---|---|
| freeze | 0.11s | hit-stop：定格、白閃、壓扁、星爆 + 鏡頭震 |
| flight | 0.58s | 離開勝者方向擊飛，拋物線高約 1.5，繞軀幹後空翻一圈（結束時角度回到 0，無跳變） |
| bounce | 0.24s | 落地重擊（鏡頭震、`slam` 塵）、小彈跳、輕微搖晃 |
| slide | 0.38s | 滑行減速到靜止，沿途 `brake` 塵，再接原本的倒地姿勢 |

距離依場邊自動縮短（最多 4 單位，不出 ±8 場地）。鏡頭 finish zoom 會追著敗者飛行的 x。

## 特效
- 畫面端（`ko_tumble.draw`，多邊形、無旋轉的像素素材）：星爆、飛行時的水平墨線速度線、K.O. 大字（彈出→停留→淡出）。
- 世界端：沿用 `ink_fx` 的 `launch`/`heavy`/`slam`/`land`/`brake` 塵。
- 音效：落地與彈跳呼叫現有 `land` 音；KO 衝擊聲沿用原本 `ko`。

## 不影響的範圍
- 最終 KO 仍由 `city_breaker` 負責；低特效（F2）、squad、城市戰役不啟動 tumble，維持舊行為。
- 不改動 `fight_simulation.gd`。

## 驗證
- 新增 `godot/tools/verify_ko_tumble.gd`（11 項：擊飛距離、方向、拋高、翻轉量、靜止、場內、勝者不動、sim 快照不變、低特效略過）。
- `verify_result_presentation.gd` 的「settle」檢查延後到 1.5 秒（等 tumble 完成）；該檔原本就有 3 項 flash owner 失敗（main 基線 12/15），結果仍是 12/15。
- `verify_city_breaker` 165/165；`verify_arena_results` 24/25（與基線相同）。
- 雲端 Godot 4.6.3 + llvmpipe + Dummy 音訊；畫面手感、真實音效與實機（macOS）尚未驗證。
- 證據：`docs/evidence/ko-tumble/ko-tumble-contact-sheet.png`。
