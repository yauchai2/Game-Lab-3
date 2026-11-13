# 四角色全動作 review 與差異化戰鬥製作方案

日期：2026-11-13（香港）。基線：main `7aac2c1631bac1d76d518e9ed666ca2f13c51df8`，已核對 origin/main。**本輪為原始碼／資產 review 與製作規劃，未替換 runtime 動畫、未購買或下載新商業素材、未發佈 Web。**

目標：ZIP、RIVET、HUSH、LOOP 在無特效、灰階剪影及正常速度下，已能靠站姿、步法、出招軌跡、節奏分辨；特效、鏡頭與聲音再放大差異。沿用現有四英雄與核心資源，不重新發明四套互不相容的操作。

## 1. Review 範圍與證據限度

已讀取：AGENTS／README／HANDOFF／TODO／DECISIONS／VALIDATION，LAST_SERVICE_RUNTIME、CHARACTER_ROSTER、CAMPAIGN_COMPLETE_RUNTIME、動畫來源紀錄；原始碼包含 fighter_roster、combat_motions、fighter_visual、aerial_poses、neon_signature_motion、last_service/profiles、fight_simulation 的招式表與解析入口、roster_preview、victory_exit 及據點 reference_workshop.pose_actor。

本輪直接解析四個 GLB 的 JSON：每個 1 skin、65 joints、0 animations。直接讀現用 quaternius_combat.json：19 clips。模型已綁骨，不應一開始就整批重綁。骨名相容不代表姿態、比例、twist 或蒙皮已適合所有招式。

視覺抽查只檢視既有 `docs/evidence/ink-fx/after.mp4` 第3秒、`docs/evidence/last-service-runtime/zip-rivet-demo.mp4` 第5秒；屬歷史版本兩張抽格，能看到交疊／失衡風險，**不能據此判定最新 main 每招逐幀表現，亦非完整影片 review、當前 GPU／真人驗收**。本輪全面 review 指所有動作類別的程式路徑；逐招動態覆核列為 P0 交付，不冒稱已完成。

## 2. 目前動作怪的具體原因

| 優先 | 已確認程式行為／位置 | 對畫面的影響及待驗假說 | 修正方向 |
| --- | --- | --- | --- |
| P0 | combat_motions.gd:93–113：大部分攻擊只選 Jab／Cross／Spell；RIVET cross／finisher／special 選 Sword_Attack | 巨拳沿劍擊軌跡，再被程序拉成拳；四人攻擊底層過度相同 | 逐角色、逐 move、逐子段對應真實完整動作，撤除不合用途的底片 |
| P0 | combat_motions.gd:194起：踢技／挑空用 `_aim_limb` 改拳擊；之後再加角色層、air_poses、共用 Cannon，最後 FighterVisual 加 Neon | 同一骨骼連續被多層指定方向；髖、支撐腳、肩膀未必同時協調 | 一個全身 base owner，明確遮罩及優先級；程序只留小幅校正 |
| P0 | neon_signature_motion.gd:5–26：special 的巨拳／腿／手臂校正不分 startup／active／recovery | 即使底片在打出或收手，上層仍可能維持蓄勢方向；RIVET 特別需檢查 | 改用每個子階段的曲線，不讓蓄勢姿態覆寫接觸與回收 |
| P0 | combat_motions.gd:140–147：接觸點只按 clip 類別0.30／0.42，active固定映到後10% | 同一時間比例未必是每人拳／腳／棍的最遠接觸點 | 每 clip／每角色 contact marker，按真招式三階段分段重定時 |
| P0 | fighter_visual.gd:99：換邊直接±90°；:101–110：model額外前移0.45／0.60 | 突然翻身、腳底視覺滑行、看起來打中但判定未中 | 轉身動畫／腳步相位、縮小視覺前移；不為遷就畫面擴判定 |
| P1 | combat_motions.gd:134–136：後退倒播 Walk；步頻共用速度÷4 | 倒走擺臂及腳掌滾動不自然，四人腿長不同更易滑步 | 真後退／戰鬥側步，逐角stride length校正，左右步相位銜接 |
| P1 | combat_motions.gd:181起只採hip垂直位移並clamp，無戰鬥foot plant解算 | 重拳、單腳踢缺少支撐與骨盆位移；是否穿地需逐幀量測 | 烘焙完整骨盆曲線；simulation掌root，接地階段有限IK／pelvis補償 |
| P1 | aerial_poses.gd.stretch：垂直scale .65–1.40；FighterVisual瞬間手／腳scale 2.1 | 比例跳變、拳套鞋底膨脹；可能蓋過動作重量感 | 先還原1.0驗骨架，再做每角短smear曲線，測1.10–1.25上限提案 |
| P1 | idle ZIP=Dance／RIVET=Spell idle；showcase RIVET=Dance；特殊pose名仍有舊Boxer／Dancer／Bass／Spark | 待機、選角與實戰性格不一致；索引沿用舊角色意圖 | 以固定角色id編排新姿態，legacy文字與資料分離 |
| P1 | grab沿共用Cross加雙手瞄準，沒有成對投技clip；node_pulse也落入預設Cross | 施術手勢與真接觸不符，投技可能兩人不同步 | 配對接觸／釋放marker，節點觸發用專屬手勢，不強迫擊拳 |
| P1 | victory_exit以sin stride＋limb方向生成離場；據點另有固定pose、局部y偏移及1.15／1.45手scale | 戰鬥改善不會自動修好選角、離場、據點；仍可能像滑行人偶 | 共用經核准的角色motion profile，場景導演只指定動作與目標 |

