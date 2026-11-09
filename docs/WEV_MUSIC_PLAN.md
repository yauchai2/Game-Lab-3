# wev／worldwidewev：選曲與音訊接入計劃

## 最新狀態：使用者確認可用（2026-11-09）

使用者最新明確表示「wev 音樂已可用」，後續按此確認推進遊戲選曲／接入，不再沿用「尚未取得、只能規劃」作為阻塞。此為使用者提供的可用狀態，未聲稱獨立查驗授權文件或整個藝術家目錄。

目前工作區只有既有 CC0 音檔，未找到 wev 的 WAV／MP3／FLAC／OGG；本訊息也未附音檔或新的可下載素材連結。下一步需要使用者提供可用音檔／素材包或直接下載連結，以確認實際曲目，才可量測音量、選循環點及替換遊戲曲目。不抽取 SoundCloud 串流，不擅自購買或聯絡藝術家。

素材到位後優先試戰鬥主曲 GET W THIS／K.I.P.、選單 THE WEVALUDE、短入場 HELLO WORLD／SELECTA，依實際提供曲目與實聽調整。保留獨立音樂／音效音量與 CC0 fallback；使用者確認可在遊戲使用，不額外推定可將原始母帶公開到 GitHub，沿用下方私人素材包與公開程式分離設計。公開試玩仍需另行點名才更新。

以下保留先前研究與當時狀態，歷史的「尚未取得」不覆蓋以上最新確認。

