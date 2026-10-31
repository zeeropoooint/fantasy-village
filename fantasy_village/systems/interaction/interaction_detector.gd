extends Area2D
class_name InteractionDetector
## 挂在玩家身上的交互探测区。
## - 范围内始终只选中最近的一个 interactable
## - 选中后发出 target_changed 信号，UI 据此显示/隐藏交互按钮
## - 外部通过 interact_current() 触发当前目标的 interact()

signal target_changed(target: Node, prompt_text: String)
signal target_cleared()

var current_target: Node = null

func _ready() -> void:
    collision_layer = 0
    collision_mask = 1 << 2   # interactables
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)

func _on_body_entered(_b: Node) -> void:
    _refresh()

func _on_body_exited(_b: Node) -> void:
    _refresh()

func _on_area_entered(_a: Area2D) -> void:
    _refresh()

func _on_area_exited(_a: Area2D) -> void:
    _refresh()

func _refresh() -> void:
    var best: Node = null
    var best_dist: float = INF
    var bodies := get_overlapping_bodies()
    var areas := get_overlapping_areas()
    for n in bodies:
        if n.is_in_group("interactable"):
            var d := global_position.distance_to(n.global_position)
            if d < best_dist:
                best_dist = d; best = n
    for a in areas:
        if a.is_in_group("interactable"):
            var d := global_position.distance_to(a.global_position)
            if d < best_dist:
                best_dist = d; best = a
    if best != current_target:
        current_target = best
        if current_target != null:
            var p: String = current_target.get("prompt_text") if "prompt_text" in current_target else "交互"
            target_changed.emit(current_target, p)
        else:
            target_cleared.emit()

func interact_current(source: Node = null) -> void:
    if current_target != null and current_target.has_method("interact"):
        current_target.interact(source)
