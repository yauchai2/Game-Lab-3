# 格鬥背景：街口低角度透視（歷史實作）

> 本文件記錄上一輪版本。使用者試玩後已選擇斑馬線、統一透視世界與輕微環繞鏡頭，並要求招牌留白。最新實作見 [PLAYTEST_FIXES.md](PLAYTEST_FIXES.md)。

## 使用者方向與來源（2026-11-07）

使用者在本聊天提供三張同構圖參考：街口客機照片、低多邊形版本、黑邊賽璐璐版本。採用左側冷藍／右側橙紅建築、向街道深處收束的透視、黃色直立招牌、深藍天空與斜向客機機腹。圖片作構圖與風格參考，背景由專案既有 3D 幾何重新組裝。

使用者另提供 [LLB 影片](https://drive.google.com/file/d/14umRoL39F5hDiDY7-REG6sa5Jqg3QGjD/view)。Drive metadata 確認檔名為 `Just_Gas vs Mauri985 Cyan League FT5  Lethal League Blaze - Just Gas (1080p, h264).mp4`，344,300,575 bytes；Drive connector 的 256 MiB 原始下載上限不足，因此改用同一檔案的公開原始下載成功讀取。ffprobe 確認 1920×1080、30 FPS、1088.654467 秒。

本輪抽看前約四分鐘的六張等距畫面（ffmpeg `fps=1/45,tile=3x2`，約 22.5、67.5、112.5、157.5、202.5、247.5 秒）；不是完整觀看 18 分鐘或逐幀量測。可見兩種紫藍／夕陽場景、頂部雙方狀態、底部音響介面、固定水平戰鬥區、白色命中環／尖刺、移動拖影及低對比背景。這些觀察支援前景辨識與畫面層次設計，沒有由靜態抽幀推斷精確頓幀數值。原始影片與抽幀只在本次分析的暫存目錄，未加入遊戲資產或 Git。

## 本輪實作

- `street_backdrop.gd` 建立獨立 `SubViewport` 和 3D world，載入原街道白盒、現有店面與招牌。背景相機位置 `(0,1.1,8)`，向上 27°，垂直 FOV 72°。
- 街道包裝 X 縮放 2.1，以 16:9 擴展兩側街牆間的天空缺口。來源場景和 GLB 無修改，這是構圖調整，並非照片的實測空間。
- 兩側建築都可見；保留街道縱深，加入原創「新隆街坊」招牌文字，深藍程序天空、白雲、兩階材質與深度描邊。
- 原程序四引擎客機保留，疊加已有輪組與綠色塗裝。在背景 world 以獨立座標及 0.9 縮放使用，參考定格位置 `(-2,31,-38)`、yaw −145°。
- 客機沿直線飛越 12 秒，接著隱藏等待；24 秒週期。暫停與結算凍結背景，凍結時只排一次更新。飛機不影響格鬥判定。
- 角色／判定繼續使用原正交格鬥平面與追鏡。透過 Canvas 背景合成，角色移動和鏡頭縮放不會改動背景仰角。
- 移除臨時橫向 Fight Club 大牌與凸起舞台正面，改成連續路面；保留起點和邊界遊戲標示。
- 頂部 HUD 高度由 120 降至 96 邏輯像素，保留生命、能量、防禦與計分，增加可見天空。
- 背景渲染寬度上限 1280，依畫幅維持比例。第二個 world 會增加渲染成本，尚未量測目標 GPU。

## 驗證與限制

- 新增 14 項背景檢查：world 分離、低角度透視、正交角色相機、雙側街牆、輸入隔離、追鏡不移動背景相機、直線等速航路、暫停、隱藏等待、固定截圖姿態、渲染尺寸上限及 Canvas 合成。
- 既有 34 項格鬥與 11 項自動 viewport 鍵盤／雙向場景切換回歸通過。
- Godot 4.6.3 Compatibility / Xorg dummy / Mesa llvmpipe：1280×720 和 960×540 的主選單、對峙、命中、挑空、暫停畫面已擷取並查看；不是目標硬體或真人試玩。
- 本輪沒有改格鬥模擬或原遊走場景。原始場景和 GLB 的 Git diff 為空。
- 現有程序建築、四引擎機體和角色動作仍有簡化，不能視為參考圖片逐像素還原或最終美術。

證據在 `docs/evidence/street-angle/`；歷史第一版畫面仍保留在 `docs/evidence/combat/`。新視角示範為 scripted、自動輸入、靜音。

```sh
godot --headless --path godot --audio-driver Dummy --script res://tools/verify_street_backdrop.gd
DISPLAY=:94 LIBGL_ALWAYS_SOFTWARE=1 godot --path godot --rendering-method gl_compatibility --resolution 1280x720 --audio-driver Dummy --script res://tools/capture_combat.gd -- res://../docs/evidence/street-angle
```
