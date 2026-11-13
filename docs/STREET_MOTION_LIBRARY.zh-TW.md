# CC0動作庫接入：ZIP踢技與RIVET擴充

2026-11-13。接續[RIVET首切片](RIVET_MOTION_SLICE.zh-TW.md)，基線 `25c83ec`，同分支 `codex/four-fighter-motion-plan`／草稿PR #29。四角整體方案見[製作規劃](FOUR_FIGHTER_MOTION_REVIEW_PLAN.zh-TW.md)。本輪已接正式共用角色呈現，沒有新增教室、修改玩法判定或發佈Web。

## 真正取得的動畫素材

本輪從固定Git提交的可讀鏡像取得原始GLB，核對官方CC0說明及KayKit原包License.txt，再離線轉接；未取得Mixamo／ActorCore／Rokoko／Fab帳戶商品，也未重綁角色。新來源不是AI生成或逐骨硬拉出的踢腿。

| 來源 | 本輪選用 | 授權與追溯 |
| --- | --- | --- |
| [Quaternius UAL2 Standard](https://quaternius.itch.io/universal-animation-library-2) | Melee_Hook與配對Melee_Hook_Rec | 官方標示CC0；鏡像richardanaya/metaverse-avatar固定84fd636…；原檔8,061,600 bytes，SHA256在manifest。此取得檔含43clips，並非宣稱拿到完整版130+ |
| [KayKit Character Animations 1.1](https://kaylousberg.itch.io/kaykit-character-animations) | 完整Unarmed Kick、Unarmed Idle／Punch、Walk、Run、Walking Backwards、Dodge Forward／Backward | 官方及包內License皆CC0；鏡像PaperPrototype/KayKitDemos固定4a59e976…；三份原GLB與授權來源有SHA256 |

[完整manifest](../references/animation-sources/street-library.json)記錄四個原GLB的作者、官方頁、鏡像、提交、原路徑、raw URL、bytes／SHA及衍生檔hash。KayKit原License僅整理行尾空白，原／衍生hash分開記錄，文字保留在`assets/animations/LICENSE-KayKit.txt`。未複製鏡像其他AGPL角色或模型；只擷取上述CC0動畫曲線。首次LFS鏡像讀取失敗，改用固定非LFS鏡像，不把未取得的archive寫成已錄用。

## 轉接管線

- 新`tools/build_street_motion_library.py`解析GLB的rotation／translation，將來源全局rest-relative旋轉轉到既有canonical rig，再重建local rotations；60Hz取樣。KayKit對應19個主要身體骨，缺少的頸／肩／手指骨沿canonical rest；UAL2對應52骨。這是兩套不同骨架的離線轉接，不要求現有65關節英雄換骨。
- 保留完整身體踢擊，包括軀幹、髖與腿；以解剖中線反射完整旋轉delta與hip offset，生成另一腿版本，沒有倒播或只鏡像鞋子。
- 擷取10個來源clip，加1個全身鏡像，共11個motion clips，約582KiB；新`street_library.json`在runtime併入原庫，總30clips。原19clip JSON與四英雄GLB byte不變。
- 原始root水平移動不驅動simulation；hip垂直曲線仍沿現有上下界。接觸marker由來源手／腳相對hip的前向位移估計，再以真命中及左右朝向檢查，並非宣稱作者原包附了遊戲判定marker。
- 建置器要求四個來源與canonical檔案hash符合manifest；再次建置SHA與錄用檔相同。需numpy／scipy（本環境2.3.5／1.17.0），不是runtime依賴。原GLB可按manifest固定raw URL重新取得，未將整套來源網格複製進遊戲。

## 正式遊戲變更

### ZIP

地面idle改用獨立unarmed guard；jab／cross／heavy／finisher／launcher／special／overdrive七個id改採完整踢擊及左右腿版本。launcher保留同一完整底片，只在這個單一owner內對右腿加有界上挑軌跡修正，不冒稱新取得獨立上踢mocap。

L首踢真命中後，下一踢才切換腿；W+L依真確認進度採右→左→右。確認當下先保留出腳的接觸pose，再於接下來的simulation幀收回／準備下一腿；hitstop停住接觸pose。揮空不切腿、不顯示假後續攻擊、不增加追蹤或距離。

### RIVET

保留第一輪站穩的jab／cross／預壓直拳；heavy／finisher／overdrive換成真正UAL2勾拳及配對回收片段。launcher在拳擊底片內由同一owner給有界上勾手臂軌跡，尚未取得獨立完整uppercut素材。

RIVET七種地面攻擊仍使用原boxing stance的骨盆／腿遮罩，避免原本的滑步／抬腿覆寫；**尚未完成完整轉髖與步進重拳，也不是地形foot IK**。走動則採新來源的完整腿部曲線、上身維持拳擊護架，不再固定住走路的腿。

### 兩人的移動與呈現整合

- 前進／跑步採新的正向走／跑；後退用真Walking_Backwards，沒有倒播Walk；E依方向採Dodge Forward／Backward，取代兩人的Roll。播放速度按實際vx及來源步頻基準換算，尚需真人調stride與停步銜接。
- `street_motion.gd`統一選片、時間、全身owner與出招肢體。Neon與legacy空中／共用Cannon／2.1倍膨脹不覆寫新地面動作。跳起、落地、受擊、死亡、投技、選角與過場按明確條件交還原owner；沒有把所有空戰也當成完成。
- 骨骼拖尾、技能追蹤與接觸取點改讀當前出招拳腳：ZIP隨確認進度換腳，RIVET新勾拳用右手，避免新動畫配舊腳骨。HUSH／LOOP及空戰仍有原fallback。
- 傷害、startup／active／recovery、能量、霸體、ROUTE／PRELOAD／SAMPLE／節點、進度存檔、BGM與原始模型均保持。

## 驗證與實際畫面

[證據索引](evidence/street-motion-library/README.md)／[12秒有聲原生片](evidence/street-motion-library/street-motions.mp4)。三段重置練習，正常指令ZIP L／ZIP W+L／RIVET W+L，分別2／3／1次真命中；未注入傷害。360幀、30fps，固定步進錄製，Linux llvmpipe，不能當目標機60fps。

- 90項新motion／FX socket檢查＋19項首輪RIVET＋46角色規則＋104死亡／群戰＋26現有ink FX＝**285項通過**。包括兩人七招雙朝向、F2／hitstop、前後步／跑／閃、上挑、hook recovery、真確認與揮空、接觸拖尾取對拳腳。
- 六個motion／recipe runtime腳本七類warning當error編譯通過。全19腳本suite仍15/19，失敗的四個上層腳本與前輪基線相同（開場、sprite/world FX、據點的既有warning）；不冒稱全套strict通過。
- 新增真正固定tick的輸入重播：兩組角色、1800 simulation ticks、每180tick明示重設場景以測付費招式；純simulation對照有呈現的simulation，0差異、0呈現改寫。基線25c83ec與新版指令hash、狀態hash及21次真命中完全相同，狀態SHA為`022cef61e6c1fea696d62c18791f77a38d82917bfdce546fa3318d15fb049c3e`。
- 舊`probe_ink_equivalence`以Demo／畫面迴圈驅動，本輪受到並行Godot視窗切換焦點、觸發正式自動暫停而不穩定；前後檔保留為demo-trajectory，不用它宣稱固定輸入相同。新的verify_motion_gameplay直接記錄指令hash並逐tick比對，與舊跨輪hash不混用。
- 四角22類×90tick的固定root抽樣及8類來源preview；HUSH／LOOP每tick骨socket與前輪資料完全相同。這些是呈現fixture，非真人步行／鞋底幾何／地形接地測量。原生片與代表抽格已目視，未逐來源幀完整藝術驗收。

## 尚未完成

HUSH精準截擊／LOOP短棍尚未重製；ZIP目前是同一完整踢擊的換腿、節奏與上挑變體，不是七套獨立武術動作。四角獨立空戰／成對投技、RIVET完整轉髖、foot IK、plant腳步marker、新角色VFX幾何與鏡頭／音色、真人／Mac／目標GPU驗收仍待做。後續優先取得更多完整拳擊／踢技片，再做HUSH與LOOP；不把本輪當四角色計劃全部完成。

錄影工具每幀檢查screen=play，若焦點中斷便失敗；initial-movie-focus.json保留初次被暫停的2／0／1命中記錄，不作accepted影片。正式焦點自動暫停功能保持。
