# 正式戰鬥VFX重製

2026-11-12。使用者已要求實作前輪全部戰鬥VFX方案；本頁覆蓋COMBAT_VFX_QUALITY_PLAN及SEPAK研究的「只有規劃」狀態。改動直接接正式FIGHT、既有Demo、Street Run及SQUAD；沒有新增遊戲模式或更改判定。

## 畫面與試用

[12秒有聲前後對照](evidence/ink-fx/comparison.mp4)／[新版](evidence/ink-fx/after.mp4)／[原版](evidence/ink-fx/before.mp4)。前6秒ZIP/RIVET、後6秒HUSH/LOOP；固定輸入來源為原有雙AI，普通有限生命、兩段獨立樣本，刻意略過入場從fight開始。30fps Movie Writer，每渲染幀推進兩個1/60 wall步，實際捕獲360幀＋引擎混音。不是硬件30/60fps證據，也未作真人實聽評分；對照片音訊只用新版，避免兩軌疊播。

F5開啟現有遊戲，FIGHT看正式對局，F12看原有AI Demo；F2比較減少效果。SQUAD照原選角入口進入；沒有更新公開Web。原始角色GLB／貼圖、音樂檔、傷害／能量／AI／hitstop規則均保留。

## 已接入甚麼

- **世界腳塵**：步行／跑步以真實位移距離去重，取當前較低鞋骨的接地位置；同事件播放步聲。每0.72m為暫用步距，不冒稱已新增動畫contact marker或足底IK。靜止、停頓、空中／倒地不連續噴腳塵；F2仍保留步聲。
- **不同運動配方**：dash後甩、轉向／煞停、起跳、普通落地、正式air_land及hard落地／ground_bounce、牆碰撞。空中dash改為小wake，不在地面憑空生煙。
- **作者化硬邊煙塵**：12個可編輯尺寸／壽命配方，共用6個不對稱輪廓、非等時持幀、3種鏡向／輪廓變體；18份預建mesh，不是12套獨立手繪貼圖。白／深墨雙層輪廓及受擊高速wake形成短煙尾。原環境蒸煙保留，戰鬥塵不再用原規律六方塊代替。
- **真骨骼軌跡**：五選角hand/foot socket快取，骨骼缺件才以比例降級；按已更新姿態取樣短ribbon，僅active附近追加，按attack serial中斷；空揮有motion但沒有contact。群戰追蹤使用各自id，非焦點敵的效果不會被錯誤綁到新焦點。
- **接觸核心**：由真hit驅動，使用攻擊手腳點與防守者身體區域的呈現交點；這仍是視覺近似，沒有新增物理碰撞接觸求解或改命中範圍。命中核心世界位置固定，角色飛走後不黏胸；短不對稱尖星、方向碎片取代多數規則同心釋放環。
- **分段弧與角色差異**：ZIP短斜切／斷弧，RIVET較厚，HUSH細直線與留白，LOOP較多分段；大招沿四角原招牌形，ZIP大招弧也拆片。黑衣人保留可讀的共通配方。
- **閃光與防守**：hitstop中的核心固定一張，不再fmod輪播；局部接觸亮核按wall time約65ms消退。受擊材質最強閃約45ms後退為弱對比，不會在長頓幀中持續全白；Neon actor shader保留輪廓與原衣服色塊。普通格擋是短盾弧，parry是分離尖刺，與命中區分。
- **聲畫重音**：既有CC0打擊／低頻上疊原創45ms snap／90ms scrape，四角音高不同；75ms共用接觸層預算防止同tick多敵疊滿。沿原SFX bus／limiter／mute；BGM仍由原owner連續播放。
- **鏡頭與背景**：減少常態高頻shake，加入小幅沿真命中方向的單次衰減反衝；沿原Neon優先序、signature取景與KO owner，不再疊另一個全屏導演。Neon環境shader在戰鬥焦點附近壓低背景對比，強接觸稍加重；天空、角色與HUD分開，退出／F2／過場還原。
- **群戰與池**：世界煙池36，裝飾最多18，重要煙可替換裝飾；骨骼短尾最多32；原Canvas效果仍24，先淘汰低優先裝飾再接命中／parry。遠敵短尾較細、煙較小。環境18＋12及過場64仍是其他池，不能把36當全遊戲總粒子數。
- **生命週期**：pause凍結age，F2清煙／ribbon／強閃／新反衝但保留必要命中提示；R、F12、回標題、換模式、群戰退出及CityBreaker交接清理。沒有Engine.time_scale、來源模型覆寫或第二套傷害權威。

