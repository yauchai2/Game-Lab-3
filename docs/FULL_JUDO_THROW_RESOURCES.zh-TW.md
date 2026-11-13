# 完整柔道摔投：資源核對與接入方向

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
