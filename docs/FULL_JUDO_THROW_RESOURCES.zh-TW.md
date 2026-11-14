## 2026-11-14 最新：兩個使用者FBX已收到，原始配對可共同播放

使用者已提供Aggressor（施技者）及Victim（被摔者）。兩段實測65骨、同名同序、30fps、1–201幀／6.667秒跨度，root位移保留；原座標同幀骨架預覽可見入身、轉肩、對手離地倒轉及落地。見[evidence/judo-source-pair](evidence/judo-source-pair/README.md)的6.70秒影片、詳細／完整時間軸抽格及SHA報告。沒有人工重定時或各自置中，非僅目錄推測。

這是來源骨架配對檢查，不是手掌／皮膚接觸或四角Godot驗收。原片首幀髖距4.415m，含走近；需兩段共同裁切（46–121幀只候選）、近身root與身高差接觸處理，再接simulation共同時鐘／落地一次結算。原FBX與逐幀曲線不進公開repo，工具可重建私有檢查資料；本輪不需MCP登入即可處理已上傳檔。下文「未取得FBX」是歷史，由本節覆蓋。完整摔投仍未正式接入。

## 2026-11-13 接續：網路已生效，官方配對與預覽已核實，待Adobe認證

本次是同一設定下的新執行個體；讀取status為unrestricted／enforced且observations_current=true，已實際連通Mixamo。未帶API key的403是官方JSON「Api Key is required」，不是proxy拒絕；使用上游公開X-Api-Key後官方目錄HTTP200。核實Shoulder Throw, Aggressor（c9c7a795-b96c-11e4-a802-0aaa78deedf9）與Victim（c9c7a914-b96c-11e4-a802-0aaa78deedf9）。兩段官方GIF各6.6秒，完整時長2fps抽樣已檢視：攻方轉身俯身過肩及收招，守方離地翻轉、背部落地及地面收尾。不是雙人對齊播放，root／接觸／落地幀仍未量測；未下載FBX、未接Godot、完整摔投未完成。

指定上游6170d5e／SDK1.30.0已在本機私有runtime重建，pip check、實際launcher initialize／六工具通過。未讀到token檔、環境無認證綁定；MCP auth與search明確回未認證，isError=false亦不算搜尋成功。公開目錄查證是獨立官方HTTP請求，不冒稱MCP搜尋成功。證據：[official-pair.json](evidence/mixamo-mcp/official-pair.json)。

launcher新增可選MIXAMO_ACCESS_TOKEN環境秘密，只交給client建構子記憶體使用，不寫token檔、不經mixamo-auth參數；未設定時沿用同主機私有~/.mixamo_mcp_token。使用者可在環境設定的秘密欄位配置MIXAMO_ACCESS_TOKEN並套用到執行環境，勿貼聊天。實際新憑證尚未提供／驗證；佔位值本地檢查確認只入記憶體、不落檔、不連網。後續先驗真認證，再同角色／30fps／完整root與時長下載兩段到repo外量測，不以GIF當FBX或曲線來源。

本次來源分支codex/four-fighter-motion-plan，基線c766a61；PR #29已合併是歷史，本次提交不在該PR內。原GLB、Godot、main與Web未改。以下網路403與舊runtime紀錄保留為歷史，由本節覆蓋目前狀態。

# 完整柔道摔投：資源核對與接入方向

最新工具進度：[MIXAMO_MCP_SETUP.zh-TW.md](MIXAMO_MCP_SETUP.zh-TW.md)。官方Playwright MCP已在雲端安裝並實測25tools／開頁／點擊；Mixamo仍被proxy403擋住，官方動畫檔未取得。以下保留前輪瀏覽器故障及資源研究歷史；完整摔投仍未完成。

## 最新約束：只用免費資源，先核實Mixamo

使用者其後明確要求「用免費的資源做」，並追問Mixamo。付費候選不再是實作採購方向。優先檢查`Shoulder Throw, Aggressor`與`Shoulder Throw, Victim`：第三方目錄索引列出這組名稱，但本輪未從Mixamo官方下載／確認兩段實際同步；不能把索引當成已取得的官方資產。Adobe官方FAQ確認Adobe ID免費、允許遊戲商用；免費不等於CC0或可任意公開原檔。

