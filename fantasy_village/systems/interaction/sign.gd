extends StaticBody2D
## 木牌:触发节奏点击小游戏。通过 MiniGameHost 宿主装载。

@export var prompt_text: String = "看看木牌"
@export var minigame_scene: String = "res://scenes/minigames/rhythm_game.tscn"

func _ready() -> void:
    add_to_group("interactable")
    collision_layer = collision_layer | 1 | (1 << 2)

func interact(_source: Node = null) -> void:
    if GameState.has_flag("sign_minigame_done"):
        _toast("木牌已经看过了。")
        return
    var host_script: Script = preload("res://systems/minigame_host/minigame_host.gd")
    var host: CanvasLayer = host_script.new()
    get_tree().root.add_child(host)
    host.start_minigame(minigame_scene, _on_result)

func _on_result(score: int) -> void:
    var reward: int = 30 if score >= 3 else 10
    GameState.add_coins(reward)
    GameState.set_flag("sign_minigame_done", true)
    AudioManager.play_sfx("coin")
    _toast("获得 %d 金币!(成绩 %d)" % [reward, score])

func _toast(msg: String) -> void:
    # 挂到独立 CanvasLayer,脱离相机变换,提示始终固定在屏幕上方居中
    var layer := CanvasLayer.new()
    layer.layer = 60
    get_tree().root.add_child(layer)
    var lbl := Label.new()
    lbl.text = msg
    lbl.add_theme_font_size_override("font_size", 16)
    lbl.anchor_right = 1.0
    lbl.anchor_top = 0.25
    lbl.anchor_bottom = 0.25
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.modulate.a = 0.0
    layer.add_child(lbl)
    var tw := layer.create_tween()
    tw.tween_property(lbl, "modulate:a", 1.0, 0.3)
    tw.tween_interval(1.5)
    tw.tween_property(lbl, "modulate:a", 0.0, 0.4)
    tw.tween_callback(layer.queue_free)
