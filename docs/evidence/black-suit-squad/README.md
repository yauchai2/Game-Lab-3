# 群戰與模型修補驗證

2026-11-11。Godot4.6.3 Linux Compatibility／Mesa llvmpipe／Dummy audio。

## 畫面

- [群戰開始](squad-start.png)：Normal四名黑衣人同場，全部有獨立血條。
- [群戰動作](squad-action.png)、[結算](squad-result.png)：正常命中／空戰與全隊勝負。
- [原版正面](repair-before-front.png)／[修補正面](repair-after-front.png)：領帶與下顎接合。
- [原版側面](repair-before-profile.png)／[修補側面](repair-after-profile.png)：後頸連接與黑縫。
- [原版後頸](repair-before-rear.png)／[修補後頸](repair-after-rear.png)。

近鏡為同樣燈光／鏡位的未播放動作模型；修補前使用原GLB及舊輪廓，修補後用衍生GLB及局部輪廓修正。群戰畫面才是有simulation的實際遊戲。不得把近鏡當真人遊玩驗收。

## 檢查

| 類別 | 通過 |
|---|---:|
| [群戰規則](rules.json)：三階數量／血量／攻擊協調、多目標真命中、間距與勝負 | 35 |
| [原生群戰](native.json)：真指標入口、骨架、暫停／重開／模式退出 | 9 |
| [修補版單敵](single-enemy/native-checks.json)：選角、動畫、真傷害／招架、偏好與重用演出 | 32 |
| [四角色資源](hero-rules.json) | 46 |
| [正式戰鬥](live-combat.json) | 45 |
| [二段跳／防禦](headless-regressions/summary.json) | 87 |
| [原生UI／材質](native-regressions/summary.json) | 43 |
| **合計** | **297** |

`rules.log`、`native.log`、`single-enemy/native.log`、`repair-capture.log`及回歸log保留輸出；最終無ERROR／SCRIPT ERROR。`repair-build.log`含Blender環境快取目錄唯讀提示，不影響衍生GLB匯出。VSync警告是llvmpipe環境限制。

自動群戰樣本不是真人操作／平衡評估；普通攻擊範圍／死亡／計時等部分測試使用明示fixture。沒有改AI血量來製作自由對戰成功的假錄像。原始模型hash及封閉補片驗證見 [模型報告](../../../references/characters/black-suit/repair-validation.json)。
