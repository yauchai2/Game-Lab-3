# 接續工作交接

更新日期：2026-11-06（Asia/Taipei）。本紀錄只根據本聊天與實際檔案，不假設其他對話內容。

## 同步前讀取範圍

- 原工作區 repo：`/workspace/Game-Lab-3`，本地分支 `work`，乾淨，HEAD 為 `cbf117aa36b0237bcf1c1c083ae33cd148c5d0c4`。
- GitHub 遠端當時只有 `main`，同一初始提交，只有 README.md；未發現 AGENTS.md、設計／待辦／交接文件或開啟中的 PR。
- 本次已讀當時 README，查詢遠端分支／檔案／PR，再 fetch 建立獨立任務分支 `codex/flight-street-handoff`。本次新增 AGENTS.md 以記錄使用者要求的協作規範。
- 這是讀取時的快照，不表示未來 main 或其他任務分支沒有新增成果；接續前必須重新確認。

## 現有成果

`godot/` 已包含六件資產展示及 S1 街道白盒。主場景為 S2 `scenes/street_walk.tscn`，已可操作測試角色；1–5／Tab 為固定視角、0 返回角色。原 S1 `street_whitebox.tscn` 與資產展示 `review.tscn` 保留。所有 GLB 原始資料未改動；尺寸與簡化碰撞在各包裝 .tscn。`assets-manifest.json` 記錄來源雜湊與狀態；`references/assets/` 包含七種資產的參考圖；`docs/evidence/` 有原型預覽與載入紀錄。

已確認的偏好與取捨見 [DECISIONS.md](DECISIONS.md)。設計基準見 [DESIGN.md](DESIGN.md)。完整原聊天計劃保留於 [archive/chat-plan.zh-TW.md](archive/chat-plan.zh-TW.md)，其中歷史工作區附件路徑不可當成 repo 檔案。

## 從哪裡接續

1. 讀取 AGENTS.md、README.md、本文件、TODO、DESIGN、DECISIONS 和 VALIDATION，確認最新分支與修改。
2. 重跑 Godot 匯入與 `verify.gd`，確認當前環境能使用六件資產。
3. 讀取 [WHITEBOX.md](WHITEBOX.md)，查看 S1 的四個固定視角與俯視布局；白盒已實作，等待使用者構圖回饋。
4. 保留 `godot/scenes/review.tscn` 作資產對照；新街道另建場景。
5. S2 控制器與 28 項無視窗檢查已完成，詳見 WALK.md。S3 入口風格樣片已完成原始／兩段／三段材質比較及軟體渲染檢查，詳見 STYLE_SAMPLE.md；S4 飛機事件原型已實作，見 FLYBY.md；下一步是人工看圖、試玩與聆聽，並按回饋精修。先不要求使用者追加付費道具生成。

## 驗證與缺口

來源 GLB 雜湊、Blender CPU 預覽和 Godot 無視窗載入有證據；GPU 畫面、實際遊玩與效能尚未驗證。詳細範圍見 [VALIDATION.md](VALIDATION.md)。

原參考照片、三段影片及部分額外三視圖未加入 repo。需要時請明確說明缺少哪些素材，不能聲稱已觀看不存在的來源。轎車只有參考圖，尚未收到模型。

## 同步原則

本次僅提交與推送任務分支，供審查及跨對話接續；不自動合併 main 或發佈。若其他分支後續新增成果，先讀取並保留，再整合本任務所需部分。

## 此次 repo 重新驗證

六件原始 GLB 與來源 SHA-256 一致；Godot 4.6.3 在本 repo 重新匯入和載入成功。模型、場景、參考圖及非歷史文件的本地連結均核對存在。證據見 VALIDATION.md 的「任務分支重新驗證」。

## 遠端接續位置

