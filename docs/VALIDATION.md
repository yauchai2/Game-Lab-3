# 驗證紀錄與證據範圍

## 六件原型資產

| 資產 ID | 三角面 | 貼圖 | 使用尺度 |
|---|---:|---|---|
| PROP_HYDRANT_A01 | 1,477 | 512×512 | 高 0.9 m |
| PROP_BIN_A01 | 1,456 | 512×512 | 高 1.0 m |
| VEH_VAN_A01 | 1,582 | 1024×1024 | 長 4.2 m，等比縮放 |
| PROP_SHOP_STOOL_A01 | 1,513 | 512×512 | 高 0.45 m |
| PROP_CRATES_A01 | 1,491 | 512×512 | 整組高 0.8 m |
| PROP_MAILBOX_A01 | 1,440 | 512×512 | 高 1.1 m |

合計 8,959 三角面，每件一個材質。這是幾何計數，不是效能測量。精確來源雜湊、模型和包裝場景位置見 [assets-manifest.json](../assets-manifest.json)。

## 已執行

- 靜態讀取 GLB JSON／buffer，讀取面數、包圍盒、內嵌貼圖尺寸及 SHA-256。
- Blender 4.3.2 讀取並使用 Cycles CPU 渲染四角度；repo 的 evidence/ 保留六件斜角預覽。來源工作區的其他角度及 .blend 尚未全部納入 repo。
- Godot 4.6.3 完成無視窗匯入，載入各資產包裝場景及總展示場景，核對面數與碰撞節點。原聊天工作區紀錄見 [six-assets-godot-verification.log](evidence/six-assets-godot-verification.log)。
- 首次 repo 同步時重新驗證每份 GLB 與來源 SHA-256 一致。

## 重現命令

從 repo 根目錄執行：

```sh
godot --headless --editor --path godot --import --quit
godot --headless --path godot --script res://verify.gd
```

`verify.gd` 檢查六件資產的三角面、至少一個 CollisionShape3D，以及總展示場景能載入。腳本不是渲染測試，也不是玩家碰撞測試。

## 尚未驗證

- Godot GPU 實際畫面、目標硬體效能與輸出包。
- 遊走控制器的人工手感、更多相機角落、真實桌面輸入與飛機事件的人工視聽（自動檢查另見下方）。
- 最終 toon 材質及與參考照片／影片的畫面一致性。
- 全資產封閉拓樸。消防栓的診斷有開放邊，原型使用獨立簡化碰撞，未將來源網格強行修補。

所有資產目前僅接受為靜態街景原型，不標記為最終遊戲美術完成。

## 任務分支重新驗證

將資料搬入本 repo 後，在 Godot 4.6.3 重新執行兩個重現命令，均成功。另核對六件來源雜湊、模型／場景／參考圖路徑，以及非歷史文件的 Markdown 連結。結果：

- [匯入紀錄](evidence/repository-import.log)
- [六件載入核對](evidence/repository-verification.log)
- [來源完整性與文件檢查](evidence/repository-integrity.json)

以上仍不包含 GPU 畫面、實際遊玩或效能驗證。

## S1 街道白盒

已生成街道場景，完成五個相機切換與方向檢查、64 m／8 m 基準尺寸、四個引擎與開口、六件來源道具、251 個 mesh 節點及八個地面射線取樣檢查。原始六件 GLB 的 SHA-256 維持一致。主場景無視窗啟動通過。

- [白盒生成紀錄](evidence/whitebox/build.log)
- [檢查紀錄](evidence/whitebox/verification.log) 與 [結構化結果](evidence/whitebox/verification.json)
- [啟動紀錄](evidence/whitebox/startup.log)
- [來源資產回歸檢查](evidence/whitebox/source-assets-verification.log)
- [五張預覽及重現步驟](WHITEBOX.md)

預覽為 Godot 幾何快照的 Blender Cycles CPU 渲染，光照另設；不代表 Godot GPU 畫面驗證。S1 沒有玩家控制器，八個射線取樣不能代替玩家碰撞與整條路的人工遊玩。

## S2 遊走物理／邏輯檢查

Godot 4.6.3 headless，60 Hz 模擬，28 項檢查通過。包含實際角色移動、斜向速度、跳躍落地、人行道跳躍、超過 50 m 的連續主街通行、側巷、建築／廂型車／郵箱阻擋、牆邊相機臂縮短，以及相機模式、游標請求、重設及掉落回復。完整測量見 [verification.json](evidence/walk/verification.json) 及 [verification.log](evidence/walk/verification.log)。重現方式及未驗證範圍見 [WALK.md](WALK.md)。

