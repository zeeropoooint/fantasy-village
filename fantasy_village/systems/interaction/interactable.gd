extends Node
## 所有可交互物(NPC、门、床、牌子、地块)的基类(纯 mixin,不绑定节点类型)。
## 约定:
## - 加入 "interactable" 组
## - 提供 prompt_text 属性(显示在交互按钮上)
## - 提供 interact() 方法(玩家按交互时调用)
## 实际节点可以是 StaticBody2D(阻挡+探测)或 Area2D(仅探测)。

@export var prompt_text: String = "交互"

func _ready() -> void:
    add_to_group("interactable")
    # 让挂了本脚本的 CollisionObject2D 同时在 world 层(阻挡)和 interactables 层(可探测)
    # 用动态 get/set 绕过静态类型检查(本脚本是 mixin,可挂在任意节点类型上)
    if self.get("collision_layer") != null:
        self.set("collision_layer", int(self.get("collision_layer")) | 1 | (1 << 2))

func interact(_source: Node = null) -> void:
    pass
