# Mixamo：四角完整動作替換及手動下載清單

2026-11-14（香港）。來源基線a5f7157。使用者新增要求：替代全部生硬動作；無法代理下載時提供名稱，由使用者從官方Mixamo下載。此授權涵蓋站姿、全方向移動／換邊、攻防／空戰、受擊／倒地／起身及角色演出，不只L或投技。

## 目前能確認的範圍

本執行環境status仍為restricted／enforced、custom allowed_hosts=[]。正常繼承proxy、帶上游公開X-Api-Key的官方products查詢仍Tunnel403；沒有繞過或嘗試其他代理。另一對話先前能連通的紀錄保留，不推論這個執行個體已同樣放行。

本表**49項是搜尋／描述索引候選，不是49段已看完的官方預覽，更不是已下載或接入**。只查名稱／描述／motion id的文字metadata，沒有下載第三方FBX或動畫鏡像。搜尋欄有些是UI名稱，有些是搜尋詞；同名結果用描述辨識，下載到手後再按實際FBX與預覽確認。肩摔攻守兩個使用者上傳檔已另行檢查，不必重下載，見[evidence/judo-source-pair](evidence/judo-source-pair/README.md)。

## 給使用者：先取P0的19段

1. 進[Mixamo Animations](https://www.mixamo.com/#/?page=1&type=Motion%2CMotionPack)，沿用剛才兩段肩摔所使用的**同一個角色**。不用先把四位遊戲角色各下載一遍。
2. 先下載下表P0的19段；Boxing／Kicking等有多個同名結果，按描述挑選，別只保留第一個結果。缺某個精確名稱時先用短搜尋詞，不拿不相關動畫代替。
3. 本專案的建議匯出規格：FBX Binary、30fps、Keyframe Reduction=None、保留完整時長、先不Mirror／Trim或調速度。已有肩摔的帶skin參考檔，其他段可Without Skin；若網站不提供該選項，With Skin亦可。
4. 初次保留root位移，不把所有動作一律勾In Place。接入時由simulation控制角色位移，再按原root／stride量測做去位移與腳步同步；不是讓來源root直接改判定。
5. 同名檔加描述後綴（例如RIVET_Boxing_BackHandUppercut.fbx、RIVET_Boxing_Idle.fbx），避免Boxing.fbx互相覆寫。打包ZIP上傳即可；可每批5–10段，原FBX不進公開repo。

這些匯出值是本專案的管線選擇，並非Adobe承諾的即插即用規格。[Adobe操作說明](https://helpx.adobe.com/creative-cloud/help/animate-characters-mixamo.html)確認在Animations搜尋、點縮圖預覽、調參後下載；[Adobe FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)確認免費Adobe ID及遊戲商用，免費不等於CC0／可公開散佈來源曲線。

## 候選表

P0＝首批19段；P1＝完整覆蓋第二批24項；P2＝演出或研究6項。可點搜尋詞開官方搜尋，但本輪無法驗證該頁實際返回結果。

| # | 優先 | 用途角色 | Mixamo搜尋名稱／詞 | 辨識描述（索引原文） | 預定用途 |
|---|---|---|---|---|---|
| 1 | P0 | ZIP | [Kicking](https://www.mixamo.com/#/?page=1&query=Kicking) | Male Front Snap Kick With The Lead Foot | 前腳短踢／J起手 |
| 2 | P0 | ZIP | [Roundhouse Kick](https://www.mixamo.com/#/?page=1&query=Roundhouse%20Kick) | Roundhouse Kick With Front Foot Advancing | 迴旋踢／連段收尾 |
| 3 | P0 | ZIP | [Hurricane Kick](https://www.mixamo.com/#/?page=1&query=Hurricane%20Kick) | Flying Hurricane Kick | 空中旋踢／大招素材 |
| 4 | P0 | ZIP | [Sweep Kick](https://www.mixamo.com/#/?page=1&query=Sweep%20Kick) | 360 Leg Sweep Kick | 低掃／地面重踢 |
| 5 | P1 | ZIP | [Drop Kick](https://www.mixamo.com/#/?page=1&query=Drop%20Kick) | Male Kicking With Both Legs | 雙腳飛踢／重招候選 |
| 6 | P1 | ZIP | [Kicking](https://www.mixamo.com/#/?page=1&query=Kicking) | Spinning Back Kick Advancing | 旋身後踢；與前腳短踢區分 |
| 7 | P1 | ZIP | [Capoeira](https://www.mixamo.com/#/?page=1&query=Capoeira) | Capoeira Idle | 輕步待機；取小幅循環，非整段照搬 |
| 8 | P1 | ZIP | [Capoeira](https://www.mixamo.com/#/?page=1&query=Capoeira) | Capoeira Escape | 低身閃避；接地需驗 |
| 9 | P0 | RIVET | [Boxing](https://www.mixamo.com/#/?page=1&query=Boxing) | Boxing Idle | 穩定拳擊待機 |
| 10 | P0 | RIVET | [Jab Cross](https://www.mixamo.com/#/?page=1&query=Jab%20Cross) | Boxing Jab Cross Medium | 直拳二連／J鏈 |
| 11 | P0 | RIVET | [Hook](https://www.mixamo.com/#/?page=1&query=Hook) | Mid Hook Punch To The Body | 身體勾拳／重擊；選Body版本 |
| 12 | P0 | RIVET | [Boxing](https://www.mixamo.com/#/?page=1&query=Boxing) | Boxing Back Hand Uppercut | 後手上勾／launcher；選Back Hand Uppercut |
| 13 | P1 | RIVET | [Body Jab Cross](https://www.mixamo.com/#/?page=1&query=Body%20Jab%20Cross) | Boxing Body Jab Cross Medium | 近身腹部連擊 |
| 14 | P1 | RIVET | [Boxing](https://www.mixamo.com/#/?page=1&query=Boxing) | Short Boxing Step Forward | 短前進步／避免腿部鎖死 |
| 15 | P1 | RIVET | [Boxing](https://www.mixamo.com/#/?page=1&query=Boxing) | Short Boxing Step Backward | 短後退步／替換倒播前進 |
| 16 | P2 | RIVET | [Boxing](https://www.mixamo.com/#/?page=1&query=Boxing) | Boxing Taunt | 選角／挑釁 |
| 17 | P0 | HUSH | [Jab To Elbow Punch](https://www.mixamo.com/#/?page=1&query=Jab%20To%20Elbow%20Punch) | Jab To Elbow Combo | 短直拳接肘／J鏈 |
| 18 | P0 | HUSH | [Elbow Punching](https://www.mixamo.com/#/?page=1&query=Elbow%20Punching) | Male Elbow Punch | 近身肘擊／短重擊 |
| 19 | P0 | HUSH | [Inward Block](https://www.mixamo.com/#/?page=1&query=Inward%20Block) | Inward Block | 內撥格擋／parry |
| 20 | P0 | HUSH | [Dodging](https://www.mixamo.com/#/?page=1&query=Dodging) | Boxing Dodge Retreat | 後撤閃避／E；選Retreat |
| 21 | P1 | HUSH | [Uppercut Jab](https://www.mixamo.com/#/?page=1&query=Uppercut%20Jab) | Uppercut Jab And Open Palm Strike Combo | 上勾接掌擊／技能候選 |
| 22 | P1 | HUSH | [Boxing](https://www.mixamo.com/#/?page=1&query=Boxing) | Short Left Boxing Side Step | 短左側步／截擊步法 |
| 23 | P1 | HUSH | [Boxing](https://www.mixamo.com/#/?page=1&query=Boxing) | Short Right Boxing Side Step | 短右側步／截擊步法 |
| 24 | P0 | LOOP | [Standing Melee Attack Horizontal](https://www.mixamo.com/#/?page=1&query=Standing%20Melee%20Attack%20Horizontal) | Right To Left Attack With Axe | 單手橫掃；來源斧擊，需短棍改編 |
| 25 | P0 | LOOP | [Standing Melee Attack Downward](https://www.mixamo.com/#/?page=1&query=Standing%20Melee%20Attack%20Downward) | Downward Attack With Axe | 踏步下敲；需短棍握點改編 |
| 26 | P0 | LOOP | [Standing Melee Attack Backhand](https://www.mixamo.com/#/?page=1&query=Standing%20Melee%20Attack%20Backhand) | Backhanded Upward Attack With Axe | 反手上撩；需短棍握點改編 |
| 27 | P1 | LOOP | [Melee](https://www.mixamo.com/#/?page=1&query=Melee) | One Handed Club Combo Attack | 搜尋One Handed Club Combo Attack描述；UI標題未核實 |
| 28 | P0 | 共用家族 | [Head Hit](https://www.mixamo.com/#/?page=1&query=Head%20Hit) | Receiving A Medium Hit To The Head From A Left Punch | 中等頭部受擊；按四角體型調校 |
| 29 | P0 | 共用家族 | [Hit To Body](https://www.mixamo.com/#/?page=1&query=Hit%20To%20Body) | Receiving A Body Hit By A Right Uppercut | 上勾腹部受擊 |
| 30 | P0 | 共用家族 | [Getting Up](https://www.mixamo.com/#/?page=1&query=Getting%20Up) | Getting Up From Back | 仰躺起身 |
| 31 | P0 | 共用家族 | [Knocked Out](https://www.mixamo.com/#/?page=1&query=Knocked%20Out) | Knocked Out Falling To Back | 向後倒地／KO；落地要量測 |
| 32 | P1 | 共用家族 | [Fighting Idle](https://www.mixamo.com/#/?page=1&query=Fighting%20Idle) | Bouncing Fight Idle With Guard Up | 護架待機候選；不是四角共用最終姿態 |
| 33 | P1 | 共用家族 | [Blocking](https://www.mixamo.com/#/?page=1&query=Blocking) | Blocking Body With Arms | 護腹格擋 |
| 34 | P1 | 共用家族 | [Hit Reaction](https://www.mixamo.com/#/?page=1&query=Hit%20Reaction) | Large Hit Reaction From The Right | 右側大受擊 |
| 35 | P1 | 共用家族 | [Getting Up](https://www.mixamo.com/#/?page=1&query=Getting%20Up) | Getting Up From Stomach | 俯臥起身；與仰躺版本配對 |
| 36 | P1 | 共用家族 | [Walking](https://www.mixamo.com/#/?page=1&query=Walking) | Walking Forward | 前進／stride基準 |
| 37 | P1 | 共用家族 | [Walking Backwards](https://www.mixamo.com/#/?page=1&query=Walking%20Backwards) | Walking Backwards | 真後退 |
| 38 | P1 | 共用家族 | [Running](https://www.mixamo.com/#/?page=1&query=Running) | Running Forward | 跑步／追擊過渡 |
| 39 | P1 | 共用家族 | [Sprinting](https://www.mixamo.com/#/?page=1&query=Sprinting) | Standard Sprint | 衝刺／高速追擊 |
| 40 | P1 | 共用家族 | [Jumping Up](https://www.mixamo.com/#/?page=1&query=Jumping%20Up) | Jumping Up From Action Idle | 起跳；由simulation控制實際高度 |
| 41 | P1 | 共用家族 | [Falling Idle](https://www.mixamo.com/#/?page=1&query=Falling%20Idle) | Mid-Air Falling Idle | 空中下落循環 |
| 42 | P1 | 共用家族 | [Landing](https://www.mixamo.com/#/?page=1&query=Landing) | Landing From Jump | 落地緩衝／回架 |
| 43 | P1 | 共用家族 | [Left Turn](https://www.mixamo.com/#/?page=1&query=Left%20Turn) | 90 Degree Left Turn | 90度左轉；換邊需補180度組合 |
| 44 | P1 | 共用家族 | [Right Turn](https://www.mixamo.com/#/?page=1&query=Right%20Turn) | Standing 180 Right Turn | 180度右轉；換邊候選 |
| 45 | P2 | 演出 | [Victory](https://www.mixamo.com/#/?page=1&query=Victory) | Victory From A Boxing Win | RIVET勝出／選角確認 |
| 46 | P2 | 演出 | [Listening To Music](https://www.mixamo.com/#/?page=1&query=Listening%20To%20Music) | Male With Headphones Listening To Music | HUSH／LOOP據點與耳機動作 |
| 47 | P2 | 演出 | [Breathing Idle](https://www.mixamo.com/#/?page=1&query=Breathing%20Idle) | Breathing Idle | 中性呼吸／轉場緩衝 |
| 48 | P2 | 研究暫緩 | [Mma Takedown](https://www.mixamo.com/#/?page=1&query=Mma%20Takedown) | Mma Takedown To Standing Mma Idle | 倒地後回站架候選A；需確認攻守角色 |
| 49 | P2 | 研究暫緩 | [Mma Takedown](https://www.mixamo.com/#/?page=1&query=Mma%20Takedown) | Mma Takedown To Standing Mma Idle | 倒地後回站架候選B；未驗配對，不列首批 |

## 如何替換全部生硬動作

| 家族 | 最終處理方式／尚待檢查 |
|---|---|
| 戰鬥待機／guard／blockstun | ZIP輕步、RIVET拳架、HUSH收窄護架、LOOP持棍；移動與防禦用遮罩接回同一套姿態，不能四人共用一個idle。 |
| 前後步／跑／dash／換邊 | 換真後退與側步，記錄每段stride／腳步相位，消除倒播與瞬間翻身；腳底及骨盆校正與角色實際速度一致。 |
| J鏈／heavy／launcher | 各招採完整出招→接觸→回收來源，按骨端最遠點／支撐腳建立marker；連段可接窗口，不能把整段硬塞原tick。miss／block／hit都要自然。 |
| L／方向L／OD／LOOP pulse | 用四人的真拳腳／短棍素材重編各子段，保留真資源與事件；不能只把一段三連擊壓縮成所有招式。LOOP施放點仍需手工接物／指令手勢。 |
| 跳躍／追擊／空中五擊／反制 | 起跳／滯空／下落／落地分開；Hurricane／Drop Kick僅作候選，接既有空戰軌跡，不能來源飛行曲線與simulation同時搬人物。拳肘／短棍空擊未有專用mocap證據。 |
| grab／受投 | 已有肩摔配對；共同裁切／雙人時鐘／root與手部接觸／落地一次結算，不能回退成抓取擊退。Mma Takedown兩項未驗攻守或柔道完整性，研究暫緩。 |
| 地面／空中stun、反彈、倒地、死亡、起身 | 方向與強度分家；頭／腹命中、擊飛與地面收尾各選片。只有指定招式開ricochet，不能為動畫新增假反彈。 |
| 選角／登場／勝出／離場／據點／故事 | 從同一角色profile延伸性格，手接耳機／棍／物件，走動要真步態；新中性演出不能覆寫既有獨立過場owner。 |

**換FBX本身不足以解決生硬**：接入同時修正骨盆／支撐腳、分段重定時、跨動作blend、單一pose owner及握點；不是重新疊多個程序層去扭來源動作。有限IK作接觸校正，原始GLB不變。LOOP三個斧擊候選屬改編來源，未核實專用eskrima／短棍mocap；不把雙手長兵器強套單手短棍。

## 接入順序與驗收

先P0角色出招＋受擊起身，與已收到肩摔一併做一組真角色樣板；再P1移動／防禦／跳落與全部既有move id；最後P2演出。每段記錄SHA／角色／骨架／FPS／root／contact marker／來源與剪輯，不公開原檔或可還原曲線。保留缺件fallback，但不能將fallback叫完成替換。

驗收覆蓋四角×雙朝向、miss／block／hit、連段接回、短長距離、身高差與牆邊、空地交接、hitstop／pause／F2、中斷／KO／重開、群戰及既有過場；確保simulation不被呈現改寫。以正常輸入原生錄影驗腳／手／穿模，不能只看headless成功。原音樂、存檔與Web發佈規則保持。本輪沒有runtime變更，沒有新的遊戲測試結果。

## 出處與證據分級

- 官方法規／使用流程：上述Adobe FAQ及操作說明。
- 名稱／描述候選：[文字metadata索引](https://github.com/Teethree89/mixamo-downloader-macos-2026/blob/main/src/mixamo_anims.json)；[名稱／描述對照](https://huggingface.co/datasets/Linzhan/Mixamo-Animations-Characters/viewer/animations/train)、[補充名稱索引](https://huggingface.co/datasets/tanish434/Mixamo-Animations-Characters/viewer/animations/train)。僅作找名線索，不用其動畫檔，不宣稱Adobe官方維護或授權已核實。
- [機器可讀清單](../references/animation-sources/mixamo-replacement-shortlist.json)保存motion id、描述及查核限制。UI標題／別名可能不同，以使用者官方頁預覽與實際FBX為準。

