# 黑白街城／青粉半身封面

2026-11-10，按使用者最新截圖和兩段TR3B參考更新。保留左選單／右人物構圖，將原來佔滿背景的大車身換成有縱深的黑白切面街道、電線及桃紅天空。兩位人物以青色／桃紅色和少量暗色切面構成，無五官、無項鍊，上半身裁切、肩膀放鬆、手收口袋。

新背景是ImageGen原創宣傳插畫，不是實際戰鬥角色的模型截圖。參考影片只用作美術方向；此次附檔SHA與已保存原片相同，沿用歸檔，不重複存兩份。原始生成prompt、檔案SHA及來源見 [source.json](../references/cover-neon-city-2026-11-10/source.json)／[prompt](../references/cover-neon-city-2026-11-10/prompt.txt)。工具回傳1672×941 PNG；沒有使用付費外部供應商或聲稱game-dev CLI封裝驗證。

背景存為 `godot/assets/ui/last_service/cover-neon-city.png`，只替換 `reference_art.gd` 的TITLE。原生Logo、五選項、hover／鍵盤焦點、文字及操作提示繼續由遊戲繪製，不烘焙在背景裡。共享640×360 viewport、Nearest取樣、無mipmap令海報與介面一同呈現清晰像素邊。這是靜態封面，沒有新增GIF或循環人物動畫。

舊 `cover.png`、模型版builder及其來源紀錄均保留，其他頁面、GLB、戰鬥與持續音樂規則不變。已於Godot4.7.2 Linux Compatibility／Mesa llvmpipe完成37項介面回歸，並人工檢視640×360標題畫面；不代表使用者Mac硬件或喇叭實測。[畫面與驗證](evidence/cover-neon-city/README.md)。只更新開發來源分支，公開Web未更新。
