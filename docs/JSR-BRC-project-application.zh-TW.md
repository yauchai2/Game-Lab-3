# JSR／BRC 規範與目前場景對照

使用者原始附件 [jsr_brc_3d.md](../references/guidelines/jsr_brc_3d.md)；另一對話提交到 main 的[整理版](JSR-BRC-style-reference.md)原樣納入本任務分支。兩者是美術製作目標；文件對原作面數與實作的描述未獨立查證。

## 已有與這次調整

- 角色原檔 1,664 三角面，在文件提出的 1,500–3,500 目標內；有骨架但沒有動畫。未檢查所有法線是否符合 30–45° 或臉部法線目標。
- 三種 128×128 環境貼圖按世界座標投射：道路與牆 32 texels/m，人行道 64 texels/m。部分立面使用兩階／三階卡通材質及冷色陰影；並非整條街所有材質均已轉成同一 Shader。
- 道路等標準材質已有 nearest+mipmaps；這次令套用卡通 Shader 的世界投射立面使用同一過濾方式。角色與道具仍用原本的線性 UV 取樣，原始 GLB 不修改。保留 mipmaps 是目前的防閃爍取捨，並非宣稱已符合規範的關閉／負 bias 選項；需在移動中比較。
- 圖片天空及側巷塗鴉為不受場景光照影響的視覺元素。現有 O 為可選螢幕描邊；尚無角色 inverted-hull、平滑法線通道或相應骨架驗證。

## 接下來的可驗收項目

1. 移動中對比不同 mipmaps／filter（遠近、斜角、招牌及角色附近），記錄畫面閃爍及目標硬體效能，再選預設。
2. 建一個可逆近景角色描邊測試，確認骨架動作、斷法線、鏡頭距離、臉部與頭髮沒有裂縫；再決定法線資料通道，避免與頂點色光照衝突。
3. 逐件檢查模型的剪影、材質與單面剔除，來源 GLB 有雙面材質或開口時先修衍生副本再驗證，避免一鍵更改造成破洞。
4. 以小段路面對照硬陰影與冷色，保留可讀性，再按玩法測試動作抽幀及圖形化特效。

## 驗證與取捨

- [線性](evidence/style-reference/01_linear.png)及[最近鄰](evidence/style-reference/02_nearest.png)為同鏡頭固定截圖，只改卡通世界貼圖的過濾。Godot Compatibility／llvmpipe、1280×720；[像素統計](evidence/style-reference/pixel-difference.json)記錄畫面差異，不代表比較完成或喜好判定。
- [11 項取樣驗證](evidence/style-reference/verification.json)與[既有風格回歸](evidence/style-reference/style-regression.json)通過。未測目標 GPU、真人操作、移動閃爍、整場景法線、效能或其他範圍。

## 2026-11-07 修正

上次雖然設定 nearest+mipmaps，但三張環境貼圖的 Godot 匯入設定實際為 `mipmaps/generate=false`，因此先前「保留 mipmaps」的說法不準確。現已開啟產生，三張 128×128 貼圖各確認含 7 層 mipmap（不含原圖），見 [驗證紀錄](evidence/mipmaps/verification.log)。先前固定鏡頭圖像屬修正前的歷史記錄；移動閃爍及 GPU 尚未驗證。
