extends Node
## 场景切换管理器。带淡入淡出转场。
## 切换期间用覆盖层 CanvasLayer + ColorRect 做 alpha 动画。

signal transition_finished(scene_path: String)

const FADE_DURATION: float = 0.4

var _overlay: CanvasLayer
var _fade_rect: ColorRect
var _tween: Tween

func _ready() -> void:
    _overlay = CanvasLayer.new()
    _overlay.layer = 100
    _overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_overlay)
    _fade_rect = ColorRect.new()
    _fade_rect.color = Color.BLACK
    _fade_rect.anchor_right = 1.0
    _fade_rect.anchor_bottom = 1.0
    _fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fade_rect.color.a = 0.0
    _overlay.add_child(_fade_rect)

func change_scene(scene_path: String, fade: bool = true) -> void:
    if fade:
        _fade_out_then_change(scene_path)
    else:
        get_tree().change_scene_to_file(scene_path)
        transition_finished.emit(scene_path)

func _fade_out_then_change(scene_path: String) -> void:
    if is_instance_valid(_tween):
        _tween.kill()
    _fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # 转场期间吃掉输入
    _tween = create_tween()
    _tween.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
    _tween.tween_callback(func() -> void:
        get_tree().change_scene_to_file(scene_path)
    )
    _tween.tween_callback(_fade_in)

func _fade_in() -> void:
    if is_instance_valid(_tween):
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
    _tween.tween_callback(func() -> void:
        _fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        transition_finished.emit(get_tree().current_scene.scene_file_path if get_tree().current_scene else "")
    )
