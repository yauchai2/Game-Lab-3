# 網頁試玩版

**GitHub 試玩網址：https://yauchai2.github.io/Game-Lab-3/ （已啟用並建置成功，2026-11-08 核對）**

2026-11-07，使用者要求一條網址可分享朋友直接試玩。使用現有 Godot 遊戲匯出，沒有重寫成另一款網頁遊戲。

## 試玩方式

分享頁按「開始試玩」，下載後 Enter 對戰，或選練習模式。桌面鍵盤：A/D 移動、Space 跳躍、J/K 輕拳／重踢、W+K 挑空、L 能量技、Shift 防禦、E 閃避、Esc 暫停。M 靜音、F4 音樂、F2 減少演出、O 場景描邊、F6 原街景。提供全螢幕、複製網址和素材授權頁。

目標是現代電腦 Chrome / Edge / Firefox，WebGL 2、WebAssembly 及 DecompressionStream；需鍵盤。未加入手機觸控操作、線上雙人或帳戶系統。第一次約下載 19 MB（十進位），無需安裝 Godot。瀏覽器若未播放聲音，可點遊戲畫面或按 Enter。失焦仍由原遊戲暫停流程處理。

## 匯出與更新

Godot 4.6.3 官方 `web_nothreads_release.zip` 模板 SHA-256：`1446f79dc12f60ce5d244c39fb6628ec298337ca5c4f91a16491feea72aa1bc9`，來源 `godotengine/godot-builds` release `4.6.3-stable`。專案 `godot/export_presets.cfg` 使用 Web / Compatibility、單執行緒、不使用 GDExtension 或 PWA，不需要 SharedArrayBuffer 或 COOP / COEP。桌面紋理格式，沒有承諾手機相容。

```sh
python tools/build_web.py --output /absolute/output/dist
node tools/verify_web_build.mjs /absolute/output/dist
godot --headless --main-pack /absolute/output/dist/game.pck --script /absolute/repo/godot/tools/verify_web_pack.gd
```

Raw JSON 動畫須經 `include_filter` 打包，否則 FileAccess 在匯出遊戲找不到動作資料。`tools/*` 和 Web 原始頁面不進 PCK；遊戲、F6 所需資源、音樂／音效均有保留。

標準引擎 Wasm 37,700,666 bytes，超過靜態託管的單檔上限，因此以可重現 gzip 壓縮（mtime=0）供應。頁面只攔截此引擎請求，以 Web DecompressionStream 還原並交給原 Godot 載入器；不修改引擎 JS 或 Wasm。壓縮資料往返雜湊及 WebAssembly 編譯有驗證。其餘檔案按原路徑供應；沒有自行依賴 Content-Encoding 標頭。

`release-manifest.json` 保存來源 Git commit、每件發佈資產大小／SHA-256。主遊戲源碼仍在 GitHub `codex/street-combat`；Site 使用獨立新目錄 `/workspace/sites/afterhours-playtest`，只部署必要 Web 檔與授權，不上傳來源對話、證據影片或整個工作區。

Site ID：`appgprj_6aee92bb6674819187ce9ab3477fd56b`，分享要求授權任何取得網址的人開啟，因此設定 `public`，不收集朋友 email 或傳送邀請。這是單人試玩頁，沒有多人伺服器。

## 驗證範圍

Web release 匯出成功；實際匯出的 PCK 在 Godot native runtime 完成 8 項資源／動畫／戰鬥／F6 往返檢查。Node 原生 WebAssembly 編譯、Web Streams gzip 還原、HTML JS 語法及所有資產雜湊檢查通過。這些都不等於瀏覽器 WebGL 實際遊玩。

環境的 Sites helper 腳本及 cua_repl.js 未提供，`sites-preview status` 回傳 `preview relay unavailable: No such file or directory`。按 Sites 技能指示不另起預覽或另裝瀏覽器替代；因此瀏覽器 QA 未驗證。使用普通 Git 同步此新 Site 的精確來源狀態與 native Sites 存檔／發佈工具，憑證只經記憶體及隱藏 stdin 傳入，沒有寫入 repo。

