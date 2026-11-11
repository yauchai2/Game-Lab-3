# 新封面、Logo及全套Ink UI

2026-11-10。依使用者最新「唔啱feel、不要項鍊，其他頁面及Logo一併統一」指示重新製作。

## 這輪實作

- 新封面以低多邊形兜帽／帽沿、放鬆插袋的上半身為主，頭轉離鏡頭，衣服沒有項鍊、十字飾物、徽章或文字。黑白城市、桃紅天空保留影片的對比感；原始影片僅作風格參考，未直接裁入遊戲。
- Logo換成白色硬切AFTERHOURS字標，附桃紅底線及青色收尾。原皇冠／米白粗描邊圖保留歷史檔，現行頁面不再繪製。新Logo依實際atlas長寬比顯示，亦配置作啟動畫面；沒有把啟動畫面設定當成已單獨截錄驗證。
- 主選單、選角、設定、暫停、教學、結算共用城市片段、Logo、字體、色盤及頁眉。戰鬥HUD同步改為青／桃紅血條、無人臉的三條電台徽記、同套操作列；電台徽記是符號，不冒稱即時音訊讀值。
- 選角維持現有4個真3D模型及不同姿態。僅預覽開啟 `silhouette_preview`：純色emission、不顯示貼圖五官，outline pass discard。實際對戰的flag保持false，模型及貼圖原檔不變。未重新分配面數、骨架或角色招式。
- 方切開關、滑桿把手、下拉箭頭含啟用／關閉／focus／disabled狀態；從共用palette產生SVG。操作標籤及快捷鍵保持原生、大字可讀，滑鼠／鍵盤焦點與音樂持續播放規則保持。

## 素材拆件與擁有者

實際資產在 [assets/ui/ink](../godot/assets/ui/ink/README.md)：新封面、乾淨Logo原圖及atlas、城市帶、斜切紋、8個SVG控件狀態，合共13個圖形／atlas來源檔（不計import與README）。Logo以AtlasTexture區域裁取；城市帶裁自新封面頭部以上，沒有角色；斜切紋裁自新生成圖集。裁切區域、SHA、生成提示詞在 `references/ink-ui-2026-11-10`。生成圖集只有斜切紋錄用；角框／電台徽記採精確原生幾何，沒有把整張生成稿當假介面覆蓋互動。

`ui_theme.gd`是palette、字體、原生元件狀態owner；`reference_art.gd`是頁面構圖／卡片／HUD owner。SVG由 `tools/build_ink_controls.py` 讀取palette再生成。歷史sprite檢視helper改為lazy載入，現行頁面不呼叫舊貼紙／米白框／頭像sprite。

全部世界與UI依然640×360合成並整數放大。常用邏輯字級24／28／32；PNG大小不是提高遊戲解析度。沒有加入HTML／第二套互動控制器，也沒有移動或覆寫原始GLB、音樂、字體及舊圖；72件此前遊戲圖像／模型／音樂／字體來源逐一比對未變。

## 驗證及限制

- Godot4.7.2-stable，Linux native Compatibility／Mesa llvmpipe。
- 37／37原生鍵盤、滑鼠、三視窗大小、選角／Demo、音樂transport及連續crossfade檢查。
- 10／10新頁面檢查：4人真3D剪影與outline旗標、原生select popup、原戰鬥材質隔離、字體及真正rematch操作。涵蓋主選單、4人選角、設定／popup／底部、暫停及其設定、教學上下部、HUD、結算圖。
- 6／6材質生命週期回歸，strict runner檢查stderr ERROR／SCRIPT ERROR；各循環pending=0，無材質錯誤。
- 43遊戲腳本載入零parse錯誤；嚴格靜態設計稽核只作補充，不能代替原生驗證。
- 結算是明示結果狀態fixture，非實際KO演出或真人操作；popup以嵌入subwindow擷取。初期擷取fixture退出有4個ObjectDB清理警告；關閉嵌入窗口並等候音訊釋放後，最終page-suite未再出現。環境V-Sync提示仍保留，不宣稱所有目標平台零警告。
- 生成圖及實機畫面以人工檢視確認衣服無項鍊；不是自動配飾／人臉辨識保證。音訊為Dummy混音環境，非Mac喇叭試聽，目標Mac效能未測。

[全套原生畫面](evidence/ink-ui/README.md)。只推送來源分支供GitHub Desktop Pull；未更新gh-pages或公開試玩版。
