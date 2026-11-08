extends RefCounted
## Product copy is keyed; simulation events and save identifiers stay language-independent.
var language := "zh"
const COPY := {
"subtitle":["借勢街鬥","PRESSURE / STREET FIGHT"],
"intro":["拳腳交鋒，借勢反擊。","Build pressure. Read the stance. Turn the fight."],
"fight":["街頭對戰","Fight the rival"],"fight_hint":["單人對 AI · 先取兩勝","Solo vs AI / First to two"],
"training":["自由練習","Free training"],"training_hint":["練連段、挑空與拆招","Combos, launchers and counters"],
"drill":["交鋒教室","Pressure dojo"],"drill_hint":["先看懂，再出手。","Read first. Then commit."],
"settings":["設定","Settings"],"controls":["操作與招式","How to play"],"explore":["街區遊走","Explore the street"],
"back":["返回","Back"],"resume":["繼續對戰","Resume fight"],"paused":["稍息，再戰。","Take a breather."],
"restart":["重新開始對局","Restart match"],"reset_training":["重設練習","Reset training"],"main_menu":["返回主選單","Main menu"],
"win":["勝出！","You win!"],"lose":["對手勝出","Rival wins"],"runback":["下一場，扳回來。","Run it back."],"draw":["平手","Draw"],
"rematch":["再打一場","Rematch"],"next_round":["下一回合","Next round"],"round":["回合","ROUND"],
"you":["你","YOU"],"rival":["對手","RIVAL"],"practice":["練習對手","PARTNER"],"free":["練習","FREE"],
"energy":["能量","ENERGY"],"guard":["防禦","GUARD"],"pressure":["交鋒壓力","PRESSURE"],"ready":["可對峙","READY"],
"calm":["試探","FEEL OUT"],"heated":["升溫","HEATING UP"],"danger":["高壓","HIGH PRESSURE"],
"clash":["一招定勢","STANCE CLASH"],"read_first":["先閱讀，不限時","READ FIRST / NO TIMER"],
"begin_drill":["準備好，按 K 出重踢","READY? K TO START"],"tap_choice":["選一次，等待出招。","CHOOSE ONCE. WAIT FOR RELEASE."],
"locked":["已鎖定","LOCKED"],"press":["頂進","PRESS"],"turn":["卸勢","TURN"],"slip":["抽身","SLIP"],
"press_rule":["追上抽身","Catches slip"],"turn_rule":["反制頂進","Counters press"],"slip_rule":["避開卸勢","Escapes turn"],
"cue_press":["對手身體前傾","Rival leans in"],"cue_turn":["對手穩住重心","Rival braces"],"cue_slip":["對手準備後撤","Rival loads back foot"],
"drill_exit":["F8 再試 · F5 返回自由練習","F8 RETRY / F5 FREE TRAINING"],
"feint":["假動作","FEINT"],"feint_warning":["姿勢可能是假動作","Stances can be feints"],
"difficulty_hint":["輕鬆無假動作；標準偶爾、挑戰較常變招。","Relaxed: no feints. Standard: occasional. Challenging: frequent."],
"difficulty":["對手難度","Rival difficulty"],"relaxed":["輕鬆","Relaxed"],"standard":["標準","Standard"],"challenging":["挑戰","Challenging"],
"partner":["練習對手","Training partner"],"standing":["站立 · 示範頂進","Standing / PRESS"],"guarding":["防禦 · 示範卸勢","Guarding / TURN"],"sparring":["陪練 · 輪換選擇","Sparring / MIX"],
"audio":["聲音","Audio"],"music":["背景音樂","Music"],"sound":["遊戲音效","Sound effects"],"muted":["全部靜音 · M","Mute all / M"],"music_enable":["播放背景音樂","Play music"],
"on":["開啟","On"],"off":["關閉","Off"],"language":["語言","Language"],"zh":["繁體中文","繁體中文"],"en":["English","English"],
"accessibility":["畫面與輔助","Visuals & accessibility"],"reduced":["減少閃光與震動","Reduce flash & shake"],
"scene_edges":["場景漫畫描邊","Scene outlines"],"training_details":["顯示練習數據","Training details"],
"settings_saved":["設定儲存在此裝置。","Settings are saved on this device."],
"local":["單人 · 鍵盤操作","SOLO / KEYBOARD"],"pause":["暫停","Pause"],"help":["招式","Moves"],
"walk_title":["街區遊走","STREET EXPLORATION"],"first_person":["第一人稱","FIRST PERSON"],"third_person":["第三人稱","THIRD PERSON"],
"reference_view":["參考視角","REFERENCE VIEW"],"back_fight":["返回格鬥 · F6","BACK TO FIGHT / F6"],
"walk_hint":["WASD 移動 · 滑鼠看四周 · Space 跳躍 · H 更多操作","WASD move / Mouse look / Space jump / H more controls"],
"walk_mouse":["Esc 放開滑鼠，再按畫面繼續遊走。","Esc releases the mouse. Click the street to keep exploring."],
"walk_views":["0 返回遊走 · 1–5 / Tab 參考視角 · V 第一／第三人稱 · R 回起點","0 walk / 1–5 or Tab reference views / V first or third person / R reset"],
"walk_tools":["B 比較材質 · C 程序雲／純色 · N 圖片天空 · O 描邊 · P 飛機重播 · M 靜音","B materials / C clouds or flat sky / N image sky / O outlines / P replay flyby / M mute"],
"walk_help":["操作 · H 收起","CONTROLS / H TO CLOSE"],"style_original":["原始材質","ORIGINAL MATERIALS"],"style_two":["兩階光影","TWO BANDS"],"style_three":["三階光影","THREE BANDS"],
"sky_image":["圖片天空","IMAGE SKY"],"sky_cloud":["程序雲朵","CLOUDS"],"sky_flat":["純色天空","FLAT SKY"],
"throw":["投技","Throw"],"throw_notice":["近身投技","THROW"],"throw_tech":["拆投成功","THROW BREAK"],
"wall_tech":["受身成功","WALL RECOVERY"],"recover":["受身 · 20 能量","RECOVER / 20 ENERGY"],
"throw_help":["G 近身投技可破解防禦；對手伸手時按 G 拆投，或跳開／閃避。","G throws a nearby guard. Press G to break a throw, or jump / dodge."],
"wall_help":["被打到場邊時按 E 受身，消耗 20 能量。","Press E at the arena edge to recover for 20 energy."],
"light":["輕拳","Light"],"heavy":["重踢","Heavy"],"launch":["挑空","Launch"],"special":["能量技","Special"],
"move":["移動","Move"],"jump":["跳躍","Jump"],"dodge":["閃避","Dodge"],"parry":["防禦／精準反制","Guard / parry"],
"move_help":["A / D 左右移動，Space 跳躍。","A / D to move. Space to jump."],
"combo_help":["J 輕拳連按三段。K 重踢。W + K 挑空。","J: three-hit chain. K: heavy. W + K: launcher."],
"air_help":["挑空命中後按 Space 追上，再按 J 接招。","On launcher hit: Space to chase, then J."],
"defense_help":["Shift 防禦；抓準起手時機可反制。E 閃避。","Shift guards; time it for a parry. E dodges."],
"pressure_help":["命中、擋格及反制會升壓。高壓地面重踢可開對峙。","Hits, blocks and parries build pressure. A grounded heavy opens a clash at high pressure."],
"clash_help":["對峙時：J 頂進、Shift 卸勢、E 抽身。只鎖定一次。標準與挑戰對手可能用假動作；教室會明示選擇。","In a clash: J press, Shift turn, E slip. One commitment. Standard and Challenging rivals can feint; the dojo shows true intentions."],
"special_help":["L 能量技，消耗 50 能量。","L uses 50 energy for a special."],
"training_title":["自由練習","FREE TRAINING"],"last_combo":["上次連段","LAST COMBO"],"hits":["連擊","HITS"],"damage":["傷害","DAMAGE"],
"inputs":["輸入紀錄","INPUT HISTORY"],"none":["尚未出招","No inputs yet"],"impact":["命中停頓","IMPACT"],
"stage":["航道街口","FLIGHT PATH / CROSSING"],"wins":["先取兩勝","FIRST TO TWO"],
"result_press":["頂進命中","PRESS CONNECTS"],"result_turn":["借勢反擊","TURN COUNTER"],"result_slip":["抽身成功","SLIP ESCAPE"],
"perfect_guard":["精準防禦","PERFECT GUARD"],"guard_break":["防禦崩解","GUARD BREAK"],"counter":["反擊命中","COUNTER HIT"],
"air_chase":["追上去！Space → J","AIR CHASE / SPACE → J"],"fight_start":["開打！","FIGHT!"],
"no_meter":["能量技需要 50 能量","SPECIAL NEEDS 50 ENERGY"],"reset_notice":["練習已重設","TRAINING RESET"],
"tie":["勢均力敵 · 壓力解除","EVEN / PRESSURE RELEASED"],"your_result":["你","YOU"],"rival_result":["對手","RIVAL"]
}
func text(key: String) -> String:
    var values: Array=COPY.get(key,[key,key])
    return values[0 if language=="zh" else 1]
func notice(raw: String) -> String:
    if raw.begins_with("FEINT / "):return text("feint")+" · "+notice(raw.trim_prefix("FEINT / "))
    var notices := {"THROW":"throw_notice","THROW TECH":"throw_tech","WALL TECH":"wall_tech","PERFECT GUARD":"perfect_guard","GUARD BREAK":"guard_break","COUNTER HIT":"counter","AIR CHASE / J TO FOLLOW UP":"air_chase","FIGHT!":"fight_start","SPECIAL NEEDS 50 ENERGY":"no_meter","TRAINING RESET":"reset_notice","EVEN / PRESSURE RELEASED":"tie"}
    if notices.has(raw):return text(notices[raw])
    for choice in ["press","turn","slip"]:
        if raw.ends_with("/ "+choice.to_upper()):return text("your_result" if raw.begins_with("YOU") else "rival_result")+" · "+text("result_"+choice)
    return raw
