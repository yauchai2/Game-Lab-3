# 2026-11-15 分支整合驗證

來源基線：main `f9576c5`。逐分支 SHA 與是否原已納入見 [branches.json](branches.json)，本輪結果見 [validation.json](validation.json)。35個遠端分支中，main及27個來源分支原已納入；其餘6個來源分支本輪合併，只有獨立發佈用gh-pages排除。來源分支全部保留。

## 接受結果

以下21個suite最終執行均成功，log無ERROR／SCRIPT ERROR。各suite有重疊，不能相加宣稱獨立測例總數。Godot 4.6.3、Linux Xorg／llvmpipe、Dummy音訊；combat與strict使用headless。不是使用者Mac／真人／實體手柄／硬體效能或實聽驗收。

|Suite|通過項目|Log|
|---|---:|---|
|verify_rivet_drop|14|[verify_rivet_drop.log](verify_rivet_drop.log)|
|verify_rivet_shutdown|25|[verify_rivet_shutdown.log](verify_rivet_shutdown.log)|
|verify_zip_delivery|44|[verify_zip_delivery.log](verify_zip_delivery.log)|
|verify_zip_express|23|[verify_zip_express.log](verify_zip_express.log)|
|verify_zip_run|22|[verify_zip_run.log](verify_zip_run.log)|
|verify_continuous_motion|79|[verify_continuous_motion.log](verify_continuous_motion.log)|
|verify_rivet_motion|19|[verify_rivet_motion.log](verify_rivet_motion.log)|
|verify_street_motion|90|[verify_street_motion.log](verify_street_motion.log)|
|verify_transit_motion|216|[verify_transit_motion.log](verify_transit_motion.log)|
|verify_motion_completion|554|[verify_motion_completion.log](verify_motion_completion.log)|
|verify_paired_throw|147|[verify_paired_throw.log](verify_paired_throw.log)|
|verify_paired_throw_render|65|[verify_paired_throw_render.log](verify_paired_throw_render.log)|
|verify_mixamo_batch|179|[verify_mixamo_batch.log](verify_mixamo_batch.log)|
|verify_mixamo_library|14|[verify_mixamo_library.log](verify_mixamo_library.log)|
|verify_gun_shot|21|[verify_gun_shot.log](verify_gun_shot.log)|
|verify_last_service_rules|46|[verify_last_service_rules.log](verify_last_service_rules.log)|
|verify_traditional_chinese|21|[verify_traditional_chinese.log](verify_traditional_chinese.log)|
|combat|34|[combat-headless.log](combat-headless.log)|
|dressing|13|[dressing-rerun.log](dressing-rerun.log)|
|motion-strict|18|[motion-strict.log](motion-strict.log)|
|godot-strict|23|[godot-strict.log](godot-strict.log)|

## 整合修正與初期診斷

通用Mixamo profile最初會覆蓋ZIP／RIVET的地面special／overdrive：RIVET落鉚2項、停工通知4項、ZIP末班快送4項失敗。明確將這四招交還影片專用owner，保留所有普通招式、步法、挑空與空中Mixamo，原傷害與固定判定不動；三個技能suite現在全過。其他歷史street／transit／RIVET檢查仍假設舊CC0 owner、右手挑空或舊clip名稱；已更新為當前Mixamo接觸肢體及專用技能分工，原接地、骨架有限、F2、停格、無simulation寫入等條件均保留。

初期未完成匯入便啟動strict造成缺cache；完成資源匯入後重跑18／23 strict全過。部分舊runner固定寫歷史證據目錄，不接受out參數；稀疏checkout缺目錄導致初期null output，建立目錄後重跑並保存到本目錄，原歷史證據還原。

額外探索檢查不計入上述通過：

- [原生編輯器環境失敗](diagnostics/editor-environment-failure.log)：此Xorg軟體環境缺VK_KHR_surface，編輯器壓縮材質匯入失敗／中止；headless初次匯入另見dummy texture Parameter t null，不能把編輯器匯入當成無錯通過。沒有修改專案render設定或原材質import配置來掩蓋環境問題。
- [舊原生combat退出](diagnostics/legacy-native-combat-cleanup.log)：34項規則通過，但原生退出有兩個GL texture leak。最終按此套件原本用途以headless重跑34/34且無ERROR，僅以後者作玩法驗收；原生清理不宣稱已全面修復。
- [walk指標環境限制](diagnostics/walk-pointer-environment.log)：28項數值檢查通過，但Xorg無原生輸入裝置而有NO GRAB，故不把這次執行當完整遊走／實體滑鼠通過。相關街景及碰撞另由dressing13/13乾淨通過。

未更新公開Web、未改gh-pages、未宣稱已同步使用者電腦。
