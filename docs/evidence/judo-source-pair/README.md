# 使用者上傳的過肩摔配對：來源檢查

2026-11-14（香港）。來源基線28986c4。Aggressor＝施技者；Victim＝被摔者。兩檔均由使用者在聊天直接提供，本輪沒有透過MCP下載。

- [雙人原始骨架同步影片](source-pair.mp4)：960×450、30fps、201個畫格、6.70秒，無聲。原動畫關鍵範圍1–201的時間跨度為200/30＝6.667秒；影片包含最後一個畫格的顯示時間。
- [摔投詳細抽格](source-pair-contact-sheet.jpg)：12個畫格，涵蓋入身／轉肩／倒轉／落地。
- [完整時間軸抽格](full-timeline.jpg)：每15來源幀及最後一幀，已目視檢查。
- [來源雜湊、骨架與量測](inspection.json)。原FBX與逐幀動作資料在repo外私有保存，不納入公開來源。

Blender4.3.2成功匯入兩段，65骨、同名／同順序、根骨mixamorig:Hips、30fps、1–201幀；帶root位移。兩個source各201幀逐幀求值，直接按原世界座標／相同幀號投影，沒有人工對齊、各自置中或時間伸縮。首幀雙方髖距約4.415m，原片有走近過程；來源尺度不是已確認的遊戲尺度。骨架抽格可見入身、肩上翻轉及地面收尾；不表示整圈360°旋轉或手掌已精準貼合。

Blender匯入有不支援Short型user property的警告；兩個Armature／動畫均已讀取，未驗這些非骨架屬性的用途。獨立重跑提取器的metadata與兩份201幀joint樣本逐byte相同。這是來源骨架診斷，不是四角retarget、皮膚穿插、物理碰撞、落地事件、正式Godot或真人驗收。完整摔投尚未接入遊戲。

## 重現

先於repo外保存使用者兩個FBX，再執行：

```bash
blender -b --python tools/inspect_mixamo_throw_pair.py -- \
  --aggressor '/private/Shoulder Throw, Aggressor.fbx' \
  --victim '/private/Shoulder Throw, Victim.fbx' \
  --out-private /private/judo-inspection
python tools/render_mixamo_throw_diagnostic.py --private-samples /private/judo-inspection
```

提取器拒絕把逐幀資料寫入本repo。預覽工具需Pillow與ffmpeg；產物為兩角度joint診斷影片及摔投抽格，不是來源曲線。完整版抽格另外以每15幀生成。

## 下一步

以同一時間軸共同裁切，先試來源46–121幀（僅候選，未錄用）；需解決近身起播、四角身高／手臂長差、root相對位置及手部接觸。先在一組實際角色上驗入身到落地，再加入共同時鐘、一次落地結算、雙朝向、邊界／群戰／中斷與暫停清理。原始兩段與原四角GLB保持不變；不把MCP／Adobe認證當成此上傳來源檢查的阻礙。
