extends CanvasLayer
class_name MiniGameHost
## 小游戏宿主。
## 1. 暂停世界(get_tree().paused = true)
## 2. 实例化小游戏场景(小游戏需继承 MiniGameBase)
## 3. 监听 finished(score) 信号
## 4. 恢复世界，把成绩交给回调
## process_mode = ALWAYS，保证暂停期间仍可运行。

const RESULT_NONE: int = -1

var _callback: Callable = Callable()
var _minigame: Node = null

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 50

func start_minigame(scene_path: String, on_result: Callable) -> void:
    _callback = on_result
    get_tree().paused = true
    var packed: PackedScene = load(scene_path)
    if packed == null:
        push_error("MiniGameHost: 无法加载小游戏 %s" % scene_path)
        _finish(RESULT_NONE)
        return
    _minigame = packed.instantiate()
    add_child(_minigame)
    if _minigame.has_signal("finished"):
        _minigame.finished.connect(_on_minigame_finished)
    else:
        push_error("MiniGameHost: 小游戏缺少 finished(score) 信号")
        _finish(RESULT_NONE)

func _on_minigame_finished(score: int) -> void:
    _finish(score)

func _finish(score: int) -> void:
    get_tree().paused = false
    if _callback.is_valid():
        _callback.call(score)
    queue_free()
