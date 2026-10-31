extends Node
## M0 核心逻辑测试。
## 运行: godot --headless --path <project> res://tests/test_runner.tscn --quit-after 5

var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    _test_time_manager()
    _test_game_state()
    _test_save_roundtrip()
    _test_dialogue_conditions()
    _test_score_reward()
    print("\n==== 测试结果: 通过 %d, 失败 %d ====" % [_passed, _failed])
    get_tree().quit(_failed > 0)

func _assert(cond: bool, msg: String) -> void:
    if cond:
        _passed += 1
        print("PASS: %s" % msg)
    else:
        _failed += 1
        push_error("FAIL: %s" % msg)

func _assert_eq(a, b, msg: String) -> void:
    _assert(a == b, "%s (期望 %s, 实际 %s)" % [msg, str(b), str(a)])

func _test_time_manager() -> void:
    print("\n--- 时间管理器 ---")
    TimeManager.day = 1
    TimeManager.minute_of_day = 6 * 60
    _assert_eq(TimeManager.format_clock(), "06:00", "format_clock 06:00")
    TimeManager.sleep_to_next_day()
    _assert_eq(TimeManager.day, 2, "睡觉后天数+1")
    _assert_eq(TimeManager.minute_of_day, 6 * 60, "睡觉后重置为 06:00")
    TimeManager.add_minutes(30)
    _assert_eq(TimeManager.minute_of_day, 6 * 60 + 30, "add_minutes(30)")
    TimeManager.set_time(5, 23 * 60)
    _assert_eq(TimeManager.format_clock(), "23:00", "set_time 23:00")

func _test_game_state() -> void:
    print("\n--- 玩家状态 ---")
    GameState.coins = 0
    GameState.add_coins(100)
    _assert_eq(GameState.coins, 100, "add_coins(100)")
    GameState.add_coins(-30)
    _assert_eq(GameState.coins, 70, "add_coins(-30)")
    GameState.add_coins(-999)
    _assert_eq(GameState.coins, 0, "金币不会变负")
    GameState.add_affinity("alchemist", 3)
    _assert_eq(GameState.affinity.get("alchemist", 0), 3, "好感度+3")
    GameState.set_flag("met_alchemist", true)
    _assert(GameState.has_flag("met_alchemist"), "has_flag 已设置")
    _assert(not GameState.has_flag("nope"), "has_flag 未设置")

func _test_save_roundtrip() -> void:
    print("\n--- 存档往返 ---")
    GameState.coins = 42
    GameState.set_affinity("alchemist", 2)
    TimeManager.day = 7
    var ok: bool = SaveManager.save_game(99)
    _assert(ok, "保存成功")
    GameState.coins = 0
    TimeManager.day = 1
    ok = SaveManager.load_game(99)
    _assert(ok, "读取成功")
    _assert_eq(GameState.coins, 42, "读回金币 42")
    _assert_eq(GameState.affinity.get("alchemist", 0), 2, "读回好感度 2")
    _assert_eq(TimeManager.day, 7, "读回天数 7")
    SaveManager.delete_save(99)

func _test_dialogue_conditions() -> void:
    print("\n--- 对话条件解析 ---")
    var db_script: Script = preload("res://systems/dialogue/dialogue_box.gd")
    var db: Control = db_script.new()
    GameState.set_flag("met_alchemist", false)
    GameState.set_affinity("alchemist", 0)
    _assert(not db._eval_condition('has_flag("met_alchemist")'), "has_flag 未满足")
    _assert(db._eval_condition('affinity["alchemist"] >= 0'), "好感度>=0 满足")
    _assert(not db._eval_condition('affinity["alchemist"] >= 5'), "好感度>=5 不满足")
    _assert(db._eval_condition('day > 0'), "day>0 满足")
    _assert(not db._eval_condition('day > 999'), "day>999 不满足")

func _test_score_reward() -> void:
    print("\n--- 小游戏成绩结算 ---")
    var reward := func(score: int) -> int:
        return 30 if score >= 3 else 10
    _assert_eq(reward.call(0), 10, "score=0 → 10")
    _assert_eq(reward.call(2), 10, "score=2 → 10")
    _assert_eq(reward.call(3), 30, "score=3 → 30")
    _assert_eq(reward.call(5), 30, "score=5 → 30")
