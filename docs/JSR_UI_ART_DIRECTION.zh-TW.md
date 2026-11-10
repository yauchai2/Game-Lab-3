# Jet Set Radio UI 研究與 AFTERHOURS 素材方案

2026-11-09。目標是讓這款香港街鬥遊戲帶有 **2000 年《Jet Set Radio》的地下電台／街頭印刷品氣質**，同時保留對戰資訊的可讀性。本輪完成研究、圖片生成、透明素材與接入規格；**沒有替換現有遊戲介面，也沒有更新公開 Web**。

[圖片總覽](../references/ui-jsr-2026-11-09/README.md) · [整包下載](../references/ui-jsr-2026-11-09/afterhours-jsr-ui-v001.zip) · [來源紀錄](../references/ui-jsr-2026-11-09/sources.json) · [生成紀錄與提示詞](../references/ui-jsr-2026-11-09/generation-manifest.json)

## 研究結論

建議方向是 **「AFTERHOURS：港式地下電台」**：橙色／黃綠的大型品牌貼紙、深紫墨線、奶油白紙邊、少量網點，以及選單用的頻率游標。最大的個性放在 Logo、選單選取與結果演出；打鬥中收回成薄而清楚的儀表。

JSR 的辨識度並不是把所有地方塞滿塗鴉。官方遊戲截圖的 HUD 很克制：左上長條與分數、右上橙色時間、左下噴漆罐，中央留給角色。這正是目前遊戲需要補上的取捨：選單更有態度，交戰畫面更少厚重底板。

## 看過甚麼，沒有把甚麼當成事實

