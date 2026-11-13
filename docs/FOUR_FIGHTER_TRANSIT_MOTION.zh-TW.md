# 四角空地交接、受擊與投技手勢

2026-11-13（UTC）。接續[四角聲光](FOUR_FIGHTER_EFFECT_STYLE.zh-TW.md)。正式共用 `FighterVisual` 已接入 `transit_motion.gd`，不另建玩法；修正離地後回共用程序姿態、舊Neon／Cannon重寫骨架、360°起跳自轉、身體拉伸與拳腳特效錯綁。

[14秒空連預覽](evidence/transit-motion/air-combat.mp4)／[8秒投技預覽](evidence/transit-motion/throws.mp4)。影片為重設練習fixture，不是人手操作。

| 範圍 | ZIP | RIVET | HUSH | LOOP |
|---|---|---|---|---|
| air_jab | 左點踢 | 左直拳 | 左短拳 | 棍端刺擊 |
| air_kick | 右展腿 | 右拳（沿用既有move id） | 右腿短踢路線、護架保留 | 單手橫掃 |
| air_finisher | 左腿變體 | 右勾拳 | 右直拳 | 斜向棍擊 |
| meteor／air_counter攻擊 | 右腿下壓 | 右拳／前臂下壓 | 右拳截擊／下壓 | 下劈／反制棍擊 |
| 起跳／浮空／落地 | 輕護架、支撐腿收起 | 拳擊護架、收膝 | 小護架、自由手穩定 | 持棍、自由手平衡 |
| 受擊 | 頭肩回彈 | 胸口受力、自由手回護 | 短回彈、自由手護面 | 頭肩回彈、持棍手保握 |
| grab初步手勢 | 左手抓取／釋放 | 右拳側帶 | 右手接觸、自由手撥臂 | 棍身引開／推離手勢 |

## 來源與控制順序

保留現有38片段（19原庫＋19擴充庫）、原GLB與全部來源hash／授權。使用已核對Quaternius／UAL2與KayKit CC0全身片段：`Jump_Start/Loop/Land`、`Hit_Head/Chest`、拳擊、踢擊與單手武器片段，沒有新增下載或帳戶素材。來源與重建仍見[STREET_MOTION_LIBRARY.zh-TW.md](STREET_MOTION_LIBRARY.zh-TW.md)及references/animation-sources/street-library.json。

空擊是現有全身攻擊曲線與跳躍腿部遮罩的編排，**不是新取得的專用空中mocap**：ZIP保留打擊腿，用jump支撐腿；其他角色按拳／棍型態保留兩腿jump姿態，HUSH踢擊例外保留右腿。原始曲線不改。下壓／護架／投技手勢的有界修正屬同一owner內程序修正，不冒稱來源片段本身包含該招。

`StreetMotion`先派送空中／受擊／grab profile，再派送既有地面profile。`CombatMotions`同一次取樣內完成腿／護架／握指遮罩與有界修正，完成後直接返回；`NeonSignatureMotion`不再覆寫已擁有的pose。`FighterVisual`同時停止這些狀態的舊lunge、2.1倍拳腳、非等比身體拉伸及起跳整人自轉。根位置、朝向、起跳／追擊／落地規則仍由simulation決定；這不是新物理系統。

空中L／大招／LOOP pulse也接到角色編排；LOOP沿用真近遠放點、sample／encore等資料，ZIP真確認換腿共用同一segment函式，RIVET持蓄力起手沿原sample時序。空中招式的FxRecipes現在讀原simulation字典也能取得正確手／腳／BatonTip，不依賴只在呈現副本才有的`air_enabled`欄位。投技ZIP改為實際左手；RIVET空中拳不再沿舊`air_kick`名稱綁右腳。

受擊用呈現時鐘取樣，hitstop／暫停可凍結；新的受擊flash才重啟反應。rise/apex/fall之間不重啟同一受擊；受擊落地會交接一次。死亡仍獨占Death01，已存在的空反30tick hold、rally、指定技ricochet翻滾、KO、showcase／cinematic繼續交回原owner，本輪沒有重製這些導演片段。

## 投技與接地的實際範圍

本輪grab只有四種來源編排的抓取／釋放**手勢**，接正式一次投技結算，沒有偽造抓住對手、額外傷害或跨角色動畫同步。**攻守配對摔投、抱提／轉摔的完整動捕、手到身體的接觸約束尚未完成**。同樣，腿部遮罩與去除拉伸不是完整轉髖、鞋底接地或地形足部IK。後續應先補這兩項，再擴選角／登場／勝出／據點同profile。

## 驗證

[evidence/transit-motion](evidence/transit-motion/README.md)：216新增＋458既有共674通過。新增含四角五空擊、空中L／大招／LOOP pulse與grab雙朝向、骨架有限值、真擊肢、hitstop／F2矩陣不漂移、無非等比放大、sim不改寫、八種空地狀態、連續受擊重啟、死亡／導演交還；另用正常指令完成四角真launcher→付費chase→air hit及一次grab結算。pulse姿態測例的一個節點為明示初始資源fixture，實戰影片無預塞節點。

與ec81ad9隔離scripts比較：14類地面／死亡狀態fixture、4角×90tick，共5,040筆clip與三骨點抽樣完全相同；不把非LOOP的node_pulse人工pose fixture當合法起招。固定1800 simulation ticks同輸入hash／狀態SHA022cef61…、21命中、0差異／骨架呈現改寫。舊三份motion測試的空中／受擊handoff預期明確更新為新owner；原有地面／死亡／showcase斷言保留，未刪檢查。12腳本七類fatal warnings通過；全19suite維持16/19，三處既有警告仍未修。

最終空連影片14秒420幀連續PLAY，每角各真chase一次、air_jab／air_kick／meteor各命中一次，包含自然落地後續連段；投技影片8秒240幀，每角一次真grab。兩片每段均是100能量、固定近身站位練習fixture，正常session指令、沒有注入傷害／空中位置／sample／node。音軌非靜音不等於人耳驗收。

Linux Godot4.6.3 Compatibility／llvmpipe／Dummy；不是Mac／真人／目標GPU效能驗收。BGM transport、規則、存檔與公開Web不變。原始碼推同分支codex/four-fighter-motion-plan／draft PR #29。
