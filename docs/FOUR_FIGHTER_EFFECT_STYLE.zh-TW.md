# 四角戰鬥風格：輪廓、鏡頭與音色

2026-11-13（Asia/Taipei）。接續[地面動作](HUSH_LOOP_MOTION.zh-TW.md)，本輪把正式戰鬥的命中、釋放、起招、招架、大招演出與撞牆圖形接到四角風格；不只換顏色。實錄：[12秒／四段](evidence/fighter-style/four-styles.mp4)，[同色輪廓比較](evidence/fighter-style/silhouettes.png)。

| 角色 | 形狀與節奏 | 大招鏡頭 | 命中材質音色 |
|---|---|---|---|
| ZIP | 錯開雙箭，隨踢技路線推進；F2單箭 | 較明顯側繞，39°起手FOV、較多roll | 高頻氣流／下降短音 |
| RIVET | 厚框壓印與兩條壓縮短線；F2單框 | 低位小側移，43°起手FOV、較低roll | 低頻下墜、非整數倍金屬泛音 |
| HUSH | 單道細切線與短見證線，不疊放射星爆 | 穩定微移，40°起手FOV、極低roll | 極短乾脆噪聲瞬態 |
| LOOP | 正交方波、兩個方端點；F2保留單路線 | 較寬46°起手FOV、較高機位 | 雙頻短節拍與中途斷奏 |

`fighter_effect_style.gd`是有限局部圖形與鏡頭profile；`fight_vfx`及原有唯一全屏owner `neon_effect_director`共用它。原有全屏幕邊／閃白仍由Neon掌管，HUSH去掉大招釋放速度線，LOOP改正交訊號線；沒有增加全屏owner。撞牆按受撞角色、招架按成功防守方取樣，避免原本從顏色猜P1/P2的錯誤。釋放仍從真impact queue取得攻擊者。LOOP端點是瞬態特效裝飾，不是假遊戲節點；真節點與pulse仍由既有規則產生。

大招鏡頭仍由`neon_signature_camera`檢查兩人身體與HUD邊界並退鏡；本輪不是節點／全場道具可見性保證。FOV釋放比起手加3°。鏡頭改動只在原本signature權重有效時啟動，普通技能不強行套大招運鏡。F2回原普通鏡頭，暫停凍結director。黑西裝保留原fallback。

`fight_audio`保留既有CC0實錄打擊主體，再疊四種原創、固定種子、啟動時建立的短PCM；不是四組新取得的真人錄音或僅調同音高。沿用十voice上限、75ms材質層預算、獨立SFX bus／limiter、靜音及effects_level；沒有修改BGM transport。四個輸出的WAV在證據目錄，供試聽，程式本身可重建。

此次清理`sprite_fx`原有未用參數與整數除法警告：圖集row明確floor，保持非負索引原結果；沒有更換CC0圖集／煙塵來源。原GLB、19原動畫／19擴充動畫、來源授權與manifest不變；原Quaternius／KayKit動作繼續使用，沒有新增付費／登入庫的下載宣稱。

## 驗證與界限

[evidence/fighter-style](evidence/fighter-style/README.md)：51新增＋407動作／機制／死亡／FX回歸＝458全通過。11個motion／recipe／風格／鏡頭／音效／Neon腳本七類fatal warning全過；全19suite為16/19，比基線多通過sprite相依的fight_vfx，尚有三處既有失敗，不能稱全綠。

與701f0c7隔離來源重播相同1800 simulation ticks，輸入hash與狀態SHA一致（022cef61…）、21真命中、0差異／呈現改寫。新增原生測試含72組間距／空中／owner鏡頭邊界，暫停、F2、靜音與音量0、PCM峰值／能量／重建及每角色呈現不改sim；同色比較為明示繪圖fixture，非實戰截圖。

12秒360幀連續PLAY實錄，四段重設練習fixture（起始100能量、固定近身站位），正常session指令，命中2／1／1／1；HUSH對手起手合法jab→真parry→sample→L，LOOP先正常放點再encore；沒有預塞sample／node／damage。影片僅ZIP技能、RIVET大招、HUSH取樣反擊、LOOP一點encore；不等於四角全招逐幀驗收。影片音軌非靜音及PCM量測不等於人耳／裝置確認。

Linux Godot4.6.3 Compatibility／llvmpipe／Dummy；非Mac、真人或目標GPU效能驗收。全空戰／投技／受擊動作家族、完整轉髖與地形足部IK、選角／登場／勝出共用profile仍待後續。原始碼推同任務分支／PR #29，公開Web不更新。
