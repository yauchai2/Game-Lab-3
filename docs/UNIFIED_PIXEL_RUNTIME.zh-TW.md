# 統一像素、活街景及聲音恢復

2026-11-10（香港日期）。本輪依使用者「開始執行」實作計劃的第一個完整切片；不是宣稱已完成所有手工動畫及獨創字族。

## 可以直接試用

GitHub Desktop Fetch／Pull `codex/street-combat`，以Godot打開 `godot/project.godot` 後F6／F5。未存取使用者電腦，沒有遠端替電腦同步；公開Web版未更新。

- 全畫面：640×360 internal viewport，預設1280×720視窗，以nearest整數放大；UI／字體／VFX同世界一起合成，不再用舊world-only filter。畫面比例保持，非整倍數視窗可有黑邊。
- 字體：RadioPixelDisplay／Body，源自已附授權的Barlow Condensed Black Italic／DejaVu Sans Condensed Bold，binary-alpha bitmap atlas。主Logo保留核准圖稿。這是JSR式粗斜街頭字體的像素化適配，不是聲稱使用官方JSR字型或完成全部獨創字形。
- Fighters：右邊大角色及四卡均使用實際GLB＋骨骼姿態；四人分別調整手套、heel-toe、低重心重拳姿態、調護目鏡。Hero短確認動作／呼吸，15Hz取樣；離開頁面停止viewport渲染，固定5個viewport。角色4維持1.98／其他2.1的略矮比例。原始GLB沒有改動。
- 特效：重擊1.35×、挑空1.45×、暴扣1.55×、技能1.8×、重砲2.15×外圍尺寸。命中中心保持小而準確；不放大碰撞判定，不重新接入舊生成噪聲貼圖。F2保留減少效果。
- 街景：128px道路／混凝土／地磚衍生貼圖，以有限色塊、缺口及筆劃表現磨損；立面小件有固定輕微偏斜。陽台植物由盒子換成銳邊葉片剪影，另有兩棵不對稱切面樹。28件小紙片／罐子集中行人路邊，不擋斑馬線。沒有新招牌文字。
- 生活動態：4位路邊角色的擦拭／喝飲品／看錶／聊天程序手勢、遠景紅車通過、樹葉及紙片微動、後車燈短暫閃動。重演出可觸發有22秒冷卻的反應。背景使用獨立有限節點，不改戰鬥狀態，暫停及節奏hold會凍結；減少效果會壓低動幅。並非新製作的完整NPC動畫套裝。
- UI：保留5主選項及電台構圖，焦點指示短促兩拍移動，選角模型確認反應；沒有把文字或戰鬥值烘焙成圖。

## 無聲跟進

原音檔確有訊號；雲端基線Master音樂峰值約0.037，效果峰值0.301。未能重現使用者電腦的音訊裝置狀態，因此不能斷定唯一根因。

現已加獨立Music／SFX bus，提升原本偏低的背景音樂電平，保留兩deck交叉淡入及暫停時降低音量。主選單在靜音／零音量／bus靜音時顯示恢復入口；Settings有 **TEST SOUND**、**RESTORE SOUND** 及音訊狀態。Restore會解除遊戲及Master／自有bus靜音，恢復80%音樂／90%效果並保存。正常啟動保留使用者有意設定的靜音，不每次強行覆蓋。

如果Pull後仍無聲：開Settings → RESTORE SOUND → TEST SOUND。若顯示“No audio output device”，檢查Godot音訊輸出驅動及電腦輸出裝置；遊戲不能替作業系統選擇喇叭。

## 驗證及限制

- Godot4.6.3，native Compatibility／Mesa llvmpipe；不是使用者截圖的4.7.2硬件執行證明。
- 來源修正截圖中的變數遮蔽／未使用profile，以及static fit呼叫：fit改為正確instance helper，分別命名card／side／fight rect。完整腳本載入沒有對應script錯誤。
- 144條戰鬥回歸、37條native鍵盤／滑鼠／跨三視窗尺寸／音樂transport測試。
- 15條新呈現檢查：framebuffer、真3D四選、不同pose、viewport有界、隱藏停渲、背景暫停／車移動／反應限頻／節點有界／音訊恢復。
- 6條AudioEffectCapture測試採樣實際引擎PCM：主選單、僅音樂靜音時保留效果、零音量＋Master靜音後恢復、暫停transport前進及戰鬥混音。主音樂新峰值約0.127，戰鬥混音峰值約0.569，採樣未clip。使用Dummy輸出，這證明混音訊號，不是人耳聆聽或使用者喇叭測試。
- 19條實際攻擊路由有真命中／出招／接觸／釋放畫面；另外7種防禦／環境效果是獨立渲染診斷，不當成實際招架操作證明。
- 嚴格前端規範稽核零問題，僅補充靜態檢查，不替代Godot操作驗證。
- native編輯器首次匯入GLB時遭環境缺少VK_KHR_surface而失敗；改用headless匯入及Compatibility實機擷取成功。批次招式擷取結束仍有ObjectDB清理警告，未宣稱退出零泄漏或效能提升；新呈現測試亦曾出現同一退出警告；另以原生verbose最小啟動／退出覆核沒有重現，仍保留待追蹤。目標Mac的聆聽、效能及4.7.2須在本機覆核。

證據位於 [unified-pixel](evidence/unified-pixel/README.md)。來源圖／GLB／音樂／舊貼圖完整保留，新資產來源與SHA在 `references/unified-pixel-2026-11-10`，可重跑字體及街景貼圖生成器。未把上述完整切片視作所有路線終點：更精細手工人物動作、全套獨創字形及每頁完整拆層轉場仍可續作。