本次測試注入應用程式輸入並跨 Godot 物理幀執行，不是人工操作。headless 不支援真實桌面游標鎖定，僅核對鎖定請求及輸入邏輯；GPU、手感和硬體效能仍待驗證。

## S3 風格樣片

Godot 4.6.3 Compatibility 透過 Xorg dummy／Mesa llvmpipe 軟體 OpenGL 4.5 實際擷取同鏡頭畫面；這不是硬體 GPU 效能測試。12 項樣片材質／切換檢查、S2 28 項遊走回歸與六件原始 GLB 雜湊檢查通過。投影開關及兩／三段畫面像素比較見 [STYLE_SAMPLE.md](STYLE_SAMPLE.md) 與其 evidence/style 紀錄。

最終風格、人為遊走感受、實體 GPU／效能及字型跨平台仍待驗收。

## S4 飛機事件與樣片調整

11 項 headless 事件檢查、28 項遊走回歸、12 項風格回歸與六件 GLB 載入／SHA-256 均通過。事件測試在退出時仍有 ObjectDB 清理警告。Godot Compatibility、Mesa llvmpipe 固定入口鏡頭擷取三個事件凍結位置；並非硬體 GPU、動態實機或音訊實聽測試。操作、證據與限制見 [FLYBY.md](FLYBY.md)。舊 S3 圖片是調整前的歷史快照。

## GitHub Desktop 指引與天空參考

本次為操作／交接文件更新；已核對目標分支及現有專案路徑。沒有實際操作使用者的 GitHub Desktop 或 Godot，也沒有將聊天中的天空圖檔匯入專案。前述 S4 測試結果為此前執行，不能視為本機使用者驗收。

## 程序天空樣片

Godot 4.6.3 headless 的 7 項天空及切換檢查通過，另重跑風格 12、遊走 28、飛機 11 項回歸通過；飛機測試仍有退出 ObjectDB 清理警告。Godot Compatibility／Mesa llvmpipe 已擷取入口比較與其他方向的靜態畫面。完整 360° 接縫、目標硬體與人工驗收尚未驗證，詳見 [SKY_SAMPLE.zh-TW.md](SKY_SAMPLE.zh-TW.md) 及 evidence/sky。

## 天空環視與接縫局部檢查

Godot Compatibility／llvmpipe：在高空隔離天空，擷取八個方向及接縫兩側；0°／360° 與 ±180° 精確相同，±179.75° 的中央區域按 5 像素對齊後約 0.21% 像素不同（未對齊約 1.66%），測試區域包含雲。天空 7 項 headless 回歸通過。這不涵蓋所有俯仰角、目標 GPU 或人工操作；檢查方法、原始圖和侷限見 [天空文件](SKY_SAMPLE.zh-TW.md)。

## 轎車候選參考圖

AI 依既有三視圖拼版製作單輛斜角參考圖，圖片已保存，尚未用 Tripo 生成或驗證任何轎車 GLB。本次未更改 Godot 程式、模型或遊玩結果；生成設定為建議，不能作為實際模型品質或成本的證據。

## 使用者上傳轎車與場景整合

原始 GLB 223,928 bytes、1,524 三角面、1,220 頂點、單材質、1024×1024 JPEG，來源與 repo SHA-256 一致。縮放後長 4.2 m；靜態盒碰撞與 B 材質切換另行包裝，原白盒保留。[六項 headless 場景檢查](evidence/car/verification.json)、28 項遊走、12 項風格、11 項飛機及七件資產載入檢查通過；場景測試與飛機測試退出有 ObjectDB 音訊清理警告。Godot Compatibility／llvmpipe 擷取[正面](evidence/car/01_front_street.png)與[背面](evidence/car/02_back_street.png)，車體陰影較暗；不是硬體效能或人工試玩驗證。工具 `game-dev` CLI 未安裝，未產生其 canonical package，也未以 Blender 正規化來源。

## 圖片天空及使用者貨車

貨車原始 GLB 282,288 bytes、1,510 三角面、1,490 頂點、1K 貼圖，來源與 repo SHA-256 一致；5.5 m 靜態包裝、碰撞和風格比較均通過，新增的 [11 項檢查](evidence/truck-sky/verification.json)及既有遊走／風格／天空／飛機／轎車、八件資產載入回歸通過。部分 headless 測試退出有 ObjectDB 音訊清理警告。[Godot 軟體渲染截圖](evidence/truck-sky/03_truck_front.png)顯示貨箱背面無明顯門件。

新生成天空圖 1774×887，原圖邊緣平均通道差約 0.72／255、最大差 6／255；llvmpipe 指定相機的 0°／360° 一致、±180° 相差 109 像素。詳細範圍與[圖片／程序比較](SKY_SAMPLE.zh-TW.md)有記錄；非完整接縫保證、硬體效能或人工試玩。