本輪瀏覽器兩次啟動均失敗（the gaas-browser node_repl sandbox cannot be disabled），沒有可操作的官方登入會話；官網文字讀取及公開目錄請求也未取得動畫內容。沒有下載第三方Mixamo鏡像，沒有購買或新runtime變更。若由使用者提供官方取得的兩個FBX，應使用同一角色／FPS、保留完整root motion、不各自裁剪；先量測配對對齊與接觸／落地幀，再開始正式接入，不能假定原始兩段起播／長度相同。

其他免費查核：SFU官方頁明示只限研究、禁止商業產品，未採用；Haley Tuffles作者頁明示免費自由使用並有Grapple Throw Down，但沒有核實完整攻守配對，直接下載被環境網路403拒絕，未取得檔。已核實的既有CC0曲線仍可用，但不取代優先查清Mixamo的需求。以下保留較早付費研究作歷史，未採購／未錄用。

查閱日期：2026-11-13。使用者最新要求「完整摔投，打哂圈，真係柔道投技般」，並要求網上找動作資源。目標為攻守雙人抓取、破壞重心、轉髖／轉肩、對手離地翻身、落地受身與分離；上一輪grab手勢／擊退結算不代表完成摔投。

本輪只做資源研究及需求更正，runtime沒有修改。已核對官方產品清單／格式標示與公開授權，取得官方影片連結；未逐幀觀看預覽、未購買／下載動畫、未檢驗FBX／GLB骨架與雙人同步，也未完成摔投接入。候選不是已錄用資產。

## 優先候選

### 1. wemakethegame：Judo AnimSet

