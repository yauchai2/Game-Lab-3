# 開放音訊來源

2026-11-07 取自官方資產頁，保存作者提供的 CC0 授權文字。音檔位於 `godot/audio/open/`，固定檔案與 SHA-256 見 [manifest.json](manifest.json)。原始大型 ZIP / WAV 不入庫。

- 音樂：**Juhani Junkala — Retro Game Music Pack / Level 1**，來源 [5 Chiptunes (Action)](https://opengameart.org/content/5-chiptunes-action)，CC0 1.0。74.3 秒，轉換為 44.1 kHz Vorbis，FFmpeg loudnorm I=-18 / TP=-2 / LRA=9，quality 4；Godot 啟用循環。
- 音效：**Kenney — Impact Sounds**，來源 [官方資產頁](https://kenney.nl/assets/impact-sounds)，CC0 1.0。14 個 OGG 原檔用於拳擊、格擋、破防、腳步與落地；遊戲中調整播放速度／音量。能量蓄力和低頻層為本專案程序合成。

授權原文：[Juhani](../../godot/audio/open/LICENSE-Juhani.txt)、[Kenney](../../godot/audio/open/LICENSE-Kenney.txt)。未使用 Lethal League Blaze 的音樂、音效或圖像素材。

## 指定音樂研究（尚未錄用）

使用者指定 wev／worldwidewev，並確認尚未取得授權，先做選曲及接入規劃。已查公開曲目／授權 metadata，見 [worldwidewev](worldwidewev/README.md)；沒有下載／加入其音訊，以上 CC0 音樂與音效維持現版。

## 2026-11-12 音訊重做
`godot/audio/sfx/` 為原創程序合成（`tools/build_combat_sfx.py`），`godot/audio/music/` 為 Starjunk 95 曲目的剪輯循環（`tools/build_music_loops.py`，出處見該資料夾 provenance.json）。Kenney 檔案保留為缺檔 fallback。詳見 [docs/AUDIO_OVERHAUL.zh-TW.md](../../docs/AUDIO_OVERHAUL.zh-TW.md)。

**2026-11-12 更新：** 遊戲內音樂已全部改為 Alan 提供的 Jet Set Radio 風格合輯 mp3 的剪輯（`godot/audio/music/`，`tools/build_playlist_music.py`），作者與授權未知，視為使用者提供並授權，不聲稱 CC0。前述 Starjunk 95 的剪輯循環已移除。
