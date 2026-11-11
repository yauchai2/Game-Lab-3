# Godot 4.7.2：截圖15項GDScript警告修正

基線 `ffffd15`。使用官方 Godot 4.7.2.stable.ed1daf0bf Linux x86_64，與截圖引擎版本相同；binary SHA256 `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`。來源：https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable 。原生 Compatibility／Mesa llvmpipe、Dummy audio，不是使用者Mac／實聽驗收。

## 原因與修正

- fight_simulation：2項 STATIC_CALLED_ON_INSTANCE，fresh／perk改由ServiceRules型別直接呼叫，其他有狀態的規則仍用原實例。
- round_theatre：2項 INCOMPATIBLE_TERNARY，音量兩分支統一float。
- city_breaker：5項transform及1項scale遮蔽Node3D屬性，改局部名稱；1項INTEGER_DIVISION改成明確floori，保留每四粒同色的索引。
- dealer_rig：1項global_basis遮蔽，改名finger_basis，骨架演算不變。
- ability_draw：字級整除改明確floori；音量及shader blur分支統一float，共3項。

沒有關閉警告或加入warning_ignore，沒有改動招式／抽獎／過場節奏、原GLB或聲音。

## 重現與驗證

`before-strict-startup.log`／JSON：將截圖四種warning類別在引擎啟動前設為Error，修改前恰好重現15項，五個檔案全數reload失敗。`strict.log`／`strict.json`：修改後5/5通過，沒有ERROR／SCRIPT ERROR。

注意Godot啟動時快取warning等級，主script執行後才用ProjectSettings改值無法保證生效。`initial-probes`保留首次嘗試：5個reload雖成功但沒有把已知警告變成錯誤，因此不當作修正證據；editor探查還產生提前退出清理警告。正式runner改成臨時project的override.cfg，在啟動前設四類為Error，再強制檢查設定，使用者project設定保持。

重跑：`python tools/verify_godot_warnings.py --godot /path/to/Godot_v4.7.2-stable_linux.x86_64`。不要直接執行GDScript測試，它會拒絕未於啟動前設為Error的環境。runner把腳本來源及匯入快取連到臨時project，原project.godot／override.cfg不變。

- `headless/summary.json`：90/90（二段跳62、四面arena18、重砲10）。
- `native/summary.json`：189/189（正式回合24、CityBreaker165），包含camera／building debris清理、F2／skip／pause及真KO入口。
- `ability/summary.json`：85/85（抽獎流程／UI63、原Tripo模型／骨架22），原生渲染／手動DRAW與CONTINUE、NPC手勢、字體及清理。
- 加上五個嚴格編譯檔案，共369項通過；以上最終log沒有ERROR／SCRIPT ERROR。Native VSync不支援警告保留，不冒稱所有驅動層WARNING皆為零。

歷史證據、匯入產生的來源.import及無關UID均已還原。本輪只更新來源main，公開Web未更新。使用者Pull後清除舊Debugger紀錄、停止舊遊戲，再重開F5覆核；截圖上舊紀錄不會因Git更新自動刪除。