死亡已有 Death01 hip下落與skin最低點貼地修補，應保留其成果；不把「所有動作 review」解讀成必須刪掉所有舊動作。現有敵人黑衣人 index4 是相容回歸範圍，不改成第五英雄。

## 3. 四人的動作與戰鬥語言

以下招式中文為製作名稱；既有 move id／輸入／技能資源為實際串接基礎。普通連段形態可換，首版保留現行startup／active／recovery與平衡，若確需改規則另以有證據的玩法變更提交。

| 項目 | ZIP／疾扣 | RIVET／鉚釘 | HUSH／靜噪 | LOOP／迴路 |
| --- | --- | --- | --- | --- |
| 核心 | 近失閃避得ROUTE，變向貼身、命中確認追踢 | PRELOAD兩階預壓、承諾出拳與短暫指定霸體 | 正面parry取得SAMPLE，後撤、讀招截擊 | 兩接點、手動連線脈衝、短棍與空間管理 |
| 動作來源方向 | 跆拳道／街舞footwork；踢擊用完整髖轉 | 拳擊／重型brawler；下肢蹬地帶拳 | 精簡拳擊／詠春式短橋的動作參考，避免空舞 | 單手短棍／eskrima參考＋設備操作手勢 |
| 靜態剪影 | 斜身、高低腳交換、手收身旁、輕快前足 | 寬站距、拳在胸前、低重心、肩背厚 | 窄站距、低護架、頭肩小幅偏軸、穩定視線 | 右手持棍、左手控點、身體側開、保持棍尖清楚 |
| 重量與節奏 | 快收腿→短停→爆發；最少大幅上身擺動 | 先沉髖→壓拳→單次重爆→長回收 | 多數時間安靜；一次極短而清楚的接觸 | 點、點、線；節奏由佈點和手動觸發構成 |
| 明確弱項 | 單擊較輕，揮空不能自動追滿 | 慢起手長回收，空揮可被繞與反擊 | 無SAMPLE時回報較低，怕投與失誤讀招 | 要預先佈置，接點可拆，近身被壓有成本 |

### ZIP：踢技與路線

