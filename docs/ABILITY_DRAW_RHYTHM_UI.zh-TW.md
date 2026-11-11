# THE DEALER：節奏、手動抽獎與 UI（2026-11-11）

本輪按使用者要求直接更新正式回合間過場。沿用上傳的 65 骨蒙面 NPC／Tripo 機身、跨場景入口及真 3D 活動件。

- 入場 2.05 秒：拖行加速、煞停、拍機重音與 60ms 短停，再展示代幣。
- 展示後無限等待。滑鼠按 DRAW 或新按 Enter／Space 才抽一次；Demo 也遵守這個最新要求，覆蓋舊自動抽取／領取契約。
- 抽獎 2.20 秒：三輪在 1.02／1.20／1.39 秒逐一停住；1.48–1.61 秒壓低音樂、暫停機械聲，再爆出能力。所有鏡頭、骨架與 PCM cue 共用局部時鐘，不改 Engine.time_scale／音高。
- 結果頁穩定等待 CONTINUE，不自動領取。等待頁需至少 160ms 並放開接受鍵／滑鼠才啟用，避免過場前長按穿透；Enter 連按不跳輪盤，Space 可明確跳過，結果不變。
- 刪除 ONE TOKEN／ONE CHANCE 等口號、密集橙色條與 XP 資訊。小型 THE DEALER 標籤、白紙黑框按鈕、桃紅 hover、青綠 pressed，結果只留核心、下一局與真能力數值。
- **舊版不是全部統一字體**：手繪標題／說明已有 HUD 字體，但獨立 CanvasLayer Button 沒有繼承共用 Theme。現在明確套用 ui_theme.build() 及 RadioPixelDisplayReadable；說明沿用 RadioPixelBodyReadable。按鈕為共用 ACTION_SIZE 32 logical／16 internal。

主要 owner：`cinematic/ability_draw.gd`、`ability_draw/timing.gd`。音效由 `tools/build_ability_rhythm_audio.py` 原創合成，可重建；原 WAV／OGG 及 GLB 都保留，長 BGM 不停止。減少特效、暫停、重開、退出沿用同一清理路徑。

[原生聲畫、畫面與測試](evidence/ability-draw/rhythm-ui/README.md)。63 項流程／輸入／節奏檢查與 22 項原模型回歸通過。Godot 4.6.3 Linux Compatibility／llvmpipe／Dummy；固定 30fps 匯出不代表即時效能，未驗使用者 Mac／真人手感或實際音效裝置。公開 Web 未更新；腰側裝備段仍未實作。