| 來源 | 實際檢視 | 可以支持的觀察 |
|---|---|---|
| [SEGA Steam 官方頁／媒體](https://store.steampowered.com/app/205950/Jet_Set_Radio/) | 2012 PC 移植版的第 0、3、6、10 張官方截圖；下載到的實圖為 1000×562 | 橙色時間、切角長條、冰藍分數字、粗深描邊、少量角落圖示；日／夜／橙天空舞台的 HUD 都維持可讀 |
| [Dreamcast 英文原版手冊掃描](https://www.gamesdatabase.org/Media/SYSTEM/Sega_Dreamcast/Manual/formated/Jet_Set_Radio_-_2000_-_Sega.pdf) | 18 頁 PDF 中的 1、3、4、5、6、7、8、12、13、14 頁；封面為西方版 Jet Grind Radio。原內容是 SEGA 手冊，由 GamesDatabase 託管 | 封面鋸齒字標與背面同心波紋；印刷頁 8–9 的 Garage／Street，10–11 的關卡／角色選擇，20–23 的文字／噴漆編輯，24–25 的 System／Radio |
| Google Fonts 官方字體授權檔 | Bungee、Barlow Condensed 的 OFL.txt 均成功讀取，來源及 SHA-256 保存 | 可以考慮作新的拉丁字體候選；本輪沒有下載或接入字體檔 |

Sega Retro 回傳驗證頁、Game UI Database 為 403、Spriters Resource 導到零素材的 PC 頁，**沒有把它們當成已看過的圖庫**。完整手冊是掃描圖，文字抽取沒有內容，實際以圖片閱讀。原作手冊／截圖未放進交付素材包。

本輪不是原版逐像素復刻、JSRF 研究或動畫逐幀量測。以下 RGB、角度、尺寸與毫秒都是**本專案提案**；原作確切字體檔未核實，不能把網路上的「JSR font」直接當官方字體。

## 把原作語言拆成可用規則

| 視覺層 | 來源中的線索 | AFTERHOURS 的轉譯 |
|---|---|---|
| 字標 | 鋸齒外輪廓、誇張字寬、層層色邊；手冊亦展示 Shape／Size／Rotate／Lens 等文字編輯 | 原創 AFTERHOURS 字標作靜態品牌圖；一般標籤與數字仍用真正字體 |
| 色彩 | 鮮亮主色與深色輪廓，而不是寫實金屬或半透明玻璃 | 橙／黃綠負責品牌與選取；深紫承托文字；青／珊瑚仍區分兩方 |
| 幾何 | 長條切角、尖端、簡短爆炸字框 | 按鈕、血條尾端及連段貼紙有一致斜切；不把所有面板都做成大爆炸 |
| 印刷感 | 粗描邊、層疊圖形、網點與紙張式構圖 | 實色硬偏移邊＋局部網點；小字區不加噪點，避免髒與糊 |
| 導覽 | Garage 有 Street／Graffiti／System／Radio／Internet 等入口，System 用清楚標題 | 本作保留真實功能：對戰、角色、練習、設定，另有 Demo／說明／探索；不照抄不存在的功能 |
| 電台主題 | 故事與 Radio 功能、封面背面的同心波紋 | 頻率游標與裁切圓盤成為原創選取符號；不是宣稱原版選單就是這個大轉盤 |
| 對戰資訊 | 原作 Stamina／Score／Time／Spray Cans 的層級清楚 | 改成兩方 HP、連段、75 秒／Demo 的 ∞、能量；不把噴漆罐數字硬搬成我們的規則 |

避免走成通用霓虹電競、賽博龐克玻璃面板、全紅黑漫畫頁，或每個中文標籤都扭曲的塗鴉牆。街景招牌仍保持目前留白規則，這套圖只處理 UI。

## 已生成的交付內容

| 檔案 | 用途 | 狀態 |
|---|---|---|
| [主選單方向圖](../references/ui-jsr-2026-11-09/generated/01-main-menu-direction.png) | 品牌、貼紙選單、電台游標、香港街景的關係 | 概念合成圖，非引擎已實作畫面 |
| [精簡 HUD 方向圖](../references/ui-jsr-2026-11-09/generated/02-hud-direction.png) | 縮小頭像圓章、薄血條／能量條、時間圓盤與小型連段貼紙 | 建議採用的 HUD 方向；大尺寸初稿另存 explorations |
| [四角色選擇方向圖](../references/ui-jsr-2026-11-09/generated/03-roster-direction.png) | ORIGINAL／1／3／4 卡片與 P1／P2 選取 | 卡片參照本作四個模型；右側 Hero 為概念插畫，有髮型／服裝簡化，不取代角色模型設定 |
| [AFTERHOURS Logo](../references/ui-jsr-2026-11-09/assets/afterhours-logo.png) | 可覆在場景上的品牌貼紙 | RGBA PNG，2146×733，主體四邊至少 6% 留白 |
| [8 款框架圖集](../references/ui-jsr-2026-11-09/assets/ui-frames.png) | normal／selected／hover／disabled 按鈕、血框、能量裝飾框、圓盤、連段框 | RGBA PNG，1536×1024；血框與圓盤中心真的透明 |
| [16 圖示圖集](../references/ui-jsr-2026-11-09/assets/action-icons.png) | 拳、挑空、暴扣、重砲、格擋、反擊、衝刺、投技、耳機、電台、Demo、角色、音樂、音效、暫停、返回 | RGBA PNG，1261×1247；附四乘四切片座標 |

共生成九張稿件，整理成六張主要交付 PNG；三張早期稿留在 explorations 供追溯。動態字、HP、能量、時間、連段數字**不烘焙進可用素材**。概念畫面上的英文只為展示，正式繁中／英文標籤應由 `ui_text.gd` 排版。

## 色盤與字體

提案色票在 [proposal-tokens.json](../references/ui-jsr-2026-11-09/proposal-tokens.json)，尚未改動 `ui_theme.gd` 的現行色票。PNG 的細微色差不等於精確 Token 值。

| 色票 | 提案值 | 用法 |
|---|---|---|
| Ink | `#20102F` | 描邊、文字、需要承托內容的深底 |
| Orange | `#FF6A00` | 品牌、確認、硬偏移邊 |
| Lime | `#D7F400` | 選取、頻率游標、短促正回饋 |
| Paper | `#FFF1D0` | 文字標籤底、字標外緣 |
| Player cyan | `#4ACFE0` | 玩家 HP／識別 |
| Rival coral | `#FF765E` | 對手 HP／識別 |

Ink 對 Paper／Orange／Lime 的提案對比約 **15.93／6.22／14.30:1**。Paper 字直接放 Orange 只有 **2.56:1**，不採作一般小字配搭；橙按鈕使用 Ink 字。[計算紀錄](evidence/ui-jsr/contrast.json)只驗證這些精確色票，不冒稱生成圖的每個像素或整款遊戲已通過無障礙驗收。

- 品牌：本輪原創字標 PNG，只是 AFTERHOURS 的字形，不是一整套字體。
- 拉丁短標題：可考慮 Bungee 或 Barlow Condensed ExtraBold；保留現有 DejaVu Condensed Bold 作數字／替代。
- 繁中與說明：沿用現有 OFL Noto Sans CJK HK 衍生字體；中文不強制斜體或拉寬。底板可以斜，文字保持清楚。
- 720p 提案：主要按鈕 22–28px、說明 17–18px、HP 16–18px、時間 40–44px、連段 40–52px。不要以低解析字圖模擬復古，場景的像素貼圖規則不等於 UI 字體也要糊。

## 畫面規格與狀態

**主選單：**左側字標與四個主要入口構成貼紙堆；右側保留真實街景／角色。選取只改游標、色與很小的圖形位移，控制項矩形不改，避免鍵盤焦點或點按位置跳動。Demo／說明／探索是次級入口；現有三種練習仍須可到達，若整理到練習頁要明確接回原 handler。

**戰鬥：**以 1280×720 邏輯畫布為基準，普通 HUD 上方約 96px，底部提示不超過 32px；中央 `Rect(240,112,800,480)` 不放常駐厚面板。P1／P2、HP、能量與時間都是真資料。能量 50／75 的標記由程式按比例畫；圖集中的 energy ornament 隔線只是裝飾，**不能直接當成 50／75 刻度**。Demo 顯示 ∞ 及重開／退出，不能冒充正常回合倒數。

**角色：**卡片以現有模型的 SubViewport／原生預覽為優先，維持角色 4 的縮高。ORIGINAL／1／3／4 與目前檔案身份一致；不憑生成圖加上角色專屬能力、鎖定條件或貨幣。P1／P2 選擇仍呼叫 `set_character` 並保存。

**暫停／設定／說明：**可用同一邊框語言，內文比主選單安靜；保留捲動、音量控制、持久化、Esc 與返回焦點。不要把設定頁每一行都做成旋轉貼紙。

**結果／強演出：**真正 KO 才顯示 KO；重砲／BREAK 繼承目前優先次序。強演出可短暫穿過中央，常駐 HUD 不可。連段數與 MAX OUT 切入不能同時擠在同一角落，需避讓或短暫隱藏次級貼紙。

| 狀態 | 外觀與行為 |
|---|---|
| Normal | Paper 底、Ink 字，原生按鈕可聚焦 |
| Hover | Orange 底，幾何與點按範圍保持 |
| Keyboard focus | 清楚外框＋游標，不依賴 hover |
| Selected | Lime＋頻率游標，和 focus 分開 |
| Pressed | 小幅內縮／硬偏移邊收回；同一原生控制項提交 |
| Disabled | 灰紫底、可讀標籤與原因，不觸發操作 |

## 動態提案

選單進場約 180ms、條目錯開 45ms、焦點切換 80ms、按壓復原 120ms。這是本作提案，不是量測原作。圓盤游標只在選項改變時移動，不持續亂轉；不要用假頻率、假音量數字裝飾。若要音訊反應圖，必須接實際音訊資料，否則維持靜態圖形。

F2 應移除位移／旋轉與強閃爍，仍保留立即的選取／焦點回饋。UI 導覽使用獨立介面時鐘，不被戰鬥慢鏡拖慢；暫停仍凍結戰鬥。

## Godot 接入方式

1. 本輪檔案目前放在 references，未被遊戲入口引用。接入時才複製採用的三張透明素材到 `godot/assets/ui/`；不要把完整主選單或 HUD 概念圖當一張可點按底圖。
2. 使用 [atlas-regions.json](../references/ui-jsr-2026-11-09/atlas-regions.json) 的像素區域建立 `AtlasTexture`。圖示原圖不是整除 4 的尺寸，座標已按實際 1261×1247 計算，不要假設每格都是 256。
3. PNG 保持原檔；UI 建議 lossless、clamp、關閉 mipmap、linear 過濾並開 alpha border fix。字體仍用原生 FontFile。原始 alpha-zero 像素可保留有色 RGB，不能只看 RGB 預覽判斷是否透明。
4. 填色／文字／焦點由程式與原生 Button／OptionButton 擁有。框架作裝飾層，`mouse_filter=IGNORE`；不要用圖片冒充已能操作的按鈕。斜邊優先保固定高度與端點，不粗暴拉伸整張圖來表示血量。
5. 現有擁有者保持：`ui_theme.gd` 統一 Tokens／Theme、`fight_hud.gd` 統一布局、`ui_text.gd` 統一繁中／英文，`fight_session.gd` 保留操作入口。採用色盤時再同步 DESIGN.md 和 runtime，不在本輪建立第二份現行主題。
6. 依次接主選單、普通 HUD、角色頁，再接暫停／設定／結果；測 960×540／1280×720／1920×1080、兩語言、鍵盤／滑鼠、焦點／停用／開啟下拉、F2／暫停／重開／退出。

## 本輪驗證與交付界線

[45/45 素材檢查](evidence/ui-jsr/asset-inspection.json)：RGBA 解碼、真正透明角落、可見內容、Logo 留白、8 框架區域及 16 圖示非空、血框／圓盤中心透明。另在 Godot Compatibility／軟體 GL 實際合成：[框架](evidence/ui-jsr/ui-frames-alpha-preview.png)、[圖示](evidence/ui-jsr/action-icons-alpha-preview.png)、[Logo](evidence/ui-jsr/afterhours-logo-alpha-preview.png)，已檢視而非只讀檔頭。

Frontend Design Premium 的 strict 靜態稽核 0 errors／warnings；其掃描主要辨識 Web 語法，這不是原生 Godot 可用性或無障礙證明。首張合成預覽因邏輯畫布大小被裁切，已修正預覽工具按 viewport 等比縮放，完整版本如上，首稿保留 first-preview。

本輪沒有更換 runtime 色票、UI、角色、音訊或戰鬥規則，沒有跑不相關的整套戰鬥回歸，也不宣稱生成圖已成為遊戲實機。素材仍需接入時的小尺寸檢視／正式互動驗證；目前可以直接取得 PNG、圖集座標、提示詞及來源紀錄。
