extends Node
## 回归验证:床旁探测不崩溃 + 右向动画帧存在 + 按钮回调可睡觉。
## 运行: godot --headless --path <project> res://tests/test_bedroom_regression.tscn --quit-after 8

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var failed := 0
    var bedroom: Node2D = load("res://scenes/world/bedroom.tscn").instantiate()
    get_tree().root.add_child(bedroom)
    for i in 5:
        await get_tree().process_frame
    var player: CharacterBody2D = bedroom.get_node("World/Player")
    var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
    # 1) 右向动画帧存在且非空
    for anim in ["idle_right", "walk_right", "idle_left", "walk_down", "idle_up"]:
        if not sprite.sprite_frames.has_animation(anim):
            push_error("缺少动画: " + anim); failed += 1
    if sprite.sprite_frames.get_frame_texture("walk_right", 0) == null:
        push_error("walk_right 第0帧为空"); failed += 1
    else:
        print("PASS: walk_right 帧纹理存在")
    # 2) 玩家放到床旁约1格,探测区应选中床(此前 target_changed 回调会崩溃)
    player.global_position = Vector2(48, 112 + 24)
    for i in 5:
        await get_tree().process_frame
    if player.detector.current_target == null:
        push_error("床旁未检测到交互目标"); failed += 1
    else:
        print("PASS: 床旁检测到目标 -> ", player.detector.current_target.name)
    # 3) 走按钮回调路径交互一次,应正常睡觉
    player.detector.interact_current(player)
    await get_tree().process_frame
    if TimeManager.day != 2:
        push_error("睡觉后日期未+1, day=%d" % TimeManager.day); failed += 1
    else:
        print("PASS: 交互按钮回调路径执行成功, day=2")
    print("\n回归验证: ", ("全部通过" if failed == 0 else "%d 项失败" % failed))
    get_tree().quit(failed)
