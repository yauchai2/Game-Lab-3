# 街景接回、開放音訊與戰鬥演出

2026-11-07，分支 `codex/street-combat`。依使用者新回饋修正；前一版的幾何拉伸、程序天空與不完整場景組裝，以本紀錄為準。

## 已核對的來源及場景

重新讀取使用者指定的「[Star] 規劃 AI 協作 3D 場景復刻」對話近期交接，並 fetch `codex/flight-street-handoff`，來源仍為 `f9cd82d`。對照其 `street_walk.tscn`、`style_sample.gd`、`environment_textures.gd`、D028、角色貼圖／天空文件。前版戰鬥入口只載白盒和 street_dressing，漏接圖片天空、另外兩件使用者車輛、樣片細節及環境材質。

現在戰鬥場景接回：

- `SKY_BLUE_A01.png` 原圖全景天空、Y 旋轉 90°，與來源遊走場景一致。
- 原六件白盒道具；紅色轎車 `VEH_CAR_A01`（-2.9,0,-17）及箱式貨車 `VEH_TRUCK_A01`（2.6,0,-36）。原白色客貨車也保留。
- 來源街道細節的 854 個批次方塊、住宅陽台、店面遮篷、捲閘、管線、天線，以及 style_sample 的燈球、外伸架、窗框、冷氣機等細節。
- 環境道路、行人道、牆面貼圖，轉卡通材質時保留世界 UV、縮放及偏移；車身貼圖保留原 UV。

街道由 X=2.4 拉伸還原為等比 `Vector3.ONE`。建築、窗框和車輛恢復來源比例；只在現有入口橫街上加十條斑馬線漆，支援左右戰鬥。角色仍位於 Z=3，與背景共用透視相機、陰影和深度，移動追鏡維持 D040–D041。來源 GLB／白盒不改，場景文字仍留白。

飛機機鼻是模型本地 -Z；位移現在直接讀 `-plane.basis.z.normalized()`，避免角度和路徑各寫一份而倒飛。統一縮放 0.75，航道基準移至 (-3,31,-64)，通過屋頂上方；12 秒直線飛越、24 秒週期，暫停時凍結。飛機掠過時可能被畫面上緣裁切，屬街口向上視野；未再為了完整顯示而拉伸模型。

## 描邊取捨

比較 [關閉](evidence/scene-audio-vfx/11_scene_edges_off.png)／[開啟](evidence/scene-audio-vfx/12_scene_edges_on.png) 同一姿勢。預設關閉場景深度描邊，保留角色黑邊，降低遠景窗框、管線和電線的黑線密度。格鬥按 **O** 可比較；暫停選單亦有開關。這是目前構圖的美術取捨，非正式最終風格驗收。

## 音樂與音效

已下載官方開放素材並實際接入。Juhani Junkala 的 CC0《Level 1》循環電子樂，Kenney CC0 Impact Sounds 共 14 個音檔。完整來源、雜湊及授權見 [音訊清單](../references/audio-sources/README.md)。原遊戲影片只作觀察，沒有抽取其素材。

輕拳、重擊、格擋、精準防禦、破防、翻滾、落地及腳步分別觸發聲音；十個 voice 播放器限制同時發聲數。重擊疊加原創低頻層。對局音樂 -13 dB、選單 -19 dB，強命中短暫壓低音樂 4 dB。**M** 全部靜音、**F4** 獨立關音樂；暫停時音樂停止推進，回到遊戲繼續。

## 戰鬥與 VFX

現階段適合加入可讀的局部 VFX：命中／格擋／破防需要即時分辨。新增硬邊白色／角色色命中閃光、雙層揮擊弧、格擋六角盾、金色精準防禦、破防碎片、翻滾塵、擊退速度碎片、蓄力收縮環及短能量波。全部為本專案原創幾何繪圖，分六段時間變化，不用原遊戲圖像；效果先於 HUD 繪製，最多 64 個存活實例。

- Shift 防禦開始前 **6 模擬幀**內成功擋招：精準防禦；不扣生命、消耗 8 防禦、獲得 12 能量，震退對手並僵直 18 幀；冷卻 90 幀，需要至少 25 防禦。持續按住超過窗口仍是普通防禦。AI 暫不使用精準防禦，避免讀取玩家攻擊後即時反制。
- 打中對手的起手階段：COUNTER HIT，傷害增加 15%，四捨五入。原有有效幀交換及連擊保留。
- F2 減少閃光／震動，省略速度碎片、擊退拖尾與重擊黑色中心，降低粒子數。

額外抽看使用者 Drive 參考影片約 65–69 秒、每秒兩張影格，觀察清楚的圓形命中閃光、小塵和短揮擊弧；這不是完整觀看或原遊戲時序測量。玩法仍是直接近身格鬥。

## 驗證與重現

Godot 4.6.3：新場景／音訊／VFX 33 項、警告編譯 3 項、格鬥 34 項、既有動畫／鏡頭／留白 30 項、自動 viewport 輸入 11 項、遊走 28 項、街道 13 項、飛機 11 項，共 **163 項通過**。警告檢查把 shadowed_variable_base_class、shadowed_global_identifier、integer_division 提高為錯誤，覆蓋使用者截圖的四項訊息。

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --audio-driver Dummy --script res://tools/verify_scene_audio_vfx.gd
godot --headless --path godot --script res://tools/verify_editor_warnings.gd
godot --headless --path godot --fixed-fps 60 --audio-driver Dummy --script res://tools/verify_flyby.gd
```

完整日誌、JSON、16 張軟體渲染截圖、[含聲自動示範](evidence/scene-audio-vfx/scripted-demo-with-audio.mp4) 位於 [證據目錄](evidence/scene-audio-vfx/)。示範 420 幀腳本控制加六幀音訊清理結尾，1280×720、60 fps、7.1 秒，含 AAC 立體聲；FFmpeg peak -7.7 dBFS，音軌有訊號且此片段未削波，不代表實聽驗收或整場混音保證。

畫面使用 Xorg dummy / Mesa llvmpipe / Godot Compatibility。未做真人操作、真人實聽、目標 GPU 或硬體 FPS 測試。既有獨立飛機／街道測試退出仍可能有 AudioStreamWAV ObjectDB 清理警告；新格鬥場景、含聲影片和擷取清理流程另行驗證。選定天空與車輛已恢復，不代表完成原照片所有細節或正式美術驗收。招牌貼圖、第二角色、投技和空中追擊仍待後續。
