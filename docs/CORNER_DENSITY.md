# 街角立面與兩側街區加密

2026-11-08（香港時間），`codex/street-combat`。依使用者最新寬幅照片，解決藍樓、橙樓的正面過空，以及左右缺少相鄰舊樓的問題。這輪只更新原始碼與 Godot 場景，**沒有更新公開試玩版**。

[照片比例寬景](evidence/corner-density/candidate/07_panorama_reference.png) · [前後對照](evidence/corner-density/compare_07_panorama_reference.jpg) · [一般戰鬥視角](evidence/corner-density/candidate/01_fight_center.png)

## 內容

- 藍樓朝向斑馬線的一面加入四層窗框、窗籠、冷氣機／風扇／托架、滴水痕、排水管、瓷磚基座、店面、捲閘、遮篷及屋頂天線。
- 橙樓正面加入五層外伸陽台、欄杆、支撐、部分花槽、窗戶與冷氣機，並補雙球壁燈、石材感柱腳和店面。
- 左右各三棟相連的舊樓，共六棟；用不同高度、退縮、色調、窗籠、陽台及店面開閉狀態打破單一立面，延伸兩側道路與行人道。
- 街邊新增兩輛低面數摩托車、展示牌、木箱、花盆、電箱及架空線，另復用使用者原轎車包裝在兩邊路緣停放。原街內紅車、白色客貨車及貨車保留。
- 路面加入低對比補丁、坑蓋及排水格。保留空白招牌，沒有生成中文字、亂碼或新塗鴉；等待使用者之後的貼圖。

新增層在格鬥與 F6 遊走共用；原始 `street_whitebox.tscn` 及所有 GLB 位元不變。圖片天空、機鼻飛行方向、街道比例、角色與相機規則不變。細節在執行場景時生成，須 F5 看實際結果，並非直接修改原白盒。

## 幾何、表面與繪製

`corner_streetscape.gd` 建立 **3,001 個程序幾何實例、10 個 MultiMesh 批次、8 份共用材質**，加兩個既有轎車場景。窗框、管線、欄杆與店面用簡單硬邊幾何；球燈、風扇和車輪的圓形網格轉為每三角面平面法線。六個樓體、兩段人行道與兩輛摩托車用簡單盒碰撞，車輛沿用原包裝碰撞。

三張新 128×128 原創低清乘色貼圖：斑駁灰泥、瓷磚灰縫、捲閘／棚面條紋。nearest+mipmaps，各 7 層；牆面 32 px/m，瓷磚與捲閘 64 px/m。沒有加 Normal／Metallic／Roughness 貼圖。生成器與雜湊在 [來源清單](../references/scene-detail-sources/corner-textures.json)，不抽取參考照片像素。

既有 toon shader 新增預設關閉的 `use_instance_color`，只有新批次使用 MultiMesh 乘色。細件不投影，樓體／陽台結構批次投射硬陰影；燈球使用無光材質，不新增逐盞即時光源。未拉長建築或模型。

## 保護玩法與可逆性

以 X ±8.8 m、Y 0.04–4.3 m、Z 2.4–4.4 m 保留完整跑動／跳躍範圍，所有新增幾何和盒碰撞均不相交。地面漆／坑蓋低於此範圍；街邊雜物在外側或角色後方。既有遊走道路、側巷及燈柱配置也有回歸檢查。

原始程式改動前的中央畫面，與新程式隱藏 CornerStreetscape 層的中央畫面逐像素相同，證明 shader 的預設開關沒有改變原畫面。其他材質模式及來源模型仍保留。

## 原生 Godot 驗證

- 新 28 項：兩側加密、六個鄰樓、碰撞、3D 包圍範圍、批次／材質、透明度、法線、三張貼圖與 mipmaps、編譯警告提高為錯誤，以及格鬥／遊走雙組裝。
- 回歸：遊走 28、街景 13、骨架／相機／留白 30、格鬥 34、練習／追擊 35、場景／音訊 33、取樣材質 11、X11 原生 viewport 自動輸入 11、原四項警告所涉腳本 3，共 **226 項通過**。
- Godot 4.6.3 Compatibility／Mesa llvmpipe，七個固定視角前後對照：中央、左右追鏡、寬景、兩側店面、照片比例寬景。相同相機／FOV／畫幅，baseline 只隱藏新層；另保留最初未修改程式時的六張圖。
- 1280×720 中央 draw calls **963→978**，primitives **118,766→165,930**；1280×544 寬景 draw calls **1,053→1,075**，primitives **113,026→170,858**。這是此相機與軟體 renderer 的繪製統計，不是硬體 FPS，亦不宣稱加細節後效能更快。

[完整證據](evidence/corner-density/)包含日誌、相機、像素差、材質／幾何指標及來源雜湊。像素差只是變更量，不是美術品質分數。部分既有快速音訊測試退出仍有 playback／ObjectDB 清理訊息；原生場景擷取沒有腳本或 shader 錯誤。

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --audio-driver Dummy --script res://tools/verify_corner_density.gd
# Requires a native display; this task used Xorg :95 with software GL.
DISPLAY=:95 LIBGL_ALWAYS_SOFTWARE=1 godot --path godot --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x720 --script res://tools/capture_corner_density.gd -- res://../docs/evidence/corner-density/candidate
```

## 同步與未驗證範圍

日常只推送 `codex/street-combat`，供 GitHub Desktop Fetch／Pull；**只有使用者明確要求才更新 gh-pages／公開試玩版**。這輪未匯出或部署 Web，Pages 來源為 gh-pages，分支提交保持 `2908503`。

本次實際執行的是雲端 Linux Godot；不能聲稱已寫入使用者電腦、替其 GitHub Desktop Pull 或完成其硬體測試。請在 Desktop 選 `codex/street-combat` → Pull，再以 Godot 開啟 `godot/project.godot`、F5；F6 檢查遊走。完整本機指引見 [GITHUB_DESKTOP.zh-TW.md](GITHUB_DESKTOP.zh-TW.md)。

真人視覺／手感、目標顯示卡、斜角移動的細線閃爍，以及使用者將提供的正式招牌貼圖仍待驗收。相鄰店面是按照片內容類型重建，不是照片所有建築的逐件量測複刻。
