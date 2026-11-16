# 整體聲音節奏與混音整理（2026-11-17）

使用者授權整體音樂／音效及節奏美感可大改。來源main660b600，保留前輪SFX共用−10dB、開場−5dB、原始MP3／OGG／WAV及使用者滑桿。此次修改正式fight_audio的編排與聲音取捨，沒有改遊戲判定、傷害或演出時間。

## 聲音方向與覆核

以安靜準備、交換動作、清楚命中、短爆發與收束作層次。檢查全部11個音樂檔的實際EBU R128響度與true peak，見[source-loudness.json](source-loudness.json)：fight_a／b／c約−21／−20.9／−19.8 LUFS，fight_low為−24.1；原來再加動態增益，平靜→激烈的預期響度落差可達7–8dB。城市−28、結果−29.6本來就有較安靜的敘事角色，不整批抬大。

| 範圍 | 正式修改 |
| --- | --- |
| 戰鬥音樂層次 | 只衰減較響的master：a／b−3dB、c−4dB；淡入淡出兩個deck分別套自己的trim。原平靜、工房、練習、抽能力、開場／KO與結果素材保留。 |
| 戰鬥換曲 | 音樂至少維持6秒實際交戰時間，再依當前曲目bar_seconds等下一個小節邊界；換曲用約一拍的.35–.65秒交接，減少不同BPM長時間打架。熱度回復會取消過時的降溫排程。 |
| 返回平靜 | 記住先前loop位置，從所在小節恢復，避免每次回到相同第一拍；新一局清除舊戰鬥位置。暫停不消耗交戰hold，練習維持固定曲。 |
| 敘事轉場 | 抽能力.45秒、KO.12秒、勝負結果1.5秒；這些實際場景入口直接切換，不被戰鬥hold卡住。KO仍是一次播放，原暫停／跳過／退出清理保留。 |
| 快速導航 | 反向淡入保留當下兩deck權重及播放位置；第三個目的地保留較響的舊deck及原有權重，不突然拉滿剛開始的曲目。權重能量有上限，仍只有兩個播放器。 |
| 音效辨識 | 腳步−5dB、落地／揮空／材質尾音−3dB、槍聲−2dB；主要命中與招架保留，前輪整體降音量不回退。 |
| 多人重疊 | 同種hit／heavy／step等25–90ms內只留一次；之後正常出招仍可播放。不刪戰鬥事件、不影響實際命中或升溫。 |
| 播放優先 | 閒置voice優先，滿池時低優先音不搶高優先；招架、破防、釋放、重砸、KO最高，腳步及材質細節最低。仍最多10個effect voices。 |
| 音樂避讓 | 普通命中1.5dB／大命中3.5dB，獨立快壓低、較慢釋放的包絡，避免連擊把整首音樂長期抽空。退出清掉殘留duck與重複門檻。 |

同種聲音合併只處理最短25–90ms窗口，不把低音量、靜音、F2、音樂／效果獨立控制或原曲來源當成待刪功能。

## 量測與驗證

[26項新增檢查](candidate.json)／[log](candidate.log)：包含小節排程、最短hold、過時排程取消、保存小節位置、練習／抽能力／KO／結果、重疊合併、重要voice保護、腳步層次、duck清除、反向／第三目的地切換與能量上限，及三首曲目非零PCM不削波。

完整隔離main660b600與相同測試，[comparison.json](comparison.json)的實際Master PCM取樣：fight_a／b／c分別下降3.00／3.00／4.00dB RMS；每曲使用相同源位置，基線／候選均有40960或45056真實混音frame。這是固定片段比較，完整曲目響度由ffmpeg另外量測；沒有把效果設定值冒稱聽感評分。所有原始音樂hash另存[music-source-hashes.json](music-source-hashes.json)，沒有重製或覆寫原曲。

33腳本10類fatal warning通過；既有音效／配樂66、故事開場44、KO21、前輪低音量12及Master PCM6檢查通過。suite重疊不相加。第一次combat_sfx退出有ObjectDB／2 resources still in use診斷，保留combat_sfx-initial.log與initial-regressions.json；後續轉場程式完成後重跑66/66且無該錯誤。接受log均無ERROR／SCRIPT ERROR，不把初次退出錯誤當乾淨通過。

## 可試聽產物

[約21秒混音試聽](mix-preview.ogg)由真Godot mixer排程錄製：選單→據點→戰鬥升溫→暫停／續戰→抽能力→KO→結果。這是固定音效排程的混音試聽，不是人手遊玩或完整KO過場錄音。921600個PCM frame，輸出peak約.162、clipped0；preview.json保留實際轉曲時間，其中平靜→激烈的outgoing約7.155秒，接近7.2秒小節邊界（約45ms差，含mixer／observer量化）。原始WAV在本輪暫存，Git保存較小的OGG試聽及重建工具。

重建：`godot --headless --path godot --audio-driver Dummy --script res://tools/render_audio_mix_preview.gd -- <output.wav> <report.json>`；方向檢查：`godot --headless --path godot --audio-driver Dummy --script res://tools/verify_audio_direction.gd -- <report.json>`。

環境Linux Godot4.6.3／Dummy，真PCM樣本及排程狀態有驗證，未做使用者Mac／4.7.2／耳機或喇叭實聽／真人趣味或平衡驗收。此輪沒有更換音樂來源、修改原音訊或部署Web。主觀舒適度仍需使用者本機試玩。
