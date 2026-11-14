# 2026-11-14：選單／彈出視窗文字像素覆核

**87項通過**：43原生介面／視窗／提示框、21語言／字形／保存、23 fatal-warning編譯。Godot4.7.2 Linux X11 dummy display、Compatibility Mesa llvmpipe、Dummy audio；實際引擎視窗與像素擷取，非使用者Mac／真人驗收。沒有部署Web。

## 修正及原因

- 原生OptionButton的PopupMenu是獨立Window／Viewport；原版公用字體getter已回報RadioBody，但實際畫面仍被柔化。其取樣值4是PARENT_NODE（繼承），不是linear常數。root為nearest不代表可以只憑root值驗收原生彈出窗。
- 所有新Viewport明確設nearest，未指定主題的Window補完整共用theme；Label／OptionButton／CheckButton／PopupMenu／TooltipLabel明確指定BODY。PopupMenu不再沿用4px描邊，避免小字輪廓堆疊。這些是整組修正，未宣稱單一設定為所有平台的唯一原因。
- 首輪掃描另發現street_whitebox探索Overlay/Help仍用engine預設字體；即使戰鬥隱藏仍補BODY。初次失敗log／JSON保留於initial。
- 字圖、fallback、字級及preset **5／8／100** 全部保持；本輪沒有重新生成任何font assets。硬度8本身保留20%coverage，不能把設計內的極少邊緣灰階當成linear柔化。

## 畫面證據

同一原生設定頁、相同字圖／字級，基線67b8e3a與修正版：

- [修正前](initial/popup-before.png)／[修正後](popup-after.png)
- 同區域nearest放大：[前](popup-before-detail.png)／[後](popup-after-detail.png)
- 相同English字區RGB色數208→52，見popup-pixel-comparison.json；只是該擷取區的描述性數據，不是所有字體的畫質門檻。
- [引擎自動TooltipLabel](pages/tooltip.png)、[設定](pages/settings-zh.png)、[雙人對戰](pages/versus-zh.png)、[城市](pages/city-zh.png)、[天賦](pages/talent-zh.png)、[故事](pages/story-zh.png)、[HUD](pages/hud-zh.png)、[結算](pages/result-zh.png)。其他頁面擷取在pages。

## 覆核範圍

實際遍歷含internal child的節點，檢查Label／Button／OptionButton／CheckButton／PopupMenu字體、各Viewport取樣及Label3D字體／取樣；設定四選單及P1/P2裝置選單皆在embedded與獨立OS視窗模式打開驗證，hover真實生成TooltipLabel。

頁面包括英／繁中主選單、設定、HOW TO PLAY、roster、labs、loadout、versus、HUD、pause、result、城市六設施、天賦與故事；晚期城市／資金及結算是明示fixture，不是遊玩賺取。語言選擇經PopupMenu公開signal，不宣稱硬件點擊routing；保留保存重啟測試。Canvas HUD／招式／抽核心／開場字幕的字體引用亦做source audit，仍經共用BODY／DISPLAY／Chinese。未啟用的舊street_dressing.show_sign_text=false系統字招牌不視為現行UI；烘焙Logo／插圖文字保留原美術，未重新繪字。

## 重跑

```sh
DISPLAY=:99 /path/to/Godot_v4.7.2-stable_linux.x86_64 --path godot --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/verify_pixel_text_audit.gd
python tools/verify_godot_warnings.py --godot /path/to/Godot_v4.7.2-stable_linux.x86_64 --output docs/evidence/pixel-text-audit/strict
```

21項語言測試用既有verify_traditional_chinese.gd的暫存副本，僅將OUT改為本目錄rules，避免覆寫歷史證據。native.log、pages/native.json、rules/rules.json、strict/strict.json及summary.json為本輪接受結果。