日誌見 [Web 證據](evidence/web/)。實機瀏覽器的啟動、音訊、速度和手機仍需朋友試玩確認；不將 Native PCK 測試或部署成功宣稱為硬體效能／真人驗收。

## 公開發佈結果

Sites version 1 已發佈成功，current_live_url 與分享權限 public 均由 native API 確認。Site source commit `3dcb8dc567a733c0bab481c17a6a98432344f80f`，對應 GitHub 遊戲來源 `77c00267b3fa7d72bf9ea61a18d6f29ecbd1135d`。部署及資產雜湊見 [紀錄](evidence/web/deployment.json)、[release manifest](evidence/web/release-manifest.json)。

匿名 HTTP 自動下載的每件資產均回應 Cloudflare 403 / error code 1010，未取得實際內容，不能當作資產線上驗證成功；沒有繞過防機器人檢查。`tools/verify_web_url.py` 可在正常連線環境按 manifest 再查。平台公開發佈成功與自動 HTTP／實際瀏覽器驗證是不同證據。瀏覽器啟動和聲音仍待實機確認。

## 改用 GitHub Pages（2026-11-07，香港時間）

使用者要求使用 GitHub 的遊戲網址，取代 ChatGPT 網址作主要分享入口。已將同一份經驗證 Web export 推送至 `gh-pages`，提交 `c663ec5f8fbe77b99bfa311823d300b9aedaa5dc`，根目錄有 `index.html`、原遊戲 PCK、壓縮引擎、音訊 worklet、素材授權與 `.nojekyll`。分支與遊戲原始碼分開，沒有合併或改動 main。未刪除舊 Sites 發佈，前面章節保留其歷史結果。

儲存庫為 public，API 顯示帳戶對 repo 有 admin，但目前 integration 無權設定 Pages：`POST /repos/yauchai2/Game-Lab-3/pages` 回應 `403 Resource not accessible by integration`。Pages 尚未啟用，網址實測 404；不能聲稱已上線。API 訊息與分支來源記錄於 [部署準備](evidence/github-pages/deployment-readiness.json)。這是連接授權範圍限制，沒有索取 token、繞過權限或改動其他帳戶設定。

帳戶擁有人只需：

1. 開啟 [Settings → Pages](https://github.com/yauchai2/Game-Lab-3/settings/pages)。
2. Build and deployment 的 Source 選 **Deploy from a branch**。
3. Branch 選 **gh-pages**，資料夾 **/(root)**，按 **Save**。
4. 等待 GitHub 顯示發佈成功，再分享 https://yauchai2.github.io/Game-Lab-3/ 。

之後更新 `gh-pages` 的靜態輸出，GitHub 會按此設定重新部署。使用專案子路徑 `/Game-Lab-3/`；已對實際匯出 fetch adapter 在根路徑和此子路徑各執行 WebAssembly.compileStreaming，並核對 15 件資產雜湊。未改動遊戲程式或二進位，原匯出包 8 項檢查仍適用。此結果不是 GitHub 線上啟動或瀏覽器遊玩驗證。

Pages 啟用後可執行：

```sh
python tools/verify_web_url.py https://yauchai2.github.io/Game-Lab-3/ docs/evidence/web/release-manifest.json
```

## 2026-11-08 接續確認

GitHub Pages 現已啟用：branch gh-pages / root、status built、HTTPS。舊版匿名 HTTP 資產 15/15 雜湊通過，Chromium WebGL 實際啟動與鍵盤畫面驗證通過；前述 404／待啟用是歷史狀態。這輪練習、追擊及 Web 操作改善見 COMBAT_POLISH.md，新版公開驗證另補記。

## 最新遊戲完善版（2026-11-08）

已公開更新：Pages 2908503 / 遊戲來源 e2c7e10。Enter 對戰、T 無限練習；F5 重置、F7 對手，挑空命中後 Space → J，難度／音效／演出設定保存在本機。15/15 線上資產、154 項 native／匯出檢查及 7/7 真實 Chromium WebGL 自動流程通過，IndexedDB 寫入與重新載入已驗證。這取代早期「瀏覽器尚未驗證」的目前狀態；歷史失敗紀錄保留。詳見 COMBAT_POLISH.md。
