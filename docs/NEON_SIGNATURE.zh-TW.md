# Neon Facets：大招長演出更新

2026-11-10。本輪依使用者新要求，覆蓋M1原先最高6°roll／短大招演出，僅作用於 `codex/neon-street-lab`。四個原角色、原模型／動畫庫／判定與音檔保留；公開Web不更新。

## 可玩變化

- 大招 `W+L` 真正消耗原有75能量、照原startup／active／recovery判定。Lab共用時鐘的overdrive profile由0.18s hold／0.30s slow／0.36s release改為0.22／0.78／0.44，slow仍0.22倍、release仍1.95倍；沒有額外Engine.time_scale，也沒有為電影鏡頭停掉音樂。
- director的overdrive起手演出最長1.50s，真正命中後可升級為0.85s釋放演出；普通special的起手演出0.85s，不讓所有小拳都有長特寫。短剪影仍只在開頭出現，長演出主要看得到真實角色動作。
- 疊加收勢／展開／瞄準／出力／收招五段pose，按現有真attack狀態套用：拳手雙手壓縮推出、Dancer抬腿外展踢擊、Bass雙手高舉重錘、Spark一手後拉一手前刺。沒有把idle或下一招強行鎖在假攻擊裡。
- 大招鏡頭36°起手／41°釋放，沿雙方中點繞約-16°到+23°，roll最高14°；淡入／淡出回正常鏡位。Release延續鏡頭權重，避免命中瞬間突然退回遠鏡再zoom。
- 每幀按兩名角色的身體邊界投影檢查畫面、血條和底部提示區，必要時拉遠；極端距離不保證相同近鏡程度。大招的近鏡應服務戰鬥可讀性，而非讓一名角色消失。
- 真正受擊中斷／被招架時取消大招鏡頭；護甲受擊但simulation仍是overdrive attack時保持。Pause凍結演出；F2／重開／返回標題清理。

## 驗證與觀看

[實際出招短片](evidence/neon-signature/overdrive-actual.mp4)／[完整時間軸抽樣](evidence/neon-signature/contact.jpg)／[報告](evidence/neon-signature/checks.json)／[log](evidence/neon-signature/verification.log)。短片是原角色在關閉training回填後的真付費大招，固定1/60秒wall-step，30fps輸出，無聲；不是假命中或目標硬件性能測試。

四人各自真付費命中、五段姿態、慢鏡、14°roll／36°FOV及body bounds均檢查；另測角落／空戰／間距、護甲、真正中斷、Pause、F2、title。重跑原生UI／材質與格鬥規則，完整範圍及結果在 [evidence](evidence/neon-signature/README.md)。

## RPG與參考素材

[街區成長／技能點／解鎖提案](RPG_PROGRESSION_PLAN.zh-TW.md)已完成設計，尚未改玩法或存檔。藝術文件／原始短片／長篇壓縮參考／圖片與生成素材統一入口在 [藝術參考總庫](../references/style-library/README.md)。
