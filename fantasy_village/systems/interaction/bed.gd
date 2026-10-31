extends StaticBody2D
## 床:睡觉 → 天数 +1、时钟重置 6:00 → 自动存档 → 次日继续。

@export var prompt_text: String = "睡觉"

func _ready() -> void:
    add_to_group("interactable")
    collision_layer = collision_layer | 1 | (1 << 2)

func interact(_source: Node = null) -> void:
    AudioManager.play_sfx("sleep")
    TimeManager.sleep_to_next_day()
    SaveManager.save_game(1)
    _show_day_banner()

func _show_day_banner() -> void:
    # 挂到独立 CanvasLayer,脱离相机变换,横幅始终居中于屏幕
    var layer := CanvasLayer.new()
    layer.layer = 60
    get_tree().root.add_child(layer)
    var banner := Label.new()
    banner.text = "第 %d 天" % TimeManager.day
    banner.add_theme_font_size_override("font_size", 32)
    banner.anchor_right = 1.0
    banner.anchor_bottom = 1.0
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.modulate.a = 0.0
    layer.add_child(banner)
    var tw := layer.create_tween()
    tw.tween_property(banner, "modulate:a", 1.0, 0.4)
    tw.tween_interval(1.2)
    tw.tween_property(banner, "modulate:a", 0.0, 0.4)
    tw.tween_callback(layer.queue_free)
