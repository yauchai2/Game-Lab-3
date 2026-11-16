# 開場與全遊戲音效降音量（2026-11-17）

使用者回報開場與整體效果聲音超大。基於main af6fcb8，全部正式遊戲音效共用Afterhours SFX；原有壓縮器額外補3dB，開場cue本身又比其他過場高。只改新玩家預設滑桿不能解決既有已儲存的85%／100%設定。

## 修改

- 共用SFX在壓縮器／limiter之後加入單一−10dB混音校準，涵蓋普通打擊／大招／UI／抽核心／開場／KO等獨立播放器。既有音量設定直接生效；保持原滑桿、靜音與音樂設定。
- 壓縮器makeup gain由+3改0，不再把已正規化的效果推大；原limiter保留，先限制疊加峰值，再衰減輸出。
- 開場音效cue的播放基準額外由−1改−5dB；開場音樂仍獨立走Music bus，音樂素材及音量未改。
- 重複初始化不疊加效果。「恢復聲音」仍能解除靜音，但不繞過共用校準；現有存檔不需刪除／重設。
- 舊探索飛機引擎如有共用SFX bus便接入；獨立探索沒有該bus時，直接以相同−10dB衰減，避免繞過此次降音量。航空腳本check-only通過，未宣稱該探索路線真人實聽驗收。

## PCM前後比較

完整隔離af6fcb8基線與候選執行同一測試。保留原來源音訊、相同85%音效設定、關閉音樂，透過Godot Master AudioEffectCapture取得每例45056個實際混音frame；開場先準備場景再擷取，避免把模型建立時間混進取樣。每例約1秒，是固定片段的RMS／peak比較，不是全曲LUFS或真人響度評分。

| 情境 | RMS變化 | 峰值前→後（linear） |
| --- | --- | --- |
| 單次重擊 | −12.95dB | .425→.095 |
| 同時十次重擊 | −13.00dB | .794→.197 |
| UI確認 | −13.00dB | .238→.053 |
| 開場箱子落地片段 | −11.55dB | .794→.158 |

壓縮器是非線性處理，輸出差值不等於各增益設定直接相加。[比較原值](comparison.json)、[baseline](baseline.json)／[candidate](candidate.json)及各log保留。12項候選檢查包含真PCM不為空／不削波、重複初始化、壓縮器無補償、單一末端trim、開場與共用bus／獨立音樂、靜音、舊低滑桿及恢復聲音不繞過校準；全部通過。

[33腳本／10類warning fatal](warnings-strict.json)通過；音效配樂66/66、故事開場44/44、KO21/21回歸通過，各suite重疊。接受log無ERROR／SCRIPT ERROR。既有證據檔恢復原歷史版本，本次產物獨立保存；log只正規化行尾空白。

環境Linux Godot4.6.3／headless／Dummy，AudioEffectCapture確實有非零取樣，不能將Dummy當作無聲通過；仍不代表使用者Mac／4.7.2、耳機／揚聲器實聽或主觀平衡驗收。原始聲音素材沒有重製或覆寫，Web未部署。

執行：`godot --headless --path godot --audio-driver Dummy --script res://tools/verify_quieter_sfx.gd -- <報告json路徑>`。基線使用完整隔離worktree及相同測試，加`baseline`僅跳過新設定結構斷言，保留真PCM檢查。
