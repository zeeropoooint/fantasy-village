extends StaticBody2D
## 门:触发场景切换。目标场景由 target_scene 配置。
## 同时记录玩家出场位置 target_spawn。

@export var prompt_text: String = "进入"
@export var target_scene: String = ""
@export var target_spawn: Vector2 = Vector2.ZERO

func _ready() -> void:
    add_to_group("interactable")
    collision_layer = collision_layer | 1 | (1 << 2)

func interact(_source: Node = null) -> void:
    AudioManager.play_sfx("door")
    if target_scene != "":
        GameState.pending_spawn = target_spawn
        GameState.pending_scene = target_scene
        SceneManager.change_scene(target_scene)