- 任務分支：[codex/flight-street-handoff](https://github.com/yauchai2/Game-Lab-3/tree/codex/flight-street-handoff)
- 草稿 PR：[#1](https://github.com/yauchai2/Game-Lab-3/pull/1)
- 首次完整同步提交：`532670dadee274a643d8faea88b1484714354ae8`。本節連結為後續補充紀錄；以遠端分支最新提交為準。

目前未合併 main、未發佈。若後續要接續本成果，先讀任務分支或 PR 的最新內容，不要只讀尚未合併的 main。

## S1 街道白盒更新

已讀取任務分支最新規範並保留六件來源資產及原展示。新增參數配置、生成器、街道場景、四個固定相機與俯視相機、1–5／Tab 切換，以及 Godot 結構／相機／物理射線檢查。飛機位置與朝向經入口預覽調整，屬美術構圖參數，非航空實測。

現有環境沒有 Xvfb 顯示服務，未取得 Godot GPU 畫面；改用 Godot 匯出的同一份幾何在 Blender Cycles CPU 產生五張預覽。操作與重現步驟見 WHITEBOX.md。尚未完成玩家控制器、事件聲音、最終 toon 或硬體效能。

五張 CPU 預覽已完成並檢查，側巷缺少地面基底的問題已修正；入口保留道路與現有道具前景。新白盒檢查涵蓋 1–5 鍵、Tab 循環、八個地面射線取樣與配置指紋，結果見 docs/evidence/whitebox/。下一步等待構圖回饋並實作 S2，勿將 S1 固定相機當成行走控制器。

## S2 遊走更新

新增獨立遊走組裝場景與比例替身控制器，保留 S1 幾何、固定相機及六件來源 GLB。已實作第三人稱預設、V 切第一人稱、走／加速／跳、滑鼠視角、SpringArm 碰撞縮短、0／1–5／Tab 相機切換、R 重設及掉落回復。游標釋放或失焦時暫停移動輸入，點擊恢復。

Godot 4.6.3 在 headless 模式以實際物理幀測試 28 項情境通過，包括超過 50 m 的主街移動、人行道跳躍、側巷與主要障礙碰撞。游標鎖定僅驗證應用程式要求，無視窗環境不能驗證真實桌面游標。未新增 S2 畫面或人工試玩證據，操作與範圍見 WALK.md。

## S3 風格樣片更新

入口左右約 14–16 m 立面、主招牌及消防栓／廂型車已加入可逆材質樣片；B 鍵比較原始材質、兩段與三段明暗。樣片裝飾包含欄杆、球燈、遮雨棚與冷氣，來源 GLB 未改動，原 S1 場景保留。細節與圖片見 [STYLE_SAMPLE.md](STYLE_SAMPLE.md)。

Godot Compatibility 使用 Xorg dummy + Mesa llvmpipe 軟體 OpenGL 實際擷取，12 項樣片結構檢查、28 項遊走回歸及來源雜湊均通過；投影開關與兩／三段畫面差異有記錄。這不是硬體 GPU 效能測試，也未代替人工風格／遊玩驗收。招牌使用系統字型後備，跨平台需確認。

## 新增風格參考與下一步

使用者於本聊天提供兩張自行生成的街景風格參考，並詢問下一步。兩圖分別偏立體低面數暖日光與高對比漫畫式陰影；共同強調低空客機、黃框直立招牌與窄街冷暖對比。詳細觀察及建議順序見 [風格參考紀錄](design/style-references-2026-11-06.zh-TW.md)。

建議先依新參考微調 S3 的局部風格，再推進 S4 客機機腹／輪組與可重設掠過事件。這是工作建議，使用者尚未確認最終混合比例或完成風格驗收；當時新調整與 S4 尚未實作；後續實作見下方。當時僅新增規劃紀錄；後續實作見下方 S4 更新。

新參考原圖僅在聊天內可見；本次環境沒有可保存的圖檔識別，原圖未同步至 repo，後續對話不得假稱已讀取 repo 中的原圖。

## S4 飛機事件與參考圖調整（最新）

延續前次建議，調整天空／暖光、窗框與街道招牌，並在遊走場景加入自動觸發 9 秒飛機航路、P 重播、程序補充的輪組／襟翼及可替換的原創合成測試音。S1 獨立場景、六件原始 GLB 未改動；玩法優先級、風格定案均未決。事件詳細規格、入口三個凍結畫面、控制與限制見 [FLYBY.md](FLYBY.md)。

Godot 4.6.3 headless 11 項事件檢查、28 項遊走、12 項風格回歸與六件資產載入／雜湊通過。Godot Compatibility 在 Xorg dummy／llvmpipe 輸出截圖，非硬體效能或動態人工遊玩。Dummy 音訊僅測狀態，未實際收聽；測試退出有 ObjectDB 清理警告待追查。下一步請使用者實際打開專案確認構圖、操作、飛機時機與聲音，再按回饋精修飛機／招牌並評估 S5；不用先新增付費 Tripo 資產。

## GitHub Desktop 協作與天空參考（最新）

使用者提議以 GitHub Desktop 取得更新、在 Godot 本機查看。建議採用；完整首次 clone、切換任務分支、後續 Fetch／Pull、保留本地修改及試玩回饋見 [GITHUB_DESKTOP.zh-TW.md](GITHUB_DESKTOP.zh-TW.md)。不假設使用者已完成同步，現有草稿 PR 未合併。

使用者在本聊天提供一張藍天與分層白／淺藍積雲圖片，詢問是否需要；可作雲形、色彩及圖形化分層的方向參考。聊天內可見圖片，但目前沒有可存取的原圖檔案識別或已保存副本，未納入 repo 或實際遊戲；是否直接採用圖像及最終天空表現尚未決定。單張橫幅不自動等同可無縫環繞的 360° 天空，實作前需處理接縫／極區，或改用程序天空與雲層。現階段不要求額外付費生成。

本次僅新增操作與交接文件，未更改 Godot 程式或實作天空；首次建議由使用者本機查看 S4，回報飛機構圖與時間、天空色調及暫用音量。

## 程序天空樣片（最新）

在遊走場景加入深藍天空和靜態白／淺藍分層雲；按 C 與原青藍純色背景比較，B 材質和 P 飛機操作保留。以程式依聊天中圖片的可見風格詮釋，並未匯入原圖；S1 白盒未變。實作、四張 Godot 軟體渲染截圖和局限見 [SKY_SAMPLE.zh-TW.md](SKY_SAMPLE.zh-TW.md)。

Godot 4.6.3 headless 的 7 項天空邏輯、12 項風格、28 項遊走及 11 項飛機事件回歸通過。雲是靜態簡化圖形，完整 360° 接縫、使用者電腦的 GPU、實際畫面和音效仍待人工驗證；現有飛機回歸的 ObjectDB 退出警告未解決。下一步請使用者透過 GitHub Desktop 同步任務分支並比較天空及飛機，再依回饋調整。

## 天空環視與雲形調整（最新）

入口上方加入兩朵不同尺寸／比例的小雲，後方一朵跨越角度接縫；使用者仍可按 C 比較原純色背景。新畫面與特定角度、指定像素區域的接縫測試見 [天空文件](SKY_SAMPLE.zh-TW.md)。Godot Compatibility／llvmpipe 擷取八方向，以及 0°／360°、±180° 與 ±179.75°；匹配與對齊差異檢查通過，並非所有俯仰／硬體均已驗證。天空邏輯 7 項回歸通過。原 S3／S4 截圖保留為歷史，音效與飛機回歸退出警告仍需後續處理。

接續仍應請使用者透過 GitHub Desktop 的任務分支查看，確認天空、飛機時機與聲音，並依回饋調整；這次沒有發佈、合併或使用 Tripo。

## Tripo 轎車候選準備（最新）

使用者詢問還可用 Tripo 生成甚麼；建議先選原有參考但未收到 GLB 的靜態港式轎車，作為廂型車之外的第二款車輛。AI 根據 repo 既有三視圖拼版生成獨立的左前斜角單車圖 [VEH_CAR_A01_ref_v002_3quarter.png](../references/assets/VEH_CAR_A01_ref_v002_3quarter.png)，用於單圖測試；原拼版保留。生成、匯出規格與回傳後檢查詳見 [TRIPO_CAR.zh-TW.md](TRIPO_CAR.zh-TW.md)。

建議沿用 P1.0、先生成 1 個候選、三角面 1,500 作起點、GLB 1K；車輛靜態無需拆分。這些是建議非使用者已執行的操作，具體可選設定與費用須以其網頁為準。目前尚未收到轎車模型，未匯入／未驗證，既有六件與遊戲程式未改；天空、建築等仍可由 AI 製作。

## 轎車整合與下一個 Tripo 候選（最新）

收到使用者轎車原始 GLB，SHA-256、面數 1,524、1024×1024 貼圖與尺度見 [資產清單](../assets-manifest.json) 及 [完整性證據](evidence/car/integrity.json)。檔案直接複製，未修改來源；在 `street_walk.tscn` 以 `VEH_CAR_A01.tscn` 包裝為長 4.2 m 靜態碰撞物，放在街道左側，原 `street_whitebox.tscn` 與六件展示場景不變。轎車包含在 B 材質比較中。使用者未提供此檔實際 P1/P2 設定，不能從檔案推定。

Godot Compatibility／llvmpipe 的[街道正面](evidence/car/01_front_street.png)與[背面](evidence/car/02_back_street.png)顯示車輛輪廓可辨；車身在陰影下較暗，等待人工評估。headless 6 項轎車／碰撞檢查、28 項遊走、12 項樣片、11 項飛機回歸及 7 件載入檢查通過；退出仍有既存 ObjectDB 音訊清理警告。未進行硬體 GPU／人工試玩或聲音驗收。遊戲資產製作 skill 建議的 `game-dev` CLI 此環境不可用，本次使用現有 Godot 與靜態檢查流程，未執行 CLI 正規化或建立 canonical package。

依使用者詢問，建議可選下一個 Tripo 候選為箱式貨車，單車參考圖及設定見 [TRIPO_TRUCK.zh-TW.md](TRIPO_TRUCK.zh-TW.md)；尚未收到貨車 GLB，費用及生成由使用者控制。

## 使用者貨車與生成圖片天空（最新）

收到 `tripo_convert_8e7c67cc-8882-42c4-9474-56e4cb8c677c.glb`，原始 SHA-256 `b15a7535ab7f2f173472ffe002ead8e246883ff9252cc11efb6769cc09b83228`，1,510 三角面、1K 貼圖，生成版本未由使用者明示。原始檔未改，新增 5.5 m 盒碰撞包裝並放在主遊走場景右側 `Vector3(2.6,0,-36)`，包括在 B 材質樣片；原 S1 白盒不變。Godot llvmpipe [前](evidence/truck-sky/03_truck_front.png)／[後](evidence/truck-sky/04_truck_back.png)顯示駕駛室及箱體可辨，背面為平面、無明顯門件，待人工評估。

依使用者提供遊戲畫面，生成原創 1774×887 圖片 `godot/assets/SKY_BLUE_A01.png`，N 切換該圖片／程序天空，C 仍控制純色／程序。截圖及原圖邊界／指定視角檢查見 [天空文件](SKY_SAMPLE.zh-TW.md)，原參考截圖僅在聊天中，並非 repo 素材；圖片全景尚待人工、其他角度及目標硬體驗收。

Godot headless 11 項貨車／天空切換測試、28 項遊走、12 項風格、7 項天空、11 項飛機、6 項轎車及八件資產載入回歸通過；部分測試退出仍有既存 ObjectDB 音訊清理警告。未進行人工試玩、實際音效或硬體 GPU／效能測試。

## 港式街景優化、飛機與描邊（最新）

依使用者要求持續製作，新增程序街景 `godot/scripts/street_dressing.gd`：店面、原創招牌、窗框、冷氣、街燈與碰撞、天線電線、斑馬線、路面細節及遠景。貨車原 GLB 不動，包裝場景增加後門。遊走飛機位置改至 `(-6,41,-52)`、yaw −150°、12 秒航路，加入綠色機頭與機身色帶；S1 白盒原設定不變。O 開關可選描邊，預設關閉；B、C、N、P 等原功能保留。

Godot 4.6.3 headless 13 項新場景檢查、28 遊走、12 風格、7 天空、11 飛機、6 轎車、11 貨車及 S1／八件載入／雜湊回歸均通過。Godot Compatibility／llvmpipe 擷取 16:9 前後對比、輪廓對照與 12.1 秒無聲連續飛越影片。指定 800×450 鏡頭的渲染繪製呼叫從 1,871 降至 1,131，兩次含少量細節差異，非 FPS 數據。方法與[證據](STREET_POLISH.zh-TW.md)；音效未實聽、目標 GPU 未測、ObjectDB 退出清理警告未解決。最終風格及人工操作仍需使用者回饋。

乾淨副本驗證：從提交 `9eff39c` 的 Git archive 在另一目錄重新匯入並 headless 啟動成功，未見腳本或 shader 錯誤；退出的 ObjectDB 音訊清理警告仍存在。詳見 STREET_POLISH.zh-TW.md。

## 角色、圖片天空與低清街景（2026-11-06，最新）

使用者明確選圖片天空、提供 `character-1.glb` 和 Hinata 參考影片。圖片天空現在為預設，N 可比較程序天空。角色原始 GLB 不改，含 65 骨骼、1,664 三角面、0 動畫；包裝縮放 1.75，使用速度驅動暫用步態。原始骨架與材質、影片識別及取樣範圍、貼圖與局限見 [CHARACTER_TEXTURES.zh-TW.md](CHARACTER_TEXTURES.zh-TW.md)。

環境新增 128×128 程序路面／行人道／牆面貼圖、生成塗鴉、招牌支架及飛機自陰影斑點修正；保留獨立 S1。headless 九組場景檢查均通過，角色與街景截圖由 llvmpipe 擷取。這不是人工試玩或目標 GPU 驗收；正式角色動畫、聲音、性能仍待處理。使用者可在 GitHub Desktop 同步 `codex/flight-street-handoff`，以 Godot 開主場景。

## JSR／BRC 製作規範（2026-11-06，最新）

收到使用者 `jsr_brc_3d.md`，原檔保存於 `references/guidelines/`（SHA-256 `7547594616f67916d3d35c6c1211bf46f8731ba337c1c2a48793b0c0c287b0de`）；另將其他對話提交於 `origin/main` 的 `docs/JSR-BRC-style-reference.md`（提交 `54a520d`）原樣複製至本分支，未合併整個 main。規範作製作目標，非已獨立驗證的原遊戲技術事實。

現有角色 1,664 tris，入口牆與道路 32 texels/m；卡通牆面 Shader 原本線性過濾與標準材質不一致，現改用 nearest+mipmaps，角色／道具 UV 取樣不變。具體對照、保留 mipmaps 的取捨、未實作清單與圖像檢查見 [專案對照](JSR-BRC-project-application.zh-TW.md)。

## 環境貼圖 mipmap 匯入修正（2026-11-07，最新）

前次材質選 nearest+mipmaps，但三張貼圖匯入實為 `mipmaps/generate=false`；已將道路、行人道和牆面的 `.import` 設為 true，不改原圖。Godot 實測每張 128×128 的 mipmap 數量為 7 層（不含原圖），材質切換回歸通過。未進行移動畫面與硬體 GPU 驗收，舊比較截圖為修正前。詳見 [專案對照](JSR-BRC-project-application.zh-TW.md)。

## 飛機音效退出警告調查（2026-11-07）

Godot 4.6.3 headless verbose 飛機測試 11 項通過，但退出仍提示 `AudioStreamWAV` 和 `AudioStreamPlaybackWAV` 未釋放；臨時測試停止後把 `sound.stream` 設為 null，警告仍存在，該實驗沒有保留於程式。原始及實驗紀錄位於 `docs/evidence/audio-diagnostics/`。這只定位測試退出時的現象，尚未證實原因或修復，未聆聽音效。

## 陽台花槽與外伸架（2026-11-07）

依原照片右側橙色立面，遊走場景增添三層低面數花槽、綠色植物與數個外伸金屬架；全部使用既有 MultiMesh 批次、位於高處且不加碰撞，獨立 S1 及原 GLB 不改。[入口畫面](evidence/balconies/01_entry.png)、[側面畫面](evidence/balconies/02_sidewalk.png)為 Godot Compatibility／llvmpipe 軟體渲染；場景結構與遊走測試通過，硬體 GPU、人工操作與最後美術仍待驗證。

## 中段街道店面層次（2026-11-07）

依使用者希望增加場景複雜度，在遊走場景加入四處淺遮篷、兩處捲閘及外牆管線，使用現有 MultiMesh 材質分組、不新增碰撞。S1 與原 GLB 保留。Godot Compatibility／llvmpipe 截圖與 headless 街景、遊走回歸見 [streetfront](evidence/streetfront/)；未作目標 GPU 或人工驗收。下一步仍是逐段提升立面差異、遠近景深及角色描邊，同時維持可走性與效能。

## 舊樓陽台與天線（2026-11-07）

在遊走場景五個舊樓位置加入三層外伸陽台、欄杆及簡化晾曬色塊，四處加天線；均使用現有批次及高處非碰撞裝飾。原始 GLB 和 S1 保留。Godot llvmpipe 仰視圖見 [住宅立面](evidence/residential/03_left_facade.png)，街景與遊走測試通過。相同 800×450 固定鏡頭軟體渲染，開啟街景細節時的 draw calls 前後均為 1,131，primitives 為 86,297→88,181；不是 FPS 或目標硬體效能測試。

## 角色近身格鬥：第一個可玩里程碑（2026-11-07）

依使用者本聊天指定「類 Lethal League Blaze 但不是擊球，而是打鬥」，從 `codex/flight-street-handoff` 的 `f9cd82d` 建立 `codex/street-combat`，復用現有街景與角色，加入玩家對 AI、固定對手練習、三段輕連擊、重擊、挑空、防禦破防、衝刺、能量技、動態頓幀、輸入緩衝、計分、兩勝賽制、暫停和重賽。主場景改為格鬥主選單，遊戲內 F6 在格鬥／原遊走之間切換。

原始 GLB 不改；近側街牆和道具僅在格鬥組裝場景隱藏以保護戰鬥可見性。外掛 toon、程序姿勢、2D 幾何特效、鏡頭及合成音。這些不是完成的手繪特效、正式角色動畫或最終音效。

34 項 headless 格鬥檢查、11 項 Xorg/llvmpipe 自動輸入與場景往返、28 遊走及 13 街景回歸通過。新格鬥測試無退出 ObjectDB 警告；街景回歸仍有既存音訊清理警告。截圖及自動示範見 `docs/evidence/combat/`，並非真人試玩或硬體效能證據。下一步先真人調校手感與正式動作／特效，再擴充格鬥深度。完整操作、架構與後續順序見 [COMBAT.md](COMBAT.md)。

## 使用者指定的街口仰角背景（2026-11-07）

依本聊天三張圖片改用沿街望入、向上仰視的構圖：雙側冷暖街牆、直立招牌、深藍天空和斜向四引擎客機。背景在獨立 SubViewport world 渲染，前景正交角色與原格鬥判定保留；相機追隨不改背景仰角，暫停會凍結飛機。頂部 HUD 收窄、臨時大牌和凸起舞台正面移除。原街景與 GLB 無改動。

已讀取使用者 Drive 影片並抽查六張等距畫面，未完整觀看或量測原遊戲幀數。14 項新背景檢查、34 格鬥與 11 自動輸入回歸通過，1280×720／960×540 的 Godot llvmpipe 畫面與自動示範見 `docs/evidence/street-angle/`。下一步是使用者確認構圖，再精修建築／客機與正式角色動作；目標 GPU 和真人手感未驗證。完整來源及參數見 [背景文件](STREET_COMBAT_BACKGROUND.md)。

## 五點試玩回饋修正（2026-11-07）

修正模型 +Z 朝向與 gameplay facing 的相反轉換，雙方現在面向彼此且能換邊。匯入 Quaternius CC0 Standard 的 14 段拳擊／移動／跳躍／翻滾／受擊／KO／發力動畫，使用休止姿態轉接和肢體校正；重踢與挑空另作方向疊加。來源、授權、雜湊與可重現抽取器均已保存，角色 GLB 無改動。

依使用者澄清，移除雙 world 合成，角色 Z=3 在現有斑馬線上戰鬥，使用同一個透視世界、陰影和相機；相機依雙方中點與距離平滑追蹤，左右輕微環繞。兩種模式的場景文字／舊字形均隱藏，招牌面板留白。

30 項新回歸、34 格鬥、11 自動鍵盤、28 遊走和 13 街景通過，共 116 項；新畫面與示範見 `docs/evidence/playtest-fixes/`。既存遊走音訊清理警告仍在；真人手感及目標硬體未驗收。詳細來源、轉接方式和剩餘限制見 [PLAYTEST_FIXES.md](PLAYTEST_FIXES.md)。接續優先看真人試玩對接觸節奏、腳步、鏡頭及素材整合的回饋。

## 場景接回、音訊與戰鬥演出（2026-11-07，最新）

已重新核對指定街景對話及來源分支 `f9cd82d`，補回前版漏載的圖片天空、紅車、箱式貨車、原世界 UV 環境貼圖和 style_sample 細節。取消全街 X=2.4 拉伸，只延伸入口斑馬線漆。飛機沿本地 -Z 機鼻飛行並移高避開屋頂。角色黑邊保留，場景額外描邊預設關，O 比較；招牌仍留白。

加入 Juhani Junkala CC0 電子樂、Kenney CC0 14 個音效，以及原創分段幾何 VFX。Shift 前六幀精準防禦及起手反擊已接入；F4 獨立音樂、M 靜音、F2 減少演出。四項使用者截圖警告已修正，三份相關腳本在提高警告為錯誤後通過。

163 項相關檢查及含聲腳本示範已完成，細節、來源和限制見 [本輪文件](SCENE_AUDIO_VFX.md)。來源 GLB／白盒及歷史證據保留。仍需真人調手感、實聽混音與目標硬體驗收；原獨立飛機測試的音訊退出警告按本輪日誌記錄，不宣稱全面排除。

## Web 分享試玩準備（2026-11-07）

已按使用者要求加入 Godot Web preset、分享入口、載入／失敗提示、全螢幕、複製連結及授權頁。桌面鍵盤單人對 AI，保留 F6 原街景。單執行緒 Compatibility，不要求跨來源隔離；動作 JSON 明確打包。Wasm 無損壓縮，總下載約 19 MB，Sites ID 與更新方法見 [WEB_PLAYTEST.md](WEB_PLAYTEST.md)。

Web 匯出、匯出包 8 項 Native 資源／玩法／F6 往返，以及 Wasm 編譯、Web Streams 解壓和檔案雜湊通過。Sites preview relay 及 cua_repl.js 不可用，瀏覽器實際遊玩未驗證；發佈結果另補紀錄，不把預期網址當作已上線。
