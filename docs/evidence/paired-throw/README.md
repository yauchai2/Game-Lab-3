# 正式雙人肩摔驗證

2026-11-14（香港）。[接入與本機私有資料安裝](../../PAIRED_SHOULDER_THROW.zh-TW.md)。來源基線1beceae，本輪runtime及工具；原始FBX與可還原曲線不在公開repo。

- [12秒正式場景有聲影片](native.mp4)、[完整2fps抽格](native-review.jpg)、[實際事件](native-capture.json)。360幀／30fps，四個重置的貼近訓練fixture，各一次正常grab命令；每段start／land／hit／end各一次，健康100→88，無傷害或空中位置注入，原BGM／SFX由遊戲混音。
- [147項新檢查](verification.json)：四角×四角×雙向×兩個施技方、落地一次傷害、miss／跳走／tech／同時打擊、guard、牆邊、致命／訓練、外部中斷／phase／reset、群戰鎖定、無資料fallback、600步非grab等價；實際骨架倒轉、全蒙皮最低點、握點、停格／F2不改姿態、黑衣普通敵人及連續互換攻守。
- [33項原生檢查](render-verification.json)：32個獨立renderer蒙皮bake地面檢查＋正式session非決勝KO不重播空中tumble。CPU貼地後再用renderer結果獨立檢驗。[原生日誌](render.log)。
- [16相關腳本strict](strict.log)，七類警告當error；[正式錄影日誌](native.log)。accepted日誌無ERROR／SCRIPT ERROR，Xvfb不支援VSync的警告有保留。
- 回歸：transit216、street90、counter122、fighter style51、rivet19、service rules46、grounded death104、ink FX26，合計674；各JSON在本目錄。額外squad35、black suit35。原「Throw beats RIVET armor」即時stun斷言改驗捕捉及落地後傷害，保留原裝甲被投技打破的契約。
- [資產manifest](asset-manifest.json)只有來源／衍生SHA、裁切與私有安裝位置，不含原曲線。

新四角抽樣最大手腕間距0.025549m；蒙皮最小Y約0.009998m，落地目標0.01m。原始動作在source 84起有倒轉，runtime每個角色及朝向均另驗head低於hips。這不是手指抓布、衣物零穿插、動態地形足IK、巨型Boss摔投或360°整圈翻身驗收。

首次把需要frame_post_draw的舊視覺套件放headless會等待／出Dummy材質錯誤，已停掉並在原生顯示重跑。新增正式KO fixture最初未等首畫格便換場／退出有texture釋放錯誤；按真渲染生命週期等待首繪、逐段process及清理後33項乾淨完成，沒有把前次錯誤日誌當通過證據。

Linux Godot4.6.3 Compatibility／llvmpipe，非Mac／真人／實體控制器／目標GPU性能驗收。錄製耗時約84秒／12秒影片，Movie Writer固定FPS不是即時表現；音訊經AAC解碼量測峰值約-5.41dBFS，非靜音、無削波，但未人耳聆聽。main／公開Web未更新。