## 程式與美術來源

- scripts/combat/ink_fx/fx_recipes.gd：原創輪廓、12配方、持幀與優先序。
- scripts/combat/ink_fx/world_ink_fx.gd：世界mesh池、足塵／短煙、接觸提示、骨骼ribbon及背景focus。
- fighter_visual.gd：骨骼錨點／短閃；impact_shapes.gd及fight_vfx.gd：分段弧、接觸與防守形狀。
- fight_session.gd／fight_hud.gd：正式事件與繪製整合；fight_audio.gd：可重建的程序PCM短層。
- shaders/neon/neon_actor.gdshader及neon_environment.gdshader：局部受擊與環境對比。project.godot新增兩個預設為0／中立位置的shader globals。

這輪新增素材全部是程式內原創可編輯幾何／PCM，沒有購買資產、沒有把SEPAK或LLB畫面／角色／聲音放進runtime，也未恢復退役噪聲圖集。沒有需要另生成的角色／場景3D模型；煙塵由預建3D網格直接渲染，符合現有360p硬邊美學。

## 驗證

Godot4.6.3 Linux Compatibility／Mesa llvmpipe，音訊Dummy；不是使用者Mac測試。最終相關集合420項通過：新FX26、strict14、基本戰鬥34、Rush21、友善防禦25、群戰規則35、正式玩法45、四角能力46、原生群戰10、回合24、混音6、裝備113、Neon21。沒有把重複的最初strict8再加到總數。

- 新FX測了靜止／移動、空中、正式air_land、揮空／真命中、接觸點、長頓幀不重閃、pause、F2、池飽和保護parry、五角雙朝向、所有招式cels多邊形可三角化、群戰id／退出及材質退休。
- 1,800個步進的逐步位置／速度／狀態／生命／資源及事件，基線46ae3e3與新版SHA256同為c0812b7f2e87cc8762d12f38d65036ddfc96675009128175c8d6a80986c187e4。這支持呈現層不改該樣本玩法，並非所有可能輸入的形式化證明。
- 兩組6秒電影樣本前後真命中均7／11。影片AAC解碼有非零音軌、peak約0.507、無>=1樣本；另引擎混音6項確認音樂持續、mute、恢復及不削波。不聲稱已用喇叭聆聽或評價混音品質。
- 舊fixture已修正：Easy勝出實測tick698，整局預算600→900但首次接觸仍限制120；Neon允許正常有限生命進result；回合驗證接受已實裝裝備段替代多餘第三局入場，並固定seed。不改遊戲規則配合測試。
- 初次headless裝備測試等frame_post_draw超時，改原生113項通過；初次未等真離地的jump fixture修正。原版舊Neon／Rush與回合失敗已保留基線紀錄；最終accepted詳evidence/ink-fx。

效能：此片在軟體GPU實際錄製約37秒得到12秒／360幀，不是即時30fps；sample draw calls峰值594，基線590。CPU／GPU數值包含軟體驅動與錄影成本，不作目標硬件提升百分比。目標Mac、真人閱讀／手感／實聽與長時間多人GPU p95仍待覆核；未把原計劃1–2ms FX預算寫成已達標。

## 尚有甚麼限制

LLB新附件仍超過32MiB讀取上限，所以沒有該片特定逐幀結論；它不阻止本輪已核實SEPAK方向與正式效果實作。沒有新增未授權的六關／Boss／故事波次。普通動作仍沿既有動畫與伸縮，腳步仍用距離備援，未新做逐動畫marker／足底IK或全面重畫模型動畫。

完整步驟：F5→FIGHT觀察普通走跑、dash、起跳、落地、J連段、K挑空、L及W+L；Shift觀察block/parry；F12看四角搭配；SQUAD檢查多人；在有煙／強招時按Esc／F2／R／返回。上述Mac／真人項目是待驗收，不宣稱已完成。
