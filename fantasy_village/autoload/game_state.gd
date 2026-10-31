extends Node
## 玩家全局状态。所有跨场景需要持久化的数据都放这里。
## 保存由 SaveManager 负责，本类只管状态本身 + 变更信号。

signal coins_changed(new_amount: int)
signal affinity_changed(npc_id: String, new_value: int)
signal flag_changed(flag: String, new_value: bool)

var coins: int = 0
var affinity: Dictionary = {}      # npc_id -> int (0..10)
var flags: Dictionary = {}         # 剧情/一次性标志，存 bool
var inventory: Dictionary = {}     # 物品 id -> 数量
var player_name: String = "旅人"

## 跨场景临时传递(不写入存档)
var pending_spawn: Vector2 = Vector2.ZERO
var pending_scene: String = ""

func add_coins(amount: int) -> void:
    if amount == 0:
        return
    coins = max(0, coins + amount)
    coins_changed.emit(coins)

func set_affinity(npc_id: String, value: int) -> void:
    affinity[npc_id] = clamp(value, 0, 10)
    affinity_changed.emit(npc_id, affinity[npc_id])

func add_affinity(npc_id: String, delta: int) -> void:
    set_affinity(npc_id, affinity.get(npc_id, 0) + delta)

func set_flag(flag: String, value: bool = true) -> void:
    flags[flag] = value
    flag_changed.emit(flag, value)

func has_flag(flag: String) -> bool:
    return bool(flags.get(flag, false))

func add_item(item_id: String, amount: int = 1) -> void:
    inventory[item_id] = inventory.get(item_id, 0) + amount

func remove_item(item_id: String, amount: int = 1) -> bool:
    var have: int = inventory.get(item_id, 0)
    if have < amount:
        return false
    have -= amount
    if have == 0:
        inventory.erase(item_id)
    else:
        inventory[item_id] = have
    return true

func to_dict() -> Dictionary:
    return {
        "coins": coins,
        "affinity": affinity.duplicate(true),
        "flags": flags.duplicate(true),
        "inventory": inventory.duplicate(true),
        "player_name": player_name,
    }

func from_dict(d: Dictionary) -> void:
    coins = int(d.get("coins", 0))
    affinity = d.get("affinity", {}).duplicate(true)
    flags = d.get("flags", {}).duplicate(true)
    inventory = d.get("inventory", {}).duplicate(true)
    player_name = str(d.get("player_name", "旅人"))
    coins_changed.emit(coins)
