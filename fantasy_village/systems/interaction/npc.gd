extends StaticBody2D
## NPC 药剂师:靠近触发对话。

@export var prompt_text: String = "对话"
@export var dialogue_path: String = "res://data/dialogues/alchemist.json"

var _dialogue_box: Control = null

func _ready() -> void:
    add_to_group("interactable")
    collision_layer = collision_layer | 1 | (1 << 2)

func interact(_source: Node = null) -> void:
    if _dialogue_box == null:
        # 挂到独立 CanvasLayer,脱离相机变换,对话框始终铺满屏幕
        var layer := CanvasLayer.new()
        layer.layer = 40
        _dialogue_box = preload("res://scenes/ui/dialogue_box.tscn").instantiate()
        layer.add_child(_dialogue_box)
        get_tree().root.add_child(layer)
    var data = _load_dialogue()
    if data.size() > 0:
        _dialogue_box.start_dialogue(data, "alchemist")
        AudioManager.play_sfx("talk")
        if not GameState.has_flag("met_alchemist"):
            GameState.set_flag("met_alchemist", true)
            GameState.add_affinity("alchemist", 1)

func _load_dialogue() -> Array:
    var file := FileAccess.open(dialogue_path, FileAccess.READ)
    if file == null:
        push_warning("NPC: 无法读取对话文件 %s" % dialogue_path)
        return []
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) == TYPE_DICTIONARY and parsed.has("lines"):
        return parsed["lines"]
    return []
