# Mixamo MCP：已安裝、連線驗證與下一步

## 2026-11-13 更新：採用使用者指定的 HaD0Yun Mixamo MCP

已在雲端安裝[指定專案](https://github.com/HaD0Yun/unity-mcp-mixamo/blob/master/README_EN.md)的獨立Python Server，固定來源commit `6170d5eca609eb5cdbbbd6b1a3fc6276362f6701`。不需Unity；下載時明確指定repo外的outputDir，取得FBX後才進Godot配對／重定向。Playwright保留作官網預覽備援。

實測JSON-RPC initialize、tools/list通過，共6工具：mixamo-config、mixamo-auth、mixamo-search、mixamo-download、mixamo-batch、mixamo-keywords。combat關鍵字工具回應正常；auth回報未存token，Shoulder Throw搜尋回報未認證，不能當官方目錄查詢成功。無憑證HTTP讀取 `https://www.mixamo.com/api/v1/products` 仍為 `httpx.ProxyError: 403 Forbidden`。證據：[direct-server.json](evidence/mixamo-mcp/direct-server.json)。

### 安裝時實際修正

- 上游僅要求mcp>=1，首次解析到2.3.0會在list_tools decorator報AttributeError。此環境改固定 `mcp==1.30.0` 後成功；pip check通過。
- 上游client的除錯print會混入stdio通訊。[launcher](../tools/run_mixamo_mcp.py)將該模組print導向stderr，並設umask077；沒有修改下載API或繞過網路政策。
- 上游根LICENSE寫BSD-3-Clause，pyproject／Server README寫Apache-2.0，根README曾寫MIT；標示不一致，保留原LICENSE，不將其當Adobe素材授權。

### 已註冊的雲端設定

名稱 `mixamo-direct`，命令為雲端私有venv Python加本repo launcher。來源／venv在 `/workspace/shared/had0yun-mixamo-mcp/`；不commit第三方程式、venv、token、登入狀態或FBX。這是雲端Codex CLI設定及直接協議驗證，未熱載入宿主對話工具，亦未安裝使用者Mac。

另一台電腦需在該電腦安裝固定commit的 `Server/` 及 `mcp==1.30.0`，再用該venv Python執行本launcher；Linux路徑不能直接複製當Mac路徑。

### 登入及真正下載的剩餘條件

此社群server不是Adobe官方OAuth登入服務，不能自動沿用另一台電腦Chrome的登入。它讀取執行server的使用者家目錄 `~/.mixamo_mcp_token`。使用者在Mixamo自行登入後，應透過私有終端／秘密設定把token放到**同一主機**的該檔，檔案權限600；不要貼聊天、不要放MCP設定明文參數或公開repo。原mixamo-auth帶token參數可能被客戶端記錄，這裡未用它傳送任何憑證。

網路放行仍須實際生效；若設定已加但此環境仍403，需在環境管理介面確認套用至目前執行環境。下載CDN只按實際返回URL確認，不預先猜測網域。網路和認證皆可用後，才搜尋Shoulder Throw, Aggressor／Victim、核對完整時長／同角色／30fps／root、下載並量測接觸與落地。MCP目前export預設FBX2019、skin=true、30fps、無減key；並不保證兩段已同步。完整柔道摔投仍未完成，Godot／Web未改。

---

2026-11-13。使用者要求使用MCP，採Microsoft官方Playwright MCP，固定版本`@playwright/mcp@0.0.85`。沒有購買素材、沒有使用第三方Mixamo鏡像；完整柔道摔投仍待取得官方配對檔及實作。

## 本輪實際完成範圍

| 檢查 | 結果 |
|---|---|
| 安裝官方npm套件 | 成功，雲端`/workspace/shared/mixamo-mcp-runtime`，不是使用者Mac |
| 註冊Codex CLI MCP | 成功，名稱`playwright-mixamo`，設定在本執行環境的`~/.codex/config.toml` |
| 從註冊的啟動命令作JSON-RPC initialize／tools/list | 成功，25個工具；協議2024-11-05，server回報Playwright 1.66.0-alpha-2026-11-09 |
| MCP瀏覽器開頁／點擊 | 成功開官方GitHub repo並點Skip to content，URL變為`#start-of-content`；部分網頁資產因網路限制有console錯誤，不宣稱整站零錯誤 |
| Mixamo官網 | MCP報`net::ERR_TUNNEL_CONNECTION_FAILED`；獨立HTTP讀取報`Tunnel connection failed: 403 Forbidden` |
| Adobe登入、下載FBX、雙人同步／遊戲接入 | 尚未到達／完成 |
| 使用者本機已登入Chrome／擴充功能 | 尚未連接；雲端安裝不會自動接上本機瀏覽器 |

證據：[evidence/mixamo-mcp/setup.json](evidence/mixamo-mcp/setup.json)。實際呼叫官方MCP server的JSON-RPC `initialize`、`tools/list`與`tools/call`，不是僅建立一份未測設定。為本輪驗證建立的本地HTTP頁經proxy回403、data URL被管理政策拒絕，沒有繞過政策；改以允許的GitHub頁驗證開頁／點擊。原CUA啟動錯誤不再是本輪MCP瀏覽器的障礙，現在是Mixamo網路存取。

註冊的是**雲端Codex CLI設定**，不等於當前託管對話原生工具清單已熱載入，也不等於使用者本機客戶端已安裝。驗證透過本地協議橋接呼叫MCP完成，runtime與私有profile不納入遊戲repo。

## 路線A：繼續用此雲端MCP

1. 在此雲端環境的網路允許清單加入`mixamo.com`與`www.mixamo.com`。目前官方目的地被proxy拒絕；本輪沒有可用的環境網路變更工具，不能由聊天內直接改此政策，也不以其他proxy／停驗證繞過。
2. 規則生效後，再用MCP開Mixamo。若Adobe登入或素材CDN有其他被拒絕網域，按實際請求補上所需網域；不預先開放整個網際網路。
3. 官網可用後，由使用者在同一個瀏覽器自行登入Adobe，代理不接收密碼／驗證碼。共享桌面可由支援介面的側欄Desktop觀看與接管，實際可用性仍需確認。
4. 再搜尋Shoulder Throw, Aggressor／Victim，核對官方預覽並下載同角色、同FPS、完整時長與root motion的配對。先檢查相對起點／接觸／翻身／落地，再做Godot樣板。

雲端私有profile與下載在`/workspace/shared/mixamo-mcp-runtime/`；不要commit profile、cookies、登入快照、FBX或可重用受限動畫曲線。只同時啟動一個使用相同profile的MCP實例，避免profile鎖衝突。

## 路線B：用使用者本機已登入的Chrome／Edge

如果要接的是本機，而非這個雲端桌面，MCP server與支援它的代理客戶端必須在可連到該瀏覽器的主機執行。雲端的localhost不是使用者Mac的localhost，不能僅靠在Mac安裝擴充功能就宣稱雲端已連接。

已提供[tools/setup_mixamo_mcp.sh](../tools/setup_mixamo_mcp.sh)，供本機Codex CLI使用：

```bash
bash tools/setup_mixamo_mcp.sh --print
bash tools/setup_mixamo_mcp.sh
```

前提是本機已有Codex CLI、Node.js與npx；script只加入名為`playwright-mixamo`的官方MCP，固定0.0.85並用`--extension`模式。已有同名設定時不覆寫；`--print`不註冊或建立資料夾。下載預設放使用者資料目錄的`game-lab-3/mixamo-downloads`，在repo外並設私有權限。

之後按[官方Playwright瀏覽器連接文件](https://playwright.dev/mcp/configuration/browser-extension)安裝Playwright Extension、重新載入MCP客戶端並選擇正確分頁。使用者自行在該瀏覽器登入Mixamo，再由可操作本機工具的代理驗證連接。本輪只在Linux做script語法與`--print`測試；沒有執行使用者Mac、安裝其擴充功能或宣稱其Adobe已登入。

## 驗證界限與來源

- [官方Playwright MCP](https://github.com/microsoft/playwright-mcp)：功能／安裝／Codex設定；[官方擴充連線說明](https://playwright.dev/mcp/configuration/browser-extension)。沒有採用未審核的Mixamo社群MCP程式碼。
- [Adobe Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)：免費Adobe ID與遊戲商用。免費不是CC0，仍需確認素材使用與原檔散佈規範。
- 新增helper以`bash -n`及`--print`驗證，候選／證據JSON解析通過；沒有修改Godot／動畫資料，沒有重跑前輪674遊戲檢查，也沒有將MCP驗證當作完成柔道摔投。
- 本輪來源基線2b413bc；查得遠端main f69fc9f，未合併、未發佈Web。接續狀態以本文件及HANDOFF最新節為準。
