# HUSH截擊／LOOP短棍：地面動作第三輪

2026-11-13（台北）。基線 `471b21e`，同分支 `codex/four-fighter-motion-plan`／草稿PR #29。接續[前輪動作庫](STREET_MOTION_LIBRARY.zh-TW.md)與[四角總方案](FOUR_FIGHTER_MOTION_REVIEW_PLAN.zh-TW.md)。本輪修改正式共用角色呈現，未改判定、資源、存檔、音樂或公開Web。

## 已接入範圍

HUSH七個地面攻擊id（jab／cross／heavy／finisher／launcher／special／overdrive）、LOOP相同七個加node_pulse，以及兩人的待機、前後移動／跑／閃、防守與blockstun。兩人使用獨立pose owner，不再讓共用Cannon、角色索引舊pose及Neon蓄勢層依序覆寫同一骨骼。空戰、投技、一般受擊、死亡、選角和過場仍有原有owner；沒有把全動作重製寫成完成。

### HUSH：短護架、撤步直拳與取樣反擊

- 待機用未出拳的KK_Punch起始姿態，jab用全身反射的另一手版本；其餘地面招式以原庫完整直拳為基礎，按實際startup／active／recovery分段。大招是一記較長起手的精準截擊，沒有共用雙掌砲姿勢或額外假連擊。
- 防守採boxing guard，早段guard_frames帶小幅撥擋手勢；blockstun用Hit_Chest反應、雙臂保持護架，hitstop停止反應取樣。這是動作回饋，沒有延長parry窗口。
- L沿原simulation前五tick後撤；移除視覺model前移，避免畫面與真後退互相抵銷。取得SAMPLE後待機自由手上收；實際消耗sample_boost時有小幅支撐動作，傷害／位移收益仍由原規則決定。
- launcher由同一owner對拳擊底片作有界上勾軌跡修正，未宣稱取得獨立uppercut素材。HUSH目前仍有共用直拳來源的節奏變體，並非七套獨立武術mocap。

### LOOP：刺、掃、劈與訊號手勢

- jab用單手刺擊，cross／大招用橫掃，heavy／finisher／node_pulse用下劈，launcher用斜擊加有界上撩修正。素材是CC0單手武器動畫轉作短棍，不宣稱原包是eskrima／baton專用動捕。
- 待機取單手刺擊的起始持棍姿態；走／跑／閃時手臂維持這個握持姿態，腿部沿完整來源移動。防守與blockstun分別取blocking與block-hit。
- L近點是向下短指令，方向＋L遠點是向前指令；兩種手部姿態有實測差異。S＋L用下壓動作配真node_pulse；大招自由手按剩餘encore節點作訊號姿態。所有節點圖形／傷害仍只由實際node事件觸發，0點版不生成假脈衝。
- 手指握姿取已有CC0 Punch_Enter的手指遮罩，握點依RightHand到Middle1的rest位置放在掌心；沒有改原角色骨架或網格。短棍仍是既有獨立幾何，未假稱新模型。
- 新BatonTip marker與當前骨骼矩陣取點，避免BoneAttachment畫面更新前的滯後；技能拖尾／接觸裝飾讀棍尖而非右拳。原本握點在手腕的位置已移入掌內，換角時清掉marker引用。

## 素材與轉接

沿用[固定來源manifest](../references/animation-sources/street-library.json)中的同一份KayKit1.1 CombatMelee GLB，來源raw hash未變。新增七個單手／防守來源clip與一個全身Punch反射，共8個衍生項目；街鬥擴充庫由11增至19，連同原19clip共38。原十一個衍生clip的完整資料逐項相同，原19clip JSON及四英雄GLB也保持byte不變。

建置器現可共用全身反射流程處理踢擊與拳擊；持棍曲線的接觸估計固定看右手，避免自由手擺幅誤作武器接觸。保留60Hz離線轉接、來源hash檢查、作者／CC0授權及可重建流程。這輪沒有購買、下載或冒稱使用Mixamo／ActorCore／Rokoko／Fab帳戶商品。

## 驗證與畫面

[證據索引](evidence/hush-loop-motion/README.md)含代表抽格、原生錄影與完整JSON／log。

- 122項新檢查：七／八招雙朝向、真合法起招fixture、F2／hitstop、資源快照不變、各種owner交還、近遠手勢、棍尖／握點、正常招架賺sample後真反擊、正常放點與脈衝、明示0／1／2節點encore及換角清理，全部通過。
- 90前輪ZIP／RIVET＋19首輪RIVET＋46角色規則＋104死亡／群戰＋26FX，連同本輪共 **407項通過**。七個motion／recipe runtime腳本以七類warning當error通過；完整19腳本suite仍15/19，與基線同四個既有失敗，不冒稱全套嚴格檢查通過。
- 相同1800 simulation ticks、相同輸入hash，在471b21e隔離基線與新版狀態hash同為`022cef61e6c1fea696d62c18791f77a38d82917bfdce546fa3318d15fb049c3e`；21真命中、0simulation差異、0呈現改寫。ZIP／RIVET四角22類抽樣的每tick骨socket也與前輪相同。
- 四角固定root抽樣只量骨socket與姿態，不當鞋底幾何／地形IK或真人步行驗收。代表抽格及影片目視，不冒稱逐來源幀完整審查；Linux4.6.3 llvmpipe／Dummy，不代表Mac、目標GPU或真人手感。

## 尚待完成

四角完整轉髖與接地IK、更多獨立招式、成對投技與空戰，還有選角／勝出／據點共用新profile、各自VFX幾何／鏡頭／音色，仍按總方案接續。這輪已有四人的獨立地面動作owner，但四角全套視覺重製尚未完成。

[15秒有聲原生片](evidence/hush-loop-motion/counter-motions.mp4)：HUSH真招架取得／消耗SAMPLE，LOOP兩點手動脈衝、一點接大招。450幀連續PLAY；三段各1次真命中，後兩段各1個真節點脈衝事件。沒有預塞樣本／節點或注入傷害；對手首記jab為明示合法起招fixture。固定步進錄製非硬體FPS；[對照圖](evidence/hush-loop-motion/comparison.png)使用相同tick的代表姿態，不是逐招完整動態驗收。
