# THE DEALER：回合間真3D抽能力

已接入 `codex/combat-escalation-next` 的正式 FIGHT／Street Run／Demo；本輪不更新公開Web。原片、來源SHA與原創素材hash在 `references/ability-draw/manifest.json`。

## 實際操作

- FIGHT：第二回合結束、比分1:1時，結果頁選NEXT ROUND／Enter進入。2:0已完場則沿用完整決勝KO，不發第三局道具。
- Street Run：第二站勝出，NEXT STOP後進入；敗退不發獎。
- NPC拖入機器、落地、拍機；代幣近鏡等待SPIN／Enter／Space。抽取後播三輪盤減速鎖停、短靜拍、能力筒爆出、獎品卡。
- TAKE CORE／Enter／Space領取後才開始下一局；原生按鈕可用滑鼠。第一按跳動畫不會同時領獎；跳過不重抽。
- Esc暫停，F1設定會暫停，F2減少魚眼／模糊／線條／粒子但保留抽獎。R重開、F12 Demo切換、返回及換場清理。
- Demo使用同一演出，0.45秒代幣等待後自動抽，結果停1秒後領取；無永久XP。

## 真正生效的能力

本場暫時資料，與既有永久XP／技能槽隔離，每個boundary只發一次；下一回合重建fighters後才套用，下一次重置自動消失。

| 能力 | 實際規則 |
| --- | --- |
| SPEED CORE | 移動速度×1.20，衝刺速度×1.10。這不是獨立加速度參數。 |
| GUARD CORE | 護盾回復×1.35，仍受100上限。 |
| CHARGE CORE | 起始能量+20，仍受100上限。 |

三種等機率，首版每局一次免費抽取；未引入貨幣／扣XP／額外加注或重抽。隨機結果由session資料決定，展示層只讀結果；三輪盤停相同對應圖案。

## 3D、動作和聲畫

NPC是原創程序切面人物：紫色兜帽、黑色面罩內襯、象牙面具／青色眼縫、肩部黃記號、寬袖、肘部及巨型黑手套、厚底鞋。與戰鬥選角獨立，不改原GLB。

機器是真正分件3D橙色機殼、側喇叭、四輪、三個UV圓柱輪盤、拉桿、出貨蓋、螺栓／警戒條；代幣與能力筒亦為3D。輪子隨拖行路程轉，雙腳／腿同步小步拖行，拍機、機身回彈、出貨蓋打開、能力筒拋物線和NPC後仰用同一局部時鐘。

近鏡廣角、短桶形魚眼、衰減震動、7-tap放射模糊、漫畫速度線／WHAM與JACKPOT、20團幾何灰塵、24片碎光、一個擴張衝擊環；結果文字位於後製上層。Compatibility可用，不依賴Forward+體積霧或速度buffer。背景沿用當局真實World3D，獎品卡才切圖形化背景。

五條原創48kHz立體聲cue：arrival、spin、reveal、coin、confirm。`tools/build_ability_draw_assets.py`可重建；沿`Afterhours SFX`與既有mute／effects_level，BGM持續transport及duck，暫停保留位置，退出停聲還原。預覽只刻意關BGM以聽清SFX，不代表遊戲移除了背景音樂。

## 換場地與入口

`FightSession.ability_draw_stage`可指定 `stage_profile.gd` Resource，預設 `resources/ability_draw/street.tres`；`reverse_street.tres`示範不同位置、32度面向、反方向入口、灰塵色。**這是同一現有街景的兩個配置，並非宣稱另造兩張地圖。**

- `anchor`／`heading_degrees`：停機演出原點與方向；全部演員／鏡頭／特效都相對它。
- `entry_offset`／`backup_entry_offset`：兩條直線拖入通道。以2.6×2.9×1.5m掃掠盒檢查碰撞；主路堵塞換備援。
- `collision_mask`：對應場景障礙；碰撞必須由地圖作者提供。
- `floor_height`／`dust_color`：高度偏移及揚塵色。
- 若兩路均堵塞，改成落位點原地短煙塵入場；地圖作者仍須提供無障礙的停機點與攝影機空間，不能把任意封閉空間視為已自動解決。首版是平地／固定高度入口，未做任意曲線導航、樓梯輪軸解算或足底IK。

雙方fighter、影子和背景生活人物在演出時隱藏，完成／取消恢復原可見性。鏡頭transform／fov／near／far／environment、後製、音樂duck與背景可見性均保存／還原；與Neon、CityBreaker和RoundTheatre互斥，清理冪等。

## 時間與復刻範圍

來源864×480、名義24fps、107幀、約4.352秒；已全時長4fps取樣並檢視關鍵畫面，不冒稱來源PTS逐幀鎖定或實聽原音軌。arrival約1.95秒＋代幣等待＋spin/reveal約1.45秒＋結果等待；本次實際錄像含0.4秒offer及1.5秒結果停留，約5.73秒。

按影片重建了人物／機器配色、拖入、拍機、代幣近鏡、輪盤、爆獎及能力卡。**不是逐像素完美復刻**：人物為手工程序關節而非來源角色rig、街景採當局背景、磨損／衣摺／煙霧形狀及動作曲線仍有差異；沒有用影片貼片假裝3D。未做完整拉桿鏡頭，原片也沒有清楚完整演出。

## 驗證與觀看

[有聲引擎預覽](evidence/ability-draw/ability-draw.mp4)／[八鏡截圖](evidence/ability-draw/README.md)／[45項原生檢查](evidence/ability-draw/verification.json)。明示1:1邊界fixture，正常runtime交接／能力規則／原生callback；不是自然完整match錄像。

45項新檢查、既有戰鬥34項及結果15項，共94項通過。native最後log無ERROR／SCRIPT ERROR；保留VSync不支援warning。初次headless材質錯誤與測試設定失敗保留，見證據README；不能以33/33旗標掩蓋該次log錯誤。

Godot4.6.3 Linux Compatibility／Mesa llvmpipe／Dummy audio；Movie Writer實際混音後轉H264/AAC，640×360原生渲染、1280×720 nearest放大。這不是使用者Mac、真人手感／音訊裝置或目標GPU即時效能驗收。

## 2026-11-11：修正突然出現＋裝備分鏡

使用者指出NPC／機器應有進場。已重現原版兩條通道起點與街景StaticCollision重疊，退回零位移的根因；入口改為已驗清楚的±6m／z0，先空場、再搖鏡迎接拖入，1.05秒煞停，腳步／輪轉／音效同步。兩路均受阻的compact配置加入遮幕揭幕，不再直接露出新生成的演員。新版有聲畫面與檢查在[entry-v2](evidence/ability-draw/entry-v2/README.md)，原版證據保留。

使用者另要求能力物件裝上角色的短動畫，已生成[1.8秒六鏡規劃](ABILITY_EQUIP_STORYBOARD.zh-TW.md)與概念圖；**裝備動畫尚未接runtime**。抽獎段不見玩家；裝備提案只拍手／腰／鞋，不露臉。未來Tripo NPC／機器需待檔案到位再做衍生綁骨／分件及換模，原檔保留。
