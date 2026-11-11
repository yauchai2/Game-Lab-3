# THE DEALER：使用者Tripo模型已接入

2026-11-11，承接使用者先前「提供蒙面NPC／抽獎機GLB後更新並加入動畫」的要求，實際載入本次兩份上傳檔；原始GLB及embedded貼圖原樣保存。沒有新增可選戰鬥角色或替換原四角。

## 檔案識別與保存

| 來源檔尾碼 | 內容 | 檢查結果 |
| --- | --- | --- |
| `36d4f0c3-b64c-4ea1-841e-104fd70e96ae` | 蒙面NPC | 1個skinned mesh、1164 tris、923個頂點、65根Mixamo命名骨骼；沒有來源動畫片段。 |
| `275dc57f-e328-47e0-89e5-10195d3209c4` | 抽獎機機身 | 1個靜態mesh、1066 tris、1627個頂點；無skin／動畫。 |

原檔在`godot/assets/ability_draw/source/`，[來源hash與metadata](../references/ability-draw/tripo/uploaded-models.json)及assets-manifest.json已記錄。`tools/inspect_ability_glbs.py`可重建metadata，不修改模型。原始物件近1單位高，以包裝節點統一縮放NPC約3.05／機殼2.0，再對齊現有演出尺寸；不把該數字視為使用者真實公尺比例。

## NPC骨骼動畫

`dealer_rig.gd`載入真正上傳的NPC及原skin，沿用已錄用的CC0 Quaternius動畫庫作rest-relative步行重定向；不是重新用程序幾何假扮人物。步態時間按實際拖行路程，左右進場轉向相應調整。停機後轉回面向鏡頭，拖行前傾、煞停、抬手拍機、展示代幣、轉輪時等待與爆獎後仰都由同一作者時鐘控制。

手臂使用二骨世界座標解算：拖行手腕對齊機殼新增握點、拍擊手腕對齊機頂；手掌朝向與手指彎曲另調。代幣跟隨原skin真正的左手腕，不使用懸空的替代手掌。頭部有小幅傾斜，保持不見玩家的原規則。

這些動畫在Godot wrapper中即時計算，**沒有將動畫烘焙回來源GLB**。此輪沒有做mocap、完整足底IK、cloth simulation或獨立可下載的動畫GLB。

## 機身及活動件

以本次機身替換原程序橙色機殼，保留原貼圖的磨損、冠形塗鴉、喇叭與外形。薄黑邊／二階cel材料在衍生包裝覆蓋，不覆寫來源材質。

來源機身沒有輪盤、輪子及拉桿，另加三個獨立真圓柱輪盤、四輪、拉桿pivot／握把及出貨蓋；機殼作靜態殼放在既有chassis上，拖行及拍擊回彈與既有聲畫時間線共用。來源凹槽深度比舊程序機器淺，已量測頂點並調小輪盤、後移至凹槽及重設輪盤近鏡，避免輪盤凸出機頂／遮住三燈。

保留現有真隨機結果與精準鎖停、一次領取、下一局modifier、FIGHT 1:1／Street Run第二站／Demo、暫停／跳過／F2及清理。裝備到玩家腰側的1.8秒動畫仍是之前的分鏡規劃，**本次沒有自行把它算作已實作**。

## 驗證與可看範圍

[原檔正面](evidence/ability-draw/tripo-models/source-models-front.png)／[斜側面](evidence/ability-draw/tripo-models/source-models-angle.png)是直接載入兩個原GLB的引擎畫面。正式過場見[evidence](evidence/ability-draw/tripo-models/README.md)。

新增原生模型檢查：原檔已可見、65骨與手指／腿鏈可用、真步態重定向、原貼圖保留、獨立機構、各階段有限骨骼姿態、手腕對準接觸點、代幣跟手、暫停及清理。原52項抽獎流程與入口檢查同樣對新模型重跑；最終結果及log在證據目錄。

有聲預覽為明示1:1回合邊界fixture的實際Godot渲染，非自然完整match；BGM僅於錄像靜音以聽清SFX。Godot4.6.3 Linux Compatibility／llvmpipe／Dummy audio，640×360固定步長再nearest放大；不等同使用者Mac實測、真人混音／平衡或目標GPU效能。程序骨骼動作仍需真人驗收，衣袖／手指細節與參考影片不完全相同。公開Web未更新。

最終模型22項＋完整流程52項，共74項通過且退出乾淨。機身來源其實以多層面封住黑色窗口，已在包裝材質與outline用來源局部座標開窗，再讓真圓柱輪盤在後方轉動；不是修改來源網格或把輪盤畫在殼上。短入場／抽獎音效改用原創OGG的PCM解碼副本，避免已重現的快速重開Ogg playback退出滯留；原OGG及長BGM保持。`tools/build_ability_pcm.py`與pcm-cues.json記錄轉換，原資產builder亦會同步重建PCM。