- J三段：前腳點踢（jab）→後腿橫踢（cross）→上挑踢（正式Rush第三段launcher）；legacy finisher另做轉身踢，不能混認現行連段。
- K挑空以支撐腳旋轉帶髖；heavy採短側踢。空中air_jab改膝／短點踢形態、air_kick展腿、meteor下壓腳跟；手臂維持平衡，不套雙掌砸地。
- E用側墊步／低滑步，不播翻滾；花ROUTE時加第二個清楚落足重音，不能變瞬移。
- L「急件簽收」兩套接續clip：首踢、真命中後追踢；揮空只收腿。W+L「末班快送」三擊分三個substate，空揮、被擋、被中斷都有退出。
- 勝出：鞋跟滑步停下、短點手勢、轉身離開；據點：靠牆換腳、整理鞋帶。

### RIVET：預壓與巨拳

- J三段：短左拳→身體直拳→上勾挑空；heavy為跨步重拳，legacy finisher為橫擺拳。全部以拳擊全身片段取代Sword_Attack，支撐腳與骨盆先到位。
- L「落鉚」分入蓄力、I循環、II循環、釋放、空揮回收；到階用肩背壓縮與腳跟沉下，不能只有拳套發光。保留既有最長36 tick、自動放拳及指定最後6 tick霸體契約。
- W+L「停工通知」雙腳錨定後一拳送出；不是ZIP踢技、不是全員共用雙掌砲。空中重擊改拳／前臂壓落；空中時不啟用地面foot lock。
- E為沉肩側踏；投技為貼身抱提短摔，需攻守配對資料。
- 勝出：拳套相撞、落肩、重步離開；據點：檢查拳套／壓工具。

### HUSH：留白與截擊

- J三段：短刺拳→肘／掌截擊→貼身上挑；不得把每次小拳都演成大仰身。heavy為停頓後直拳，air_kick仍保留短踢以覆蓋現行動作類別。
- 防守以肘線與小幅偏頭表現；parry是短撥而非雙臂大張。SAMPLE用手部短記號與局部殘像標記，取得與消耗都有可辨動作。
- L「留白」後撤踩穩→直線截擊；model不能一邊後撤一邊共用lunge前移抵銷。W+L「全場靜音」先收動作、瞬間切入、單次清楚接觸、停住回看。
- E為小幅slip／撤步，投技為撥臂借力轉摔。強化與未強化共用基本軌跡，但收勢／局部特效不同。
- 勝出：手到唇旁、回望、安靜離開；據點：聽耳機、點頭，小幅度循環。

### LOOP：短棍與訊號

- J三段：棍端短戳→反手橫敲→上撩挑空；heavy為踏步下敲。棍長、握點、手腕twist先校正；動作取短棍來源，不能直接用長劍砍劈。
- L近放點與方向+L遠放點各有手勢：抬棍定位→左手落點→回護架；S+L「交叉接線」短棍壓下才發脈衝，node_pulse不用Cross底片。
- W+L「安可迴圈」依節點數選0／1／2點演法；節點脈衝是真事件，鏡頭與光線按事件依序走，再呈現本體敲擊。無節點不顯示兩次假爆炸。
- 空中以單手棍擊、另一手平衡；E為交叉撤步，投技為棍身引開後推離，接觸點需與對手身高匹配。
- 勝出：棍尖畫小圈、收棍離開；據點：蹲修線路→起身→走到機器，不能在idle腿姿下平移。

## 4. 全動作覆蓋表：不可只重做L與大招

每格均要有錄影及審核狀態；可以複用合適來源，但四人的關鍵pose、節奏與輪廓須不同。

