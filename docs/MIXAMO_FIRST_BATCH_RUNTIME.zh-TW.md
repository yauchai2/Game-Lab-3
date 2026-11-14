# 第一批 Mixamo 動作與 Walking（2026-11-14）

本輪已處理使用者提供的 21 FBX＋Walking.glb，將可用的地面出招、受擊、防禦、後閃與慢行接入正式 presentation。肩摔沿用已完成的共同時鐘版本。[來源 metadata](evidence/mixamo-first-batch/sources.json)、[裁切／接觸點](evidence/mixamo-first-batch/clips.json)、[骨架診斷](evidence/mixamo-first-batch/README.md)。這不是全套 49 候選都已替換。

## 已接入

|角色／狀態|實際來源與用途|
|---|---|
|ZIP jab／cross|Roundhouse Kick 左右版本，來源第31個30Hz樣本為接觸點|
|ZIP heavy／finisher|Hurricane Kick 單一循環＋明示6樣本入式／10樣本回收，左右版本；不將整段多踢當一擊|
|RIVET jab／cross|Jab Cross 拆成前手刺拳、後手直拳；各自獨立對齊判定|
|RIVET heavy／finisher|Boxing 低位身擊／Hook 前手勾拳，保留全身重心轉移|
|HUSH jab／cross|Jab To Elbow Punch 拆成刺拳／後段肘擊|
|HUSH heavy／finisher|Illegal Elbow Punch，以 RightForeArm 作打擊視覺錨點|
|LOOP cross／heavy／finisher|Standing Melee Attack Backhand／Horizontal／Downward；右手握拳遮罩，FX仍跟實際 BatonTip|
|RIVET／HUSH 待機|Idle 護架，略不同呼吸速度；ZIP及LOOP原本專用待機保持|
|四角慢行|Walking 取30Hz第16–47樣本、去淨前進位移；可正常向前護架行路，保留護架／短棍手臂姿勢|
|地面受擊／blockstun／向後dash|Head Hit 或 Hit To Body／Inward Block（LOOP保持專用持棍格擋）／Dodging|

共23個私有衍生clip，其中20個已由selector使用、3個僅完成轉換（AirKick／KnockedOut／GetUp）。四角15個地面攻擊slot採新來源。所有挑空招、LOOP刺擊、技能／大招與未有合適來源的空中狀態保留原owner；不把平踢假稱上踢，不以低位Boxing冒充挑空上勾拳。Knocked Out／Getting Up涉及既有死亡、肩摔恢復與過場owner，仍須逐幀接續驗收，這輪未切換。

Walking原檔長10.2667秒，包含約12.6米前進與最後一幀回起點，**不是原地行路**。glTF時間以秒儲存；Blender場景24fps不是來源24fps宣稱。新clip提取單一完整步態，去線性root漂移、保留垂直與有界重心；只在向前0.3–2.0m/s使用，依1.23m/s來源步速配速。高速仍跑步，後退仍用原後步，不反播正向步態。

兩個Hurricane Kick雖然檔案SHA不同，逐幀世界關節位置及旋轉的5位小數semantic hash一致，因此只取一段。兩個肩摔SHA與已驗收版本相同。Boxing在實際骨架中是蹲低身擊；先前「上勾拳」粗略描述由這次覆核更正。這批沒有Sweep Kick。

## 重定向及接入

`inspect_mixamo_batch.py`以秒計算、30Hz取樣，保留來源世界骨架／rest／旋轉在repo外；builder將它轉到既有Quaternius canonical rest，以肩線／身高frame及骨方向校準，再沿原CombatMotions重定向到四角。左右踢使用全域rest-relative鏡射＋左右骨交換，不直接翻local quaternion。

來源前進位移不驅動simulation。保留最多0.32m來源平面重心，runtime重心offset總長上限0.55 rig單位；出招phase依原startup／active／recovery對齊source contact，傷害及移動數值不變。新profile擁有完整姿勢，停用原程序扭髖／手腳瞄準／body squash／額外lunge；保留原foot IK，再按實際蒙皮最低點修正大鞋鞋底穿地。FX與接地排除肢體共用實際接觸骨，例如Hook為LeftHand、肘擊為RightForeArm。

來源、原GLB與可還原曲線不進公開Git；公開只有程式、非逐幀metadata、診斷渲染與影片。loader核對canonical SHA、schema／clip／curve／finite資料，缺檔或不相容時用原動畫。庫在首次載入時固定，安裝後需重開遊戲。

## 本機安裝

Pull任務分支後下載對話提供的私有`mixamo_fighters.json`，在repo根執行：

```sh
python3 tools/install_mixamo_motions.py ~/Downloads/mixamo_fighters.json
```

肩摔仍另外用`tools/install_mixamo_throw.py`安裝`mixamo_shoulder_throw.json`。兩者寫入被Git忽略的`godot/.godot/private_animation`；清快取後要重裝。亦可用`GAME_LAB_MOTION_LIBRARY`／`GAME_LAB_THROW_LIBRARY`指repo外檔案。不會在Fetch／Pull時自動下載Mixamo曲線。

可由原檔重建，不依賴Adobe登入／MCP：

```sh
blender -b --python tools/inspect_mixamo_batch.py -- --input-dir /private/downloads --out-private /private/samples
blender -b --python tools/build_mixamo_motion_library.py -- --samples /private/samples --output /private/mixamo_fighters.json
```

亦可用`--manifest /private/input-manifest.json`指定`[{"path":"/private/Knocked Out.fbx","file_id":"local","filename":"Knocked Out.fbx"}, ...]`；檔名見sources.json。builder以來源檔名查找inspection對應樣本，順序可不同。

## 仍待做

- AirKick／KnockedOut／GetUp的正式owner接續與全動作時間軸驗收；尤其不把8.33秒Getting Up整段硬塞進原28tick恢復。
- 真正上踢／挑空上勾拳、Sweep Kick、前閃、跑步／後退、跳起落地，以及技能／大招與演出來源；沿原替換計劃分批。
- Mac／實體輸入／真人手感與效能覆核。Linux軟體渲染與MovieWriter不代表使用者裝置即時效能。

只推送`codex/four-fighter-motion-plan`／草稿PR #37；沒有合併main或更新Web。
