# RIVET 第一輪動作切片

2026-11-13，接續[四角色製作方案](FOUR_FIGHTER_MOTION_REVIEW_PLAN.zh-TW.md)。基線 `45bb063`（規劃）／main `7aac2c1`。這輪已改正式共用FighterVisual，不是新增獨立教室；範圍是RIVET的地面靜止護架與jab／cross／heavy／finisher／special五個move id。沒有把整份四角計劃當作完成。

## 已實作

- 新 `last_service/rivet_motion.gd`集中記錄選片、接觸／回收相位與地面姿態所有權。沿用已有CC0 Quaternius Punch_Enter／Punch_Jab／Punch_Cross；未下載或冒稱接入Mixamo／ActorCore／Rokoko／Fab商品。
- 原本RIVET cross／finisher／special會選Sword_Attack，再被共用踢技／特殊姿勢覆蓋。新切片改採拳擊片段，這五招不再經過那些骨骼層；Neon尊重完整pose owner，不把打出的拳拉回蓄勢。未涵蓋動作仍沿原路徑。
- 地面髖與腿取Punch_Enter的固定站姿，手／脊椎沿真拳擊曲線，移除這組動作上的共用model前移、1.0–1.4空中變形、2.1倍肢體scale及hitstop抖動。這是**固定站姿來源遮罩，不是地形foot IK**，也尚無完整骨盆轉髖、步進重拳或自然呼吸循環；後續素材要補這些表現。
- 預壓由simulation反覆使用的frame7/8取同一load pose，避免兩幀交替抽動；階級以小幅load取樣差異表現，釋放才走到contact，再回收。attack serial區分同move的新一輪；短招blend縮至.025秒。數值、能量、霸體與真傷害規則不改。
- 死亡、空中、大招overdrive、挑空launcher、移動、防守受擊／blockstun、選角showcase及過場保持其原有owner；新護架只覆蓋地面靜止idle，包括其既有guard輸入。未聲稱這些家族已重製。

## Review與畫面

[證據索引](evidence/fighter-motion/README.md)包含：

- 四角×22動作類別×90tick的固定root呈現抽樣，每段0／24／55tick原生截圖。接地資料量的是Foot骨socket；不能把骨頭靜止當成鞋底貼地／真人步行通過。
- [RIVET前後對照](evidence/fighter-motion/rivet-comparison.png)：舊版特技與抬腿覆寫已換成站穩出拳。固定tick24對某些短招已是回收，並非所有欄都在接觸瞬間。
- [12秒有聲原生片](evidence/fighter-motion/rivet-motion.mp4)：三段重設練習fixture，各用一次正常L按／持／放，3次真命中；經session command路徑，無傷害注入。實際PRELOAD事件記錄見movie.json，並不宣稱三段必然各為0／1／2階。Linux llvmpipe Movie Writer，360幀／30fps，錄製約67秒，非真人或硬體FPS驗收。

逐角全動作動態／接地與配對投技仍未完成。這輪P0是可重現的抽樣工具與首批資料，P2是RIVET有限地面切片；P1官方來源研究有進展，但帳戶素材尚未取得。

## 驗證

- 19項新原生檢查：五招有限骨骼、固定站姿、取消舊抬腿／放大、真hold至二階及釋放、7/8幀穩定、左右朝向F2／hitstop、受擊／死亡／空中／選角交還owner；全部通過。
- 46項現有角色機制、104項死亡貼地／群戰回歸；全部通過。
- 相同1800步兩組角色固定種子，修改前後完整玩法trajectory SHA256同為 `6de1a9657cab5320d3bffe0c1e4ff2057ee5080a0c71efee7bd82c0f4754d591`，事件計數亦相同。四角抽樣中ZIP／HUSH／LOOP所有骨socket資料相同。
- 五招固定root抽樣在tick10之後，左右Foot骨相對首樣本最大位移由舊版約0.32–1.93單位降至0（按各招／腳不同）；此指標包含舊版刻意抬腿與視覺前移，**不等於量測出1.93米實際腳滑**。未量鞋幾何與地形誤差，不能當foot IK完成。
- 四個本輪runtime腳本在七類warning當error的獨立設定下均編譯通過。全專案原19腳本strict套件為15/19，未改動基線也同為15/19：開場stage、現行sprite/world FX、據點reference workshop的既有warning導致4個上層腳本失敗；保留前後log，不為此輪修改無關美術。
- 新原生檢查／抽樣／錄影／玩法probe與既有規則／死亡測試accepted log無ERROR或SCRIPT ERROR。初次測試缺匯入快取，已執行editor import後再驗；headless不是畫面證據。Mac／真人／正式素材完成度仍待驗。

## 外部來源狀態更新

上一輪shell HTTPS對官方網域回proxy403。這輪可透過可用的Web工具查閱以下官方頁，這不代表已登入帳戶或取得下載權：

| 來源 | 本輪已核實內容 | 接續處理 |
| --- | --- | --- |
| [Adobe Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) | Adobe ID可用；人物與動作可用於商業遊戲；人形／模型條件有要求 | 帳戶選樣，公開repo原始動畫再散佈須另核對，不能從他人repo拾取不明Mixamo檔 |
| [AccuRIG官方](https://actorcore.reallusion.com/static-page/auto-rig/pre_page/accurig/accurig.html) | 自動綁骨工具與角色重用流程 | 原65骨先保留；只在測姿失敗的衍生副本重綁 |
| [Fab Boxing Animation Pack](https://www.fab.com/listings/6cc14b2c-2383-45bf-a8f4-6f890b76487d) | 商品列67動作，含Basic Guard、Walk Forward／Backward、Jab／Cross、Uppercut與parry，列FBX格式 | RIVET／HUSH優先候選；價格／個別授權／帳戶取得及公開來源放置尚未確認，未採購 |
| [Rokoko Motion Library說明](https://support.rokoko.com/hc/en-us/articles/4410021327121-Getting-Started-Rokoko-Studio-Motion-Library) | 需在Studio瀏覽與取得motion資產 | 補HUSH截擊／LOOP手勢與勝出表演；未裝Studio或取得商品 |
| [Quaternius UAL2官方](https://quaternius.com/packs/universalanimationlibrary2.html) | 新庫有combo／分擊片段，CC0，支援Godot | 公開repo相容候選，可優先取得試片；尚未導入，現用仍舊19clips |

## 下一輪

先取得完整拳擊／踢技選樣，補RIVET前後步、launcher／overdrive及重心轉移；再沿同一資料契約做ZIP踢技、HUSH截擊與LOOP短棍。當前固定腿站姿解決層衝突，不能代替最終全身動作。原四GLB、現用判定／進度／BGM不變，公開Web未更新；僅推任務分支與draft PR。
