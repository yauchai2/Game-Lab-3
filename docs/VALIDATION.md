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
- 遊走控制器、相機、碰撞手感與飛機事件。
- 最終 toon 材質及與參考照片／影片的畫面一致性。
- 全資產封閉拓樸。消防栓的診斷有開放邊，原型使用獨立簡化碰撞，未將來源網格強行修補。

所有資產目前僅接受為靜態街景原型，不標記為最終遊戲美術完成。

## 任務分支重新驗證

將資料搬入本 repo 後，在 Godot 4.6.3 重新執行兩個重現命令，均成功。另核對六件來源雜湊、模型／場景／參考圖路徑，以及非歷史文件的 Markdown 連結。結果：

- [匯入紀錄](evidence/repository-import.log)
- [六件載入核對](evidence/repository-verification.log)
- [來源完整性與文件檢查](evidence/repository-integrity.json)

以上仍不包含 GPU 畫面、實際遊玩或效能驗證。
