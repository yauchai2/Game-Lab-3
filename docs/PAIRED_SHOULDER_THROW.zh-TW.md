> 此文保留前階段紀錄。最新使用者已授權動作隨GitHub提供，Pull即用、第一批23個衍生clip已全啟用，肩摔恢復已改64tick；請先看[MOTION_COMPLETION.zh-TW.md](MOTION_COMPLETION.zh-TW.md)。

# 完整雙人過肩摔：正式接入

2026-11-14（香港）。使用者要求繼續完成共同裁切、角色重定向、抓握及落地。基線1beceae，沿codex/four-fighter-motion-plan；不合main、不更新Web。這一組肩摔已接到實際grab流程，其他49項動作候選並未因此完成替換。

## 本機安裝一次私有動作資料

公開repo保留原四角GLB與既有CC0庫；不公開Mixamo FBX或可還原曲線。雲端已安裝並驗證，GitHub Desktop Pull程式**不會自動取得私有動畫檔**。

1. 取得本對話提供的私有`mixamo_shoulder_throw.json`，保留repo外備份。
2. 在專案根目錄執行：

```bash
python3 tools/install_mixamo_throw.py ~/Downloads/mixamo_shoulder_throw.json
```

3. 重開遊戲，以原本抓投輸入操作。四英雄及普通黑衣敵人可使用配對；雙方都可施技。測試用訓練時貼近對手發動，拆投、預先跳走及同時打擊的規則仍在。

installer寫入被Git忽略的`godot/.godot/private_animation/mixamo_shoulder_throw.json`，權限600，有舊檔先留`.bak`；若清掉Godot快取需重裝。也可把檔留在repo外，啟動遊戲前以`GAME_LAB_THROW_LIBRARY`指定絕對路徑。沒有資料或明確停用時沿原grab fallback，不能將這種情況當完整摔投已生效。正式匯出／Web資產打包沒有在本輪處理。

如要從兩個原始FBX重建，不需Adobe token：

```bash
blender -b --python tools/import_mixamo_throw.py -- \
  --aggressor '/private/Shoulder Throw, Aggressor.fbx' \
  --victim '/private/Shoulder Throw, Victim.fbx' \
  --output /private/mixamo_shoulder_throw.json
```

然後執行installer。匯出器拒絕把曲線寫到公開repo路徑，唯一repo內例外是被忽略的`.godot`快取。原始兩個FBX不修改，來源SHA見[evidence/paired-throw/asset-manifest.json](evidence/paired-throw/asset-manifest.json)。

## 實際行為

- 原片1–60幀走近段裁掉；兩段共同使用61–121幀，不各自置中。保留轉肩、對手離地倒轉及落地，不用單模程序自轉冒充摔投，也不聲稱此來源做了360°整圈。
- `paired_throw.gd`是唯一雙人simulation時鐘。合法grab命中才捕捉，先不扣血；第60個配對tick對應來源106幀，透過原`_resolve_hit`路徑結算一次，保留傷害／能量／核心／角色資源規則及一次停格。
- 共80個接觸／跟進tick及28個回復tick，加既有grab起手和落地停格，正常約2.15秒。施技者繼續收招；被摔者落地後hold，再以既有CC0 Roll末段及其角色待機銜接起身，不把來源原片地面掙扎段當起身。
- `paired_throw_motion.gd`重定向原始全身及手指旋轉，保留四角骨長。來源平面位移1.0倍、垂直參考1.15倍；兩方共享基準，模型深度位移轉入世界座標，雙朝向不拉開抓握。
- 實際雙人手腕以雙骨IK協調，另有每臂最多3.5cm的肩胛前伸補償；不放大拳腳或拉長手臂。四角配對抽樣最大手腕殘差約2.56cm，並非每根手指／衣服表面零穿插的保證。
- 每個新姿態按實際CPU蒙皮最低點作向上貼地，地面回復期保持接地；停格／暫停／F2不改共同時序或幾何。renderer獨立蒙皮bake另驗腳底，不以同一CPU公式自我證明。
- 牆邊對整條雙人root路徑共同平移限制；沒有對遠處敵人自動吸附。抓空、先跳走、拆投不進雙人流程。同時的普通打擊先打斷起手。
- 群戰鎖定已捕捉的普通敵人，致命落地也不提前換人；配對段等待成員／一般advance暫停，沿既有短雙人演出模式。外部受擊、換phase及reset釋放狀態。巨型Boss沿其原有grab／裝甲規則，不強套這個人類比例配對。
- 致命摔投完成收尾後才結算回合；屍體保留落地pose，不再接普通KO空中翻滾。原有最終決勝過場仍由其導演接管。訓練不留下死體鎖住狀態。

## 證據與驗收

[正式場景12秒有聲影片及報告](evidence/paired-throw/README.md)：四段貼近訓練fixture，每段僅一次正常grab輸入，逐段真start／land／hit／end各一次，沒有注入傷害、空中位置或命中。四角都可施技，攻守雙方使用實際角色模型。

147項新simulation／實際骨架檢查、33項原生renderer／正式KO接入檢查全過；674項相關motion／角色規則／死亡／FX回歸通過，另35群戰及35黑衣整合通過。16個相關腳本七類fatal warning通過，專案匯入與正式fight_session解析通過；未重跑全專案所有歷史strict套件。

Godot4.6.3 Linux Compatibility／llvmpipe／Dummy音訊；影片12.000秒、360幀／30fps，完整2fps抽格已檢視，AAC解碼非靜音、無削波。固定FPS錄製約84秒，不能當目標硬件即時30fps或Mac／真人手感／實聽驗收。