2026-11-09。使用者指定 [worldwidewev](https://soundcloud.com/worldwidewev)，允許替換現有音樂／音效；其後明確確認：**「尚未取得，先完成選曲及接入規劃」**。本輪只研究公開資料，不下載音樂母帶／串流、不購買、不聯絡藝術家，也不改現有遊戲音訊。

## 1. 已核實甚麼

公開頁面均取得 HTTP 200：[SoundCloud](https://soundcloud.com/worldwidewev)、[藝術家網站](https://wev.world)、[Bandcamp《OST》](https://worldwidewev.bandcamp.com/album/ost)、[Bandcamp 音樂目錄](https://worldwidewev.bandcamp.com/music)、[官方專輯 smartlink](https://createmusic.fm/OST)，以及下列兩首 SoundCloud 頁。只保存必要的曲目及授權欄位，沒有保存追蹤識別碼或媒體串流網址；[完整正規化資料](../references/audio-sources/worldwidewev/catalog.json)含來源、擷取時間與回應雜湊。

《OST》頁標示 2026-05-29 發行、15 首，專輯／曲目 JSON-LD 顯示 All Rights Reserved。公開標籤含 electro、garage house、house music、jungle、UKG、VGM。這支持其為本遊戲的**風格試聽候選**；不是已完成實聽或聲學分析。

| SoundCloud 已讀作品 | 頁面資料 | 決定 |
|---|---|---|
| [MINMI - shiki no uta (wev edit)](https://soundcloud.com/worldwidewev/minmi-shiki-no-uta-wev-edit-1) | 約 5:50；改編曲；All rights reserved；downloadable=false；連到 Bandcamp | 暫不列首批接入，需釐清原曲及改編相關權利 |
| [OST ALBUM RELEASE @ The Lot Radio 05-29-2026](https://soundcloud.com/worldwidewev/wev-ost-album-release-the-lot) | 約 61:45；House／electro／jungle／UKG 等標籤；All rights reserved；downloadable=false | 可作聆聽方向參考，不把整段混音當遊戲可用原曲包 |

不能把 Bandcamp 的 downloadable 旗標或購買下載視為遊戲使用授權。也不能因專輯名叫 OST，就推定它可供其他遊戲使用。只查了上述頁面，沒有宣稱整個藝術家目錄都是相同授權。

## 2. 第一批試聽名單

以下用途是**按長度／曲目定位安排的試聽假設**，不是已聽出某段 drop、已量測 BPM 或已選定循環點。點開來源可自行試聽；真正錄用前再比較人聲密度、鼓點、低頻、可循環性及遊戲事件辨識。

| 優先 | 曲目／公開長度 | 擬試位置 | 要確認的問題 |
|---|---|---|---|
| 1 | [HELLO WORLD](https://worldwidewev.bandcamp.com/track/hello-world)／10.01 秒 | 啟動／首次入場的短篇候選 | 能否在約 1–3 秒內建立識別，跳過時是否可自然截斷 |
| 1 | [SELECTA](https://worldwidewev.bandcamp.com/track/selecta)／12.80 秒 | 選角確認／VS 短篇候選 | 是否適合 3–8 秒版本；不可僅因名字就當選角音效 |
| 1 | [GET W THIS](https://worldwidewev.bandcamp.com/track/get-w-this)／4:04.28 | 正式戰鬥主循環候選 A | 連打時仍否聽到格擋、蓄力及命中；能否找穩定樂句 |
| 1 | [K.I.P.](https://worldwidewev.bandcamp.com/track/k-i-p)／3:42.98 | 正式戰鬥主循環候選 B | 與 A 比較重量、低頻遮蔽、反覆重賽疲勞 |
| 2 | [CAN'T SHAKE THIS](https://worldwidewev.bandcamp.com/track/cant-shake-this)／3:36.76 | 對戰或練習備選 | 人聲與重音是否搶走戰鬥提示 |
| 2 | [THE WEVALUDE](https://worldwidewev.bandcamp.com/track/the-wevalude)／5:20.97 | 標題／選角長循環備選 | 是否有較疏落段落；仍要實聽，不按名稱推斷內容 |
| 2 | [LONELY BOY](https://worldwidewev.bandcamp.com/track/lonely-boy)／4:06.84 | 標題／結果備選 | 結果短停留是否適合，或應保持原對戰曲尾聲 |

首批只需一首對戰主曲、一首選單候選及一個短篇；先控制授權與切換成本。合作曲 SPECTRUM、WITMYBABY、TECHNOCHRONIC、COME UNDONE、BAD BOY MUSIC 暫列第二批，需核實共同權利及各方署名。單一藝名曲目也仍須確認是否含第三方取樣。

## 3. 授權與母帶：甚麼資料齊了才可錄用

授權範圍需清楚涵蓋指定作品的錄音與詞曲、遊戲內互動使用／同步、循環／剪輯／淡入淡出／濾波等改作、遊戲內音訊檔散布、PC 原生與未來 Web、測試版／正式版、地區／期間、商業與否、宣傳影片及玩家直播／Content ID 處理，以及第三方取樣與共同創作者。

公開 GitHub 的原始碼與可下載遊戲是不同散布情境。優先用**不公開的音訊素材包＋公開接入程式**：合法母帶放在將來的本機忽略目錄，公開 repo 保留 manifest／credits 與可用的 CC0 fallback；取得明確允許原檔公開的授權才考慮提交音檔。Web 的 OGG 亦可被下載，不能把壓縮／加密當授權替代。

可向權利方提出的具體需求（只是備忘，未寄出）：

> 一款港式街頭 2.5D 近身格鬥遊戲，希望使用《OST》中的指定曲目，首批評估 GET W THIS／K.I.P.、HELLO WORLD／SELECTA。需要 PC 遊戲及未來 Web 試玩內使用，並能剪成循環、短入場、動態混音。請說明母帶／詞曲與取樣是否可一併授權、授權期間／地區／費用、署名、宣傳／直播與原始素材再散布限制。公開程式碼可與授權音檔分開提供。

母帶優先 WAV 44.1／48kHz、16／24bit，保留原檔與 SHA-256；有官方 instrumental／stems 可一併評估。沒有 stems 時不假裝可拆出乾淨鼓組，也不擅自用 AI 分離人聲／取樣。

## 4. 音訊架構怎樣接

現況 `fight_audio.gd` 只有一個循環 `level1.ogg`，依 context 改音量，並用 10 個聲道播放動作音效。下一輪抽出單一 MusicDirector，FightAudio 保留遊戲事件介面：

- `Music`：兩個可交接的播放器或經驗證的同步流；保留共用播放時鐘。
- `SFX`：拳、腿、格擋、破防、落地；按事件優先級分配有上限的聲道。
- `UI`：移動焦點、確認／返回，避免與戰鬥音效互相搶聲道。
- `Stingers`：入場／勝負短篇，獨立限制同時播放數。
- `Master`：保留餘量及最後峰值保護，不能用 limiter 掩蓋全場過響。

曲目資料含 `track_id, artist, title, source_url, license_ref, master_sha256, import_path, cue_role, bpm, first_downbeat, loop_start/end, loudness, true_peak, credits, admission_status`。未量測的 BPM／循環點為 null；未授權的 import_path 為 null。候選曲不能因被列在 manifest 就成為可播放素材。

| 遊戲狀態 | 混音行為 |
|---|---|
| 標題／選角 | 較低音量，長循環；確認短篇不重啟整首主曲 |
| 入場／VS | 約 0.2–0.4 秒交接，經許可的短篇；跳過可自然落入戰鬥曲 |
| 正常對戰 | 同一播放頭持續；不每次出拳、格擋或回合重開都從頭播 |
| 高壓／空連 | 有 stems 才加層；沒有則有限 EQ／音量變化，不能用 pitch_scale 加快音樂冒充升壓 |
| 接觸停頓 | 音樂繼續走；保留 20–40ms 的局部短空隙給重擊，普通輕拳不要每拳抽空 |
| 重擊／暴扣 | Music duck 約 3–6dB、80–160ms；連續觸發有最小間隔，避免永久壓低 |
| KO／結果 | 先突出確定的命中及落地，再接勝負短篇；只播一次，保留重賽清理 |
| 暫停／失焦／靜音 | 保持原設定語義；音訊不因玩法 hitstop 一起停止，真正暫停才保存／恢復播放位置 |

音樂節拍只協調裝飾與跨曲交接，**命中／格擋音必須立即響**，不等下一拍。玩家不必跟 BPM 才可贏。

播放時間可用播放器位置加混音時間、減輸出延遲估算，但要實測後端誤差。若有同長度對齊 stems，先驗證 Godot 4.6 的同步流路徑及 loop 行為；不能靠同一幀連續呼叫兩次 `.play()` 就宣稱 sample-accurate。暫停／seek／跨回合的起點都要檢查。

## 5. 製作、音效與混音規格

先在授權母帶上量測，不按壓縮串流估計。音樂起點可試約 −18 LUFS-I、≤−1.5dBTP；這是製作目標而非現有歌曲量測值。長樂句循環點依實聽與零交越／尾音處理；取得 BPM 後才做整小節切換。OGG 用於成品，母帶保留在合法素材包。

交叉淡化可用等功率曲線，但相似／相關的訊號仍可能加峰，保留至少數 dB 餘量並實測總和。不得讓兩份同曲副本反覆觸發而累積音量。4–6 層低頻同時疊加會遮蔽腳步，重點是頻率分工與時序，不是每次再加 sub。

使用者允許換全部音效；首批重做「起跳、追擊、三拍拳腳、格擋換手、暴扣、受身、KO」的音色家族，優先原創合成或已有可散布授權資源。wev 音樂授權若不含音效取樣，就不從歌曲抽鼓／人聲做招式。

在設定／credits 顯示藝術家與錄用曲名，保留獨立音樂／音效音量、靜音與 F4；戰鬥中不彈外部促銷或要求登入 SoundCloud。

## 6. 接入與驗收順序

1. **已完成**：來源頁、15 首目錄、兩首 SoundCloud 權利欄位、使用者尚未取得授權的回答，保存到 catalog。
2. **待實聽**：按候選表比較，選主曲 A／B 及最少短篇；在遊戲命中聲上試聽，不單獨聽歌就決定。
3. **待授權／母帶**：權利文件、適用曲目、可改作與散布範圍、credits；沒有就維持 CC0 fallback。
4. **接入框架**：用現有合法音檔驗證 buses、MusicDirector、交接、pause、duck 和路徑缺失 fallback；這是未來工作，本輪未改程式。
5. **正式換曲**：合法音檔正規化、雜湊、實際循環點及曲目狀態逐件錄用；不把整個專輯直接塞入遊戲下載。
6. **驗收**：耳機／喇叭實聽；至少 20 次選單↔對戰↔結果、失焦／mute／volume 0、快速重賽，沒有重播／疊曲／點擊爆音；長樂句循環及 duck 恢復正常。全開輸出量測不削波，畫面強度不影響聲音邏輯。

音訊測試需真的錄製／聆聽。既有 Dummy 驅動與 316／79 項邏輯檢查不等於新版音訊實聽或授權已完成。公開 Web 仍只有使用者另行點名才更新。
