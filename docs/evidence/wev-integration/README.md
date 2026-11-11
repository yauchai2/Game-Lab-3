# wev 接入證據

[來源與處理清單](../../../references/audio-sources/worldwidewev/admitted.json)；最新範圍見 [WEV_MUSIC_PLAN.md](../../WEV_MUSIC_PLAN.md) 與 [VALIDATION.md](../../VALIDATION.md)。

- `headless/summary.json`：103 項既有回歸通過。
- `native/summary.json`：17 原生介面＋初版 19 音訊檢查；後續新增實際曲末循環。
- `final-audio/summary.json`：最終 20 項音訊檢查及短 Master 混音取樣。
- `final-audio-regression/summary.json`：退出清理修正後重跑 33 項既有音訊，避免重複計數。
- `runtime-first.*`：保留首跑 19 項通過但 OGG 退出警告的結果；之後修正播放實例 stop，最終日誌無該警告。
- `source-loudness.log`／`game-loudness.log`：FFmpeg 音檔量測，非真人實聽。
- `settings-credit.png`／`capture_settings.gd.txt`：原生署名／音量畫面及擷取方法。

完整曲目由官方免費下載流程取得；來源 MP3 不提交，只加入遊戲 OGG 衍生。不含短期下載 token、帳號／email、私人授權文件。只依使用者確認可用與下載／接入指示，不將作品改標 CC0。公開 Web 未更新。
