# 完整短篇故事驗證

Godot4.7.2／Linux Compatibility／Mesa llvmpipe。最終437項通過，0失敗；[機器總表](summary.json)。規則50、原生23、城市擴充86＋22、strict12＋11、舊M1 37、二段跳62、戰鬥34、九核心75、整體UI15、Ink10。最終log無ERROR／SCRIPT ERROR；初次失敗另留在initial-attempts，不混作最終通過。

- [規則](rules.json)／[log](rules.log)：八組無裝Boss普通輸入、角色／核心上限、有限增援／prop一次範圍、route／craft／核心預算／v2遷移／M1進攻回歸。
- [平衡對照](balance-runs.json)：四角裸裝各打兩Boss；九種極端裝／核心只進攻都敗於Signal。Gantry一極端樣本可硬過剩8HP；不是所有Boss都保證打敗spam，不能冒稱真人平衡完成。
- [完整故事](campaign-runs.json)：四英雄各從0錢裝進度，以正常指令打18場，合法掉裝／解鎖／加點及付費補給，沒有直接改敵HP、注入傷害或免費回血。自動controller使用可見預告資料且時機精準，不能當真人學習／難度結論。
- [原生](native.json)／[log](native.log)：真城內模型、兩槽招式、真Space二跳課程且不改run、真DRAW→EQUIP、Boss／裝備／地面預告／暫停／死亡bounds／prop破壞／退出隔離。為看後期功能使用明示best／資金fixture；phase及death畫面使用HP fixture。實際Boss與整趟通關在headless普通輸入測例證明。
- regressions各JSON／log保存舊模式檢查；舊歷史evidence未覆蓋。原生Dealer測試曾未等面板排版就ensure_control_visible，已補layout等待；沒有改斷言。城市規則僅按schema3、35%chain上限及最多9總增援更新三項舊預期，同時6存活上限另外驗證。

## 原生遊戲畫面

[45°安全城](city.png) · [工坊](workshop.png) · [六章結局](story-ending.png) · [核心抽取](core-result.png) · [裝備演出](core-equip.png)

[Gantry預告](gantry-warning.png) · [第二階段](gantry-phase2.png) · [巨像貼地死亡](gantry-defeated.png) · [Signal預告](leviathan-warning.png) · [真破箱](prop-break.png)

圖是960×540實際渲染，未做後期修圖。Dummy audio，未驗實聽；未驗Mac／目標硬體FPS／真人操作。原創低模是可重建暫用美術；仍需真人平衡與美術打磨。

重跑：`godot --headless --path godot --script res://tools/verify_city_campaign.gd`；原生`godot --path godot --script res://tools/verify_city_native.gd`。strict可用tools/verify_city_compile.py及tools/verify_godot_warnings.py；後者需--output指向本輪目錄以免覆蓋歷史報告。
