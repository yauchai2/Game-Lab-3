# 地面動作覆核：急停、前後步、閃避與受阻步態

2026-11-16，基線5ba39a4。[全遊戲覆核表](WHOLE_GAME_MOTION_REVIEW.zh-TW.md)的地面移動切片；不是整張覆核表全部完成。

## 發現及修正

正式角色的`vx`可在場邊被夾住、或被另一個身體阻擋時保持非零，但角色的`x`已沒有移動。舊renderer仍以這個要求速度選行跑clip，造成原地跑。四角7種情境的相同指令trace共找到324個這類停住抽樣，全部仍在行跑clip。

修正放在`motion_interpolation.gd`的展示副本：地面idle狀態沿同一角色、同一已提交tick的實際位移，取「確實朝要求方向移動」的部分，且不超過原要求速度。撞住便站穩，部分前進便降步速；被人推動不會憑空變成自己行路。

- 不寫simulation的速度、位置、面向、命中、傷害或碰撞。原生前後兩份完整trace的權威位置／速度／狀態逐列相同；展示前後的simulation JSON亦保持不變。
- 攻擊、一次性dash、空中、死亡、傳送及角色替換保持原動作入口。
- hitstop／高壓對峙／蓄壓對峙／空反hold保留凍結時的步態，不因零位移突然跳回idle。
- F2仍停用位置插值，但保留同一受阻步態修正；演出、選角、NPC的既有作者速度未套這個正式交戰濾波。
- 原模型、來源動作、retarget及地面IK保持。沒有把角色root拉走來掩蓋腳滑。

修後同一324個抽樣的行跑clip數變為0，F2同為0。此數字證明選片跟真位移一致，不等於所有鞋底接觸／美術姿勢已完美。

## 原生範圍與畫面

四個原rig各檢查前進、急停、前進轉後退、右場邊受阻、身體受阻、前閃、後閃，共28個固定情境。每組有骨架有限值、原生clip／相位、權威位移與展示純讀取資料；另有hitstop保持檢查。修前／修後／F2各33項場景檢查通過，專門規則21項與3項前後比較通過。

[修前6秒片](evidence/ground-motion-review/before.mp4)／[修後6秒片](evidence/ground-motion-review/after.mp4)使用完全相同的四角、普通移動指令、診斷地面／燈光／鏡頭，每角90模擬tick，30fps共180格。這個簡化地面是為看清腳與場邊，不冒稱正式街道鏡頭；原生完整街景抽格亦保留。影片不是硬件實時FPS量測。

已查看四角受阻姿勢對照、急停／後退／閃避的原生抽格與短片，選片回到護架／idle，未見這組樣本出現有限值錯誤或simulation被展示寫入。仍待更多相位、地形、鏡頭、真人觀察，尤其對手換邊的180°面向轉身、選角／勝利、敵人／Boss、工房NPC及遠景路人。不把前後步轉換當全部轉身動畫精修。

## 回歸及證據邊界

[規則、完整trace、原生抽格、短片及SHA256](evidence/ground-motion-review/README.md)。連續動作79、Transit216、Street90通過；既有1800tick展示／規則雙路replay零差異、零展示修改。23個戰鬥腳本七類fatal warning通過。

專案沒有`.game-dev/adapter.json`，環境沒有`game-dev`CLI，沒有自行安裝adapter。本輪依Game Visual Debugging的受控對照原則，用遊戲既有Godot擷取與telemetry；不是該工具的sealed run，也沒有depth／normal／object-ID或硬件效能附件。修前原生audit退出的ObjectDB非致命警告保留；後續runner等待清理，接受結果沒有engine／script錯誤。

Linux Godot4.6.3 Compatibility／Mesa llvmpipe／Dummy；非Mac、實體輸入、真人樂趣或硬件效能驗收。來源同分支PR #38，未合main或發Web。