| 動作家族／現行id | 共用驗收 | 角色差異與處置 |
| --- | --- | --- |
| 戰鬥idle／呼吸 | 腳底穩、無明顯抽動、回到可出招姿態 | ZIP輕步／RIVET寬站／HUSH靜止／LOOP持棍 |
| walk／jog／sprint | stride對速度；加減速與停步銜接 | 四角各自前進與停止，不共用倒播 |
| 後退／轉身／換邊 | 正常與左右鏡像測試，不反轉膝肘 | 真後退、轉身clip；黑衣人原路徑相容 |
| dash／E | 位移與footwork一致，F2不改物理 | ZIP滑步／RIVET沉肩／HUSH撤步／LOOP交叉步 |
| guard／blockstun／parry | 拳套不穿頭、格擋後自然回架 | 四種護架與各自撥擋，不改友善窗口 |
| jab／cross／finisher | 打出、接觸、回收各有pose；miss也自然 | 腿／拳／短橋／棍；finisher覆蓋legacy路徑 |
| heavy／launcher | 支撐、力線、落點、起飛可讀 | 踢／勾拳／截掌／上撩，對應實際擊中點 |
| grab／受投 | 成對接觸、未抓到退出；不得拉遠處對手 | 腳絆／抱摔／轉摔／棍引推離 |
| jump squat／rise／apex／fall／land | 有蓄力與落足，不在空中鎖腳 | ZIP收膝／RIVET緊湊／HUSH克制／LOOP棍平衡 |
| double jump／chase | 接現有軌跡，避免8tick整模旋轉造成迷向 | 各自收身姿勢與追擊姿態 |
| air_jab／air_kick／air_finisher | 空中接觸相位、換招過渡、末段回收 | 腳膝／拳肘／短擊／棍敲；保留全部有效id |
| meteor／air_counter | 上下方向清楚，不套共用砸手 | 下踢／砸拳／短壓擊／下敲；反制hold與recoil成對 |
| special／overdrive／node_pulse | 多段、miss／block／hit、資源0與滿額 | 本文四套專用編排，LOOP獨有pulse |
| stun／空中recoil／撞牆反彈 | 受擊方向、落地、可控恢復 | 按身形調重心，不把普通招加反彈 |
| death／KO／落地屍體 | 沿既有skin最低點貼地，不卡半空 | 可保留合適Death來源，姿勢／比例逐角校正 |
| 選角／確認／回合登場 | 模型全身可見、轉場不跳pose | 從同一角色profile取showcase資料 |
| 勝出／離場／故事／據點 | 與戰鬥性格一致，手接物與腳底可信 | 修正程序步態，據點互動另設手部目標 |

現有12個角色進度節點多為既有招式／資源修正，不應當作12個全新全身clip；將perk／preload／sample／ROUTE／節點數納入變體覆蓋，不更名存檔id。

## 5. 素材庫分工與實際選用策略

2026-11-13從此雲端以正常HTTPS讀取以下四個官方入口，均回 `Tunnel connection failed: 403 Forbidden`。因此本節是依工具用途編排的**候選取得流程**；未核實今日目錄、價格、帳戶權益、特定商品內容或最新授權。不列虛構SKU，不聲稱已使用Mixamo包。實作時先用具可存取性的官方來源／合法帳戶取得一角樣本，再擴批。

