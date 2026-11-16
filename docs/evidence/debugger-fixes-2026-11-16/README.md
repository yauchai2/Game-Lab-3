# 使用者 Debugger 截圖修正（2026-11-16）

來源main `9e79b09`，使用者截圖Godot4.7.2：22項GDScript警告及world_ink_fx.gd:225多邊形三角化錯誤。雲端本次為Godot4.6.3 Linux Compatibility／Mesa llvmpipe、Xvfb、Dummy音訊，不能宣稱已重測使用者Mac／4.7.2。

## 警告修正

- translation_catalog：char改character；gun_shot移除未用、無副作用的at字典。
- rivet_motion兩處、mixamo_profiles及rivet_shutdown的load改具體的load_weight／load_phase；paired_throw_motion的convert改pose_basis。
- fight_vfx移除未用radius；hub_widgets的wrap改wrap_text、兩個local row改line，保留row()函式及全部建UI操作。
- fight_spectacle的sign改strike_direction；story_opening/stage兩個prop改scene_prop、print改lid_print；rug仍建立、接到場景，僅變數改_rug。
- cinematic/story_opening的advance改step_progress；workshop的sign改door_plate。
- hub_pages移除未用jname／chapter／stars，END RUN按鈕仍建立並保留callback，只去掉未用變數接收。

既有嚴格編譯從7類增至10類，加入shadowed_global_identifier、shadowed_variable、unused_variable，23個腳本擴至33個。沒有壓低警告設定或加warning_ignore。修前[嚴格log](warnings-before-strict.log)／[報告](warnings-before-strict.json)重現失敗，包含依賴錯誤；修後[log](warnings-final-strict.log)／[報告](warnings-final-strict.json)33/33、無ERROR／SCRIPT ERROR。

## 殘影多邊形

原本只檢查3D兩端距離，不能保證2D投影後有面積；朝相機移動可投成重疊端點，末端寬度亦可能消失。現在跳過相機後方端點、非有限座標／寬度、重疊或極小端點距離、零寬／負寬、零面積及無法三角化的quad；有效quad沿原來位置／顏色／形狀繪製，不改simulation。

[渲染測試14/14](ink-trace-after.json)／[log](ink-trace-after.log)：重疊、極近端點、過期寬度、負寬、非有限值、浮點精度丟失寬度、144種正常方向／寬度仍可三角化；實際canvas draw及HUD路徑、暫停／F2／退出。原始main的殘影繪製程式亦在相同fixture執行，保留[before log](ink-trace-before.log)；4.6.3並未輸出使用者4.7.2那句triangulation錯誤，因此不能聲稱同版原生錯誤已重現。修正直接阻止上述不合法幾何送進draw_colored_polygon，仍需使用者Pull後在4.7.2實玩確認。

## 相關回歸

| 測試 | 結果 |
| --- | --- |
| 繁中／槍械 | 21/21、21/21 |
| 配對肩摔／故事開場 | 147/147、44/44 |
| RIVET動作／停工通知（原生） | 19/19、25/25 |
| 據點（原生） | 30/30 |

據點原測試仍斷言舊960×540。完整隔離main基線9e79b09同為29/30，唯一失敗相同，見nightshift-baseline.log／json；正式city_hub早已是1280×720。本輪僅更新測試明確驗現行1280×720，沒有改遊戲viewport或放寬其他導航／購物／退出斷言。保留第一次候選29/30及後續nightshift_hub-final.log／nightshift-reference-verification.json，不冒稱第一次就全通過。

接受執行皆exit0、無ERROR／SCRIPT ERROR；Xvfb的VSync警告另列。RIVET shutdown測試退出有ObjectDB資源未釋放警告，保留原log，不當成乾淨退出。其他結果檔為當輪產物，既有證據資料夾已恢復歷史版本；log僅去除行尾空白。Web未部署，真人手感與硬件效能未在此次驗證範圍。

執行：`python tools/verify_godot_warnings.py --output <證據目錄>`；渲染測試用正常Compatibility而非headless：`godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_ink_trace_geometry.gd -- <報告json路徑>`。