- [Fab產品頁](https://www.fab.com/listings/c2a40d77-1e8f-49e1-9d02-48a597a73e22)／[官方預覽](https://www.youtube.com/watch?v=LHKp7QiC4MI)／[Unity商店](https://assetstore.unity.com/packages/3d/animations/judo-animset-215958)。
- Fab清單明確為攻擊方`atk`與被摔方`hit`，有Setmotion01–08共8組配對；另有grab、fall、rise、roll與移動，標示47 animations＋9 poses。
- **第一個柔道風格評估候選**。配對齊全，比單人Throw或原本抓取手勢更切合目標；八組的具體招式與旋轉幅度仍需逐段看預覽，不能由Setmotion編號猜招名。
- 格式頁標UE／Unity，不等於已確認提供獨立FBX。取得前應確認原始FBX或能合法從套件匯出完整骨架動畫；不能把uasset直接當Godot動畫。作者FAQ站本輪回502，該站技術細節未讀取。
- Unity產品頁查閱時顯示$131.99、Single Entity、v1.13；Fab價格需選授權，本文沒有把Unity價格當Fab價格或成交價。

### 2. Raise Creation：Grab & Throw Takedown Animation Pack

- [Fab產品頁／預覽入口](https://www.fab.com/listings/23c75ad8-7c73-4e5d-bb62-18d0e01e5585)。
- 產品頁標示46+動畫、每個takedown有相應`_React`；列出`HipSweep`、`BackThrow`、`RearArchDrop`與`RollFlip`、`RollOver`、`RollToss`、`SpinOver`、`TumbleLaunch`等配對。
- 格式明確列FBX及UE。**誇張翻圈／背摔／翻滾方向的候選**，亦較直接符合Godot素材管線；不把所有摔角／特技動作稱為正統柔道，實際接觸品質與旋轉仍需看影片及原檔。
- 公開頁價格需選授權，沒有核實數字；本輪未購買／下載。

### 3. Player Motion：Judo／雙人配對動畫

- [Judo目錄](https://playermotion.games/animations/judo)／[配對格式說明](https://playermotion.games/answers/two-person-fight-animations)／[商用授權](https://playermotion.games/license)。
- 目錄列Ippon-seoi-nage、Harai-goshi、Sumi-gaeshi；配對說明亦列Tomoe-nage。供應商說明每對分為兩個角色檔與SCENE.json，同時起播、相同時長；可選FBX／GLB、24／30／60fps。
- 供應商明確自述以Blender／自有工具逐幀製作，**不能標成真人mocap**；本輪沒有獨立驗證其動作質素，宜先試一組，不先把整包列為錄用。
- 查閱目錄顯示52招／$66.56、單招$2.89；其他被索引頁出現51／60等不同數字，購買前要看實際清單與結帳，不能視為一致固定規格。
- 直接個別招式URL未能經本輪工具讀取；核實範圍是目錄與配對／license頁，不是單招原檔。Standard License的營收／資金門檻及禁止散佈原檔以當次條款為準。

## 免費庫核對結果

- [Adobe Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)確認Adobe ID可免費使用，包含遊戲商用；Mixamo公開首頁無可讀目錄，本輪未登入核實指定攻守摔投片段。因此不把第三方鏡像中的Shoulder Throw檔當成官方已取得、已配對或可公開散佈素材。
- [Rokoko 13 free fight](https://www.rokoko.com/resources/rokoko-mocap-13-free-fight-animations)與[6 free martial arts](https://www.rokoko.com/resources/rokoko-mocap-6-free-martial-arts-animations)確為FBX／Mixamo骨架／30fps及商用頁面，但沒有核實含完整雙人柔道摔投，不以「fight」標籤代替配對證據。
- AccuRIG是綁骨／檢查與套用動作的工具；本輪沒有從ActorCore官方核實到具體可交付的雙人柔道包。沒有為填滿品牌清單而聲稱找到或接入。

## 真實動作參考：與素材授權分開

[IJF巴投Tomoe-nage](https://judo.ijf.org/techniques/tomoe-nage)及[IJF大腰O-goshi](https://judo.ijf.org/techniques/O-goshi)提供技術影片／3D動畫觀看入口，可用來判斷翻身、髖部支點與落地是否合理；**觀看參考不代表可下載重用其動畫資產**。背負投、髖摔與巴投可作第一輪招型方向，四角的最終分配待選定配對來源與預覽確認，不假定Setmotion序號與招名對應。

## Godot與本repo的接入約束

- [Godot官方格式文件](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)：支援glTF／GLB與FBX（ufbx），但格式可讀不等於雙人接觸自然或retarget成功。
- 需要同一組攻守動作的完整root位移／旋轉、髖高、相對起點與共同時間軸。現有站立管線會忽略水平root、限制髖部垂直偏移；不能原樣套在摔投上，也不能以獨立播放兩條單人動作或整個模型轉圈取代配對。
- 先做一組真雙人樣板：合法抓中→配對對齊→轉髖翻摔→落地標記一次結算→受身／起身→解除抓取。由simulation掌管配對狀態、目標、根軌跡與一次結算，presenter只讀；暫停、F2、死亡、中斷、重開／退出及群戰須解除雙方鎖定。
- 四角／黑衣人體型不同，另需手到衣領／臂／腰的接觸調整及骨架重定向。先驗一組，再擴招型／雙朝向／不同對手／牆邊，不能只驗攻擊者單模或fixture傷害數字。
- [Fab Standard License摘要](https://www.fab.com/eula)允許相容工具與商用遊戲，禁止將資產獨立散佈；Player Motion亦禁止散佈可重用原檔。本repo為公開來源：付費FBX／GLB及可還原動畫曲線不直接commit上傳，採私有資產目錄／私有依賴與公開匯入清單。實際購買的license及條款仍須核對，不把付費包當CC0。

## 下一步與目前界限

1. 首先對Judo AnimSet的官方8組預覽確認哪組有完整轉肩／轉髖翻摔；若要更強翻圈，再評估Grab & Throw的RollFlip／SpinOver配對。
2. 確認可用原始格式、配對根軌跡、取樣／接觸／落地幀與授權後，取得一組素材並做雙人retarget樣板。此步尚未執行，沒有任何購買或聯絡賣家的操作。
3. 真樣板可審核後，才擴四角專屬摔投與正式模式。未完成前，保留現有grab可玩行為，但明示為過渡手勢，不宣稱已達使用者完整柔道投技要求。

工作來源基線0267f14；本輪讀取遠端main為3915c2d，未合併main，也未更改遊戲／原始素材／公開Web。只做文件與候選登記，未重跑前輪674 runtime檢查，不能把歷史結果當新摔投驗收。
