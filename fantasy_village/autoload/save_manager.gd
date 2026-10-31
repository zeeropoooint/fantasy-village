extends Node
## 存档管理器。M0 本地版:序列化到 user://save_slot_1.json。
## 存档带 version 字段，未来通过迁移函数链升级。

signal save_finished(slot: int, success: bool)
signal load_finished(slot: int, success: bool)

const SAVE_VERSION: int = 1
const SAVE_DIR: String = "user://"
const SLOT_FILE: String = "save_slot_%d.json"

func slot_path(slot: int) -> String:
    return SAVE_DIR + SLOT_FILE % slot

func has_save(slot: int = 1) -> bool:
    return FileAccess.file_exists(slot_path(slot))

func save_game(slot: int = 1) -> bool:
    var data := {
        "version": SAVE_VERSION,
        "saved_at": Time.get_unix_time_from_system(),
        "game_state": GameState.to_dict(),
        "time": TimeManager.to_dict(),
    }
    var text := JSON.stringify(data, "  ")
    var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
    if file == null:
        push_warning("SaveManager: 无法写入存档 %s" % slot_path(slot))
        save_finished.emit(slot, false)
        return false
    file.store_string(text)
    file.close()
    save_finished.emit(slot, true)
    return true

func load_game(slot: int = 1) -> bool:
    var path := slot_path(slot)
    if not FileAccess.file_exists(path):
        load_finished.emit(slot, false)
        return false
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        load_finished.emit(slot, false)
        return false
    var text := file.get_as_text()
    file.close()

    var parsed: Variant = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("SaveManager: 存档不是有效 JSON")
        load_finished.emit(slot, false)
        return false

    var data: Dictionary = parsed
    var version: int = int(data.get("version", 0))
    data = _migrate(data, version)
    if data.is_empty():
        push_error("SaveManager: 存档版本迁移失败 v=%d" % version)
        load_finished.emit(slot, false)
        return false

    if data.has("game_state"):
        GameState.from_dict(data["game_state"])
    if data.has("time"):
        TimeManager.from_dict(data["time"])
    load_finished.emit(slot, true)
    return true

func delete_save(slot: int = 1) -> void:
    if FileAccess.file_exists(slot_path(slot)):
        DirAccess.remove_absolute(slot_path(slot))

## 版本迁移函数链。当前只有 v1，保留结构以便后续扩展。
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
    var v: int = from_version
    var d: Dictionary = data
    while v < SAVE_VERSION:
        v += 1
        d = _migrate_to(d, v)
        if d.is_empty() and "version" not in d:
            # 迁移失败标记
            return {}
    return d

func _migrate_to(data: Dictionary, target_version: int) -> Dictionary:
    # 预留:每个 case 处理一个版本的字段增减/改名
    match target_version:
        1:
            return data
        _:
            push_warning("SaveManager: 未知迁移目标版本 %d" % target_version)
            return data
