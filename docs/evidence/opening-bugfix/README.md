# 開場 polygon／GDScript 截圖錯誤修正（2026-11-12）

基線：main d5ecbf3。眼鏡 glint 在14.55秒起 radius=0，細小三角形亦受全局HUD座標精度影響。未修正的burst在相同12種半徑／24組ray-spin fixture重現340筆triangulation ERROR（臨時載入原guard及polygon繪製）。僅略過半徑<1仍會在小型ray失敗；最後改用draw_primitive直接提交三角形，並略過不可見半徑／alpha。

- `bursts.log`：12種半徑（0至720）×24組ray/spin＝288組原生canvas繪製，零ERROR／SCRIPT ERROR。Python runner會在engine exit 0但log有錯時失敗，拒絕headless dummy。
- `strict/strict.json`／`strict.log`：19/19腳本、七種warning設Error，包含本輪confusable_local_declaration／unused_parameter／standalone_ternary，零ERROR／SCRIPT ERROR。修正title外層u、_draw_slam未用參數、clear_equipment獨立ternary。
- `flow.log`：既有開場／暫停／skip／存檔／FREE PLAY重播37/37。
- `capture.log`：15個真3D抽格（包含14.55、14.55001、14.5501、14.56、14.75、14.94999），零ERROR／SCRIPT ERROR；`glint.png`保留正常亮點畫面。

重跑（有X11 display）：

```sh
python tools/verify_godot_warnings.py --output /tmp/opening-strict
python tools/verify_story_opening_bursts.py --output /tmp/opening-bursts.log
godot --rendering-driver opengl3 --audio-driver Dummy --path godot --script res://tools/verify_story_opening.gd
```

Godot4.6.3 Linux／Compatibility OpenGL／llvmpipe／Dummy音訊。使用者截圖版本4.7.2及Mac硬體仍待覆核；未聲稱本機已同步。Web未更新。
