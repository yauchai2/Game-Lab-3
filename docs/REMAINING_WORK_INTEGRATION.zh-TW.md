# main 整合與剩餘工作收尾（2026-11-13）

本輪依使用者「全合到main」「仍未完成的工作把它們全做好」整合現有來源，並完成能在雲端執行的程式收尾。**完整攻守配對柔道摔投及目標電腦／真人／實體手柄驗收仍未完成**，不能將本頁的其他完成項目當作這兩項已交付。

## 已整合來源

以遠端 main `3915c2d` 為基礎；這個 main 已含新版開場、完整故事／結局、首批圖像式據點介面與黑衣人手槍。

| 來源 | 收入內容 |
| --- | --- |
| codex/story-waves-m1 `352c524` | 1280×720全遊戲、清晰字圖及中等像素字體 |
| codex/four-fighter-motion-plan `2b413bc` | 四角地面／空中／受擊動作、專屬聲光鏡頭、免費配對投技需求與取得阻礙 |
| claude/opening-music-flow `fff9fe2` | 開場配樂去掉落拍前空白 |
| claude/project-thread-gw0yhr `8fad9e0` | DEALER／SHOP／CIRCUIT 圖像式介面 |
| claude/project-thread-oo92do `ba8a886` | 手柄震動路由、開關與保存 |

來源動作文件原本分散於不同分支；完整歷史另保存在 `docs/integration-history/`，根目錄最新交接以本頁及最新 HANDOFF／TODO 為準。公開 Web 未部署。

## 本輪完成

- UI P1：AUTO／ALWAYS／OFF操作提示並保存；AUTO首回合6秒後收起，暫停凍結。教學保留必要任務提示，舊練習不再與底部通用提示重疊。只保留P1青／P2桃紅資源格，移除重複角色資源文字，SURGE保持細條／一行；過場隱藏暫停按鈕。
- UI P2：主選單5項；AI DEMO只保留開發快捷鍵F12，HOW TO PLAY只列核心按鍵、當前角色與LESSONS／LABS。舊練習、SQUAD與歷史Street Run統一從LABS進入；選角只選人／LOADOUT／CONFIRM，刪除重複出擊入口。Enter失去焦點時也開正式STORY城市。
- 音訊設定只留全靜音與兩條音量；診斷／測試／恢復僅在無聲設定時顯示。音樂滑桿可解除舊music_muted偏好；零音量與靜音仍不停止transport。WATCH OPENING移至SETTINGS單一入口。
- UI P3：回合／抽獎文字與遮幕使用共用Ink tokens，原生按鈕文字全大寫；暫停／結果／設定共用面板範圍。LOADOUT技能名稱、狀態與說明分開；修掉選角確認與名稱重疊、無控制項的SQUAD裝飾及大字母。
- 四英雄加入有界轉髖與兩骨接地IK。足部支撐鎖定、最多14cm視覺骨盆修正與最多22cm足部目標修正，離地／死亡／KO／反彈／換模釋放。只讀simulation，不改fighter root、碰撞、傷害、能量或時鐘；它是**當前平地的骨骼接地**，不是任意地形射線IK或新增mocap接觸marker。
- 選角、勝出／登場及據點預覽明確啟用同一英雄基礎profile；正式據點已使用同一visual。導演可在其上保留專屬手勢。共用姿態採明確opt-in，抽能力裝備／Dealer／既有劇情導演保持各自的姿態與取景。
- 全19腳本的七類fatal warning檢查通過；保留黑衣人手槍、原GLB／BGM／存檔與各模式隔離。

## 驗證

[完整851項報告](evidence/remaining-work/summary.json)，含19 strict、70新整合、51角色風格、216空地交接、43開場、68本機雙人輸入、22城市、23完整戰役、34戰鬥、75核心、10Ink UI、37參考UI、10群戰、24回合、113裝備、25結果、11震動路由。accepted logs無ERROR／SCRIPT ERROR。震動是headless注入裝置路由測試，並非真手柄實震。

另有1,800個固定simulation tick、21次真命中：純simulation與加呈現simulation的SHA相同，0呈現資料修改。四英雄×雙朝向×地面招式接觸／收招抽樣，最大支撐誤差約0.042m（門檻0.08m），所有骨骼矩陣有限；不是真人或任意地形驗收。

環境為Godot4.6.3 Linux Compatibility／llvmpipe／Dummy音訊；不宣稱Mac4.7.2、目標GPU即時FPS、真聆聽、手柄或鍵盤鬼鍵已驗。首次失敗保留於 `evidence/remaining-work/initial/`：暫存輸出資料夾、過時選單與音樂等待假設、共用showcase影響裝備取景、支撐腳reach誤差，均在最終驗證前處理。靜音裝備音軌若已自然播放完畢，pause驗證接受「未播放或已暫停」，仍必須凍結演出時鐘。

[主選單](evidence/remaining-work/main.png)／[選角](evidence/remaining-work/roster.png)／[精簡HUD](evidence/remaining-work/hud-clear.png)／[HOW TO PLAY](evidence/remaining-work/help.png)。

## 仍未完成與接續條件

1. **完整攻守配對柔道摔投**：最新使用者要求只用免費資源；優先Mixamo `Shoulder Throw, Aggressor`／`Victim`。官方登入瀏覽器無法啟動，官方原檔未取得，兩條root軌跡／同步／接觸與落地幀未核實。現有grab仍是過渡手勢，不能當完整摔投。詳 `FULL_JUDO_THROW_RESOURCES.zh-TW.md`；不採購付費包、不提交無法確認授權的鏡像。取得官方兩份FBX後才可做配對狀態、根軌跡、一次落地結算及四角轉接。
2. **目標電腦與人手驗收**：需要實際裝置。Fetch／Pull main後，以本機Godot停止舊遊戲並F5；按下列流程記錄結果，不把雲端自動測例當替代。

## 本機驗收流程

- STORY城市：移動到六設施、出擊／回城、天賦與裝備、讀存檔；沿用既有存檔並保留備份。
- 四角：向兩邊走／停、普通連段、重擊／挑空／空連、受擊／倒地、技能／大招；看支撐鞋是否滑動、轉髖是否自然、群戰／Boss能否辨識。
- 設定：三種操作提示、靜音與音量滑桿；暫停／設定／回合／抽獎／裝備／KO中確認聲音連續且沒有失控重疊；WATCH OPENING能播與跳過。
- 雙人：兩鍵盤區、多鍵同按鬼鍵、兩個真手柄、混用與拔插；開關震動並實際感受強度與結束清理。
- 目標GPU：實際遊玩記錄平均與p95幀時間、F2比較；另記視窗／全螢幕、字體、亮度、Boss容錯及音量。公開Web需另行明確要求才更新。