| 來源 | 工作角色 | 優先搜尋／選片規格 | 不應誤用 |
| --- | --- | --- | --- |
| [Adobe Mixamo](https://www.mixamo.com/) | 快速取得基礎全身motion與可比較樣本 | boxing guard／jab／hook／uppercut、back step、side step、kick、jump／landing／hit reaction；這些是搜尋詞，非已核實clip商品名 | 不將所有免費／可下載動作當可再散佈原檔，完整combo也不能直接等於遊戲三連 |
| [AccuRIG／ActorCore](https://actorcore.reallusion.com/auto-rig) | AccuRIG為綁骨工具；ActorCore才是動作取得入口 | 先檢查現有rig；只有肩／肘／手腕變形不合格才在衍生副本重綁；ActorCore搜重拳／轉身／表演 | 不把AccuRIG寫成大型戰鬥動作庫；不覆寫四份原GLB |
| [Rokoko](https://www.rokoko.com/)／[Vision](https://www.rokoko.com/products/vision) | 動作素材候選＋補錄專屬表演 | HUSH撤步截擊、LOOP佈點／收棍、四角勝出／據點互動；先拿短樣本驗接觸 | 影片動捕不會自動修好鞋底、手握與棍接觸；仍需人工cleanup |
| [Fab／原Unreal Marketplace](https://www.fab.com/) | 尋完整風格化戰鬥套件而非東拼西湊 | unarmed boxing／brawler、taekwondo／kick、single stick／eskrima；優先同作者完整含idle、locomotion、hit、turn的包 | Godot不能直接用.uasset／AnimBP；須確認能合法匯出FBX及跨引擎使用，UE-only內容不錄用 |
| [Quaternius現有庫](https://quaternius.com/packs/universalanimationlibrary.html) | 已有可追溯CC0基底、缺件fallback與對照 | 合適idle／walk／jump／death可保留，先逐角驗收 | 不再用Sword／Spell底片硬拉所有徒手技能 |

首批取得目標：ZIP完整踢技＋footwork 8–12段；RIVET完整拳擊8–12段；HUSH撤步／parry／直拳6–10段；LOOP單手棍／手勢6–10段。這是選樣量，非最終總量或採購承諾。每人最後約30–40個motion entry（含共用合格來源、子段及變體），預估120–160 entry；獨特來源clip數在選樣後統計，不把entry當購買數量。

每候選記錄：官方URL、作者、asset id／版本、取得日、授權全文／憑證、帳戶持有人、可用引擎、是否可修改、是否允許原始檔進公開GitHub、來源SHA256、骨架／FPS／root／contact資料、導出衍生hash、錄用／拒絕理由。**本repo公開**，允許成品遊戲使用不等於可公開付費FBX或可還原曲線；商業來源留授權合規儲存，repo只放可公開資料／manifest與重建說明；衍生動作也需同樣判斷。

選樣評分：全身重心25%、接地20%、contact與可重定時20%、風格吻合15%、銜接覆蓋10%、清理成本10%。授權／格式為先決條件；總分提案≥80才錄用。先對同一招試兩個候選，避免買完整包後才發現無法用於Godot／公開repo。

## 6. 導入與動畫架構

1. **保留原件**：四個source GLB byte不變。衍生rig與蒙皮修改各有版本；不因AccuRIG存在就重綁。先以抬臂、深蹲、扭腕、單腿支撐、拳套握拳5種測姿核對65骨、roll、權重、手指與大型鞋／拳套。
2. **統一轉接基準**：Blender中建立明確A/T reference pose與canonical humanoid映射；逐角rest offset、骨長、hips高度、肩／腕軸校正。無法直接相容的來源只離線轉接一次，避免執行時連續跨rig修正。
3. **離線清理**：完整骨盆／脊椎／腳掌曲線、膝肘pole、手腕twist與短棍握點；刪除不需的camera／mesh／scale track。支撐腳接地marker、攻擊limb與棍尖marker、投技配對marker皆人工核對。
4. **資產輸出**：優先Godot可匯入的GLB／AnimationLibrary；FBX先在DCC轉換並驗單位／正向。若保留現有JSON sampler，擴充版本化格式及對照測試，不硬套僅rotation＋hip-y的舊格式。來源60fps品質烘焙，30fps候選需接觸品質驗收，最終運動仍沿60tick simulation。
5. **資料化選片**：新增每角motion profile（設計提案），key含character id、move、subhit、ground／air、resource tier、phase；每項含clip、contact、plant、release、blend-in/out、loop、root policy、mask、fallback。不是只在程式加入更多character==分支。
6. **唯一動作owner**：全身base → 小幅上身additive（有mask）→ 受擊校正 → 有界foot／hand IK → 短smear。死亡／成對過場有明確互斥所有權；新profile啟用後移除同部位legacy `_aim_limb`，Neon只掌演出意圖與既有畫面owner，不再另改全身骨骼。
7. **時間與命中**：attack由實際f.frame與move_data分段取樣；原clip contact映到active開頭。多段ZIP以subhit／attack instance識別，避免同move第二擊仍延續第一擊clock；RIVET蓄力loop與release分開。取消從當前pose短blend，但不能把5tick jab整段blend掉；起手過渡提案1–2tick、idle／步行4–8tick，按片調。
8. **root與接地**：simulation唯一掌x／y／朝向／傷害；動畫in-place，DCC root用於測stride與有限visual offset。foot lock只在marker接地窗內，空中／dash出地／被投／KO flight立即解除；pelvis補償提案上限0.05–0.08遊戲單位，不拉長腿追地面。0.45m等共用lunge重測並逐招縮限。
9. **事件與VFX**：腳步聲／煙跟plant，揮擊弧跟正確拳腳／棍尖，接觸爆點只跟真hit／block／parry。風聲可在揮空播，命中聲與強閃不能播假命中；節點pulse按實際事件位置顯示。
10. **多場景採用**：先接正式FIGHT同一套visual，隨後故事／SQUAD／練習／Demo／選角／登場／勝出／據點，各自鏡頭director只要求動作。據點固定投影美術不變更成新相機系統。

## 7. 戰鬥畫面、鏡頭與聲音要有四種風格

| 層 | ZIP：路線切片 | RIVET：工業壓印 | HUSH：留白切割 | LOOP：訊號接線 |
| --- | --- | --- | --- | --- |
| 主形狀 | 沿鞋尖的短斜線、折線、窄踢弧 | 厚塊、扁衝擊、地面短塵壓 | 細直切、局部負空間、單一小爆點 | 棍尖短方波、端點方塊、清楚連線 |
| 色／材質 | 既有青綠，少量白色鞋邊 | 既有橙色，黑厚邊與亮接觸核心 | 既有桃紅，黑白留白，少粒子 | 既有黃綠，節點低亮、觸發才亮 |
| 軌跡／殘像 | 沿真鞋骨短尾，快入快出 | 主體少殘像，拳接觸一瞬厚形 | 一個精簡前pose／後pose，回收乾淨 | 沿棍尖socket畫短軌跡，非整身拖尾 |
| 鏡頭 | 水平短跟隨與方向切，保持落足 | 較低機位、沉下再撞、單次回彈 | 少移鏡；接觸才一次短推近 | 優先讓玩家與節點同框，按真pulse巡視 |
| 大招構圖 | 三次方向重音，末踢終結 | 蓄勢寬肩→巨拳壓滿局部畫面 | 收景留白→一次切入→安靜停住 | 節點依序響應→本體擊，0點版更簡短 |
| 聲音 | 鞋擦、窄風切、乾短踢擊 | 低頻機械預壓、厚拳、重量落足 | 短呼吸／小撥擋、乾淨截擊；僅短duck | 棍身敲擊、接點click、脈衝依序短音 |

普通招禁止每擊全屏遮幕；full-screen仍沿Neon唯一owner。角色色表達身份，P1/P2額外用輪廓／腳下小標辨識，鏡像同角不能靠換色作區分。沿現行960×540／nearest與現用VFX來源，所有新線／貼圖在最終viewport檢查像素密度，不復活退役噪聲圖集。

BGM持續播放，只沿既有duck owner短降音量；F2降低閃白／甩鏡／變形／殘像，必須保留可讀角色動作及真玩法。群戰最多六存活場景沿現有優先池，重要招式給前景額度、遠景減少裝飾，不疊四套全屏效果。

## 8. 製作里程碑與交付

以下是單一熟練製作者的粗估工作日，非承諾交期；素材取得、授權與重綁若有問題須重估。

| 階段 | 工作量粗估 | 具體交付／通過門檻 |
| --- | --- | --- |
| P0 全角基準review | 1–2日 | 四角全部動作家族的現版短片，側面／斜前／鞋底近景；特效on/off；issue表列接觸幀、腳滑、穿模、層衝突；每段≤15秒 |
| P1 素材選樣與rig驗證 | 2–3日 | 四庫取得／授權狀態、兩候選對比、四角測姿、每角1個走步＋1招＋1防守重定向；先驗最難的RIVET拳套與LOOP棍握 |
| P2 動畫管線與一角切片 | 3–4日 | 每角profile契約／marker／root策略；先RIVET做idle、前後步、jab→cross→launcher、L兩階釋放，關特效亦自然 |
| P3 四角完整招式 | 6–10日 | ZIP追踢、HUSH取樣、LOOP節點與短棍；四角全部表列動作含空揮／被擋／中斷／死亡；不只新增測試教室 |
| P4 分角VFX／鏡頭／聲音 | 3–5日 | 各角同一場景before/after、有聲≤15秒片；大招各1片；減少特效對照；真骨骼／事件同步 |
| P5 場景與回歸收尾 | 2–3日 | 正式1v1／鏡像／六人群戰／Boss／選角／登場／勝出／據點、暫停F2重開退出；真人與Mac待實際裝置驗收 |

合計約17–27工作日；若要高完成度四套全動作，不能把下載幾段clip視作整輪完成。每階段只在成果通過後擴展；每輪驗證後commit／push任務分支，PR具體列已完成與待辦，不自動發Web或合main。

## 9. 驗收方法與停止條件

**自動可量測項目（擬定標準，先用P0量測校準）**：

- 只在plant窗且非移動／空中事件下量鞋底：滑移≤0.02m、地面高度誤差≤0.015m（以專案1單位≈1m估算，按角色尺度正規化）；鞋幾何最低點比只看Foot骨更可信。
- contact marker與實際active起點差≤1 simulation tick；各段動作接觸肢體必須朝對手／正確高度。近／遠／極限距離同時錄，不能以整身前移掩蓋短手。
- 短棍握點與手socket距離≤0.02m；tip軌跡連續，棍不穿自己身體。投技只在真grab成立後對齊雙方pose，不能延伸判定。
- 新動畫版本相同輸入seed的simulation events／HP／meter／resource／KO／存檔一致；若有玩法調整要獨立說明，不能偷偷放寬命中。
- hitstop／pause時攻擊pose不前進；R／F2／離場後無殘留IK、手腳scale、鏡頭roll／FOV／duck；高速連按／同move續段不殘舊姿勢。

**必須用動態目視／真人判斷的項目**：

- 四角各選idle、前後步、三連、L、W+L，關特效與灰階盲辨；初始目標熟悉玩家辨識≥80%，實際人數及結果記錄，非程式測試可替代。
- 慢速只用來找問題，正常速度必須有準備→接觸→回收；檢查單腳支撐、力線、肩胯反向、左／右側與被打斷過渡。夸張pose可保留，但不能無意關節翻折或靠膨脹遮錯。
- 每角每招：hit／block／parry／miss、地面／空中、左右朝向；另測preload0/1/2、SAMPLE有無、ZIP首擊miss與續段、LOOP0/1/2點／被拆。故事裝備／天賦不得改壞姿態或遮讀招。
- 效能用真目標硬體錄CPU/GPU幀時間與99百分位，提案60fps／16.7ms；Linux llvmpipe錄影只能看流程，不能宣稱Mac效能通過。

停止條件：P2尚未解決腳滑或接觸層衝突，不進P4大量特效；素材授權／格式不合格則淘汰而非硬轉；一角完整動作未通過，不把四角「都有新特效」當完成。

## 10. 下一輪第一個可 review 的實作範圍

先做P0量測與P1樣本，接著在正式FIGHT做RIVET「站穩→預壓→一拳→收勢」切片。它同時驗證目前最明確的Sword底片錯用、special蓄勢覆寫、巨拳變形、腳底滑行與真命中同步。通過後用同一管線做ZIP踢技，再HUSH截擊及LOOP短棍。第一輪不以調色或全屏演出冒充動作修復。
