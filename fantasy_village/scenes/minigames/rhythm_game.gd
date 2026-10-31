extends Control
## 节奏点击小游戏(M0 示例)。
## 5 个音符从上往下落，玩家在击中区按 空格/点击 判定。
## 结束时发出 finished(score) 信号,score = 击中数(0..5)。

signal finished(score: int)

const NOTE_COUNT: int = 5
const NOTE_SPEED: float = 120.0      # px/s
const HIT_ZONE_Y: float = 280.0
const HIT_TOLERANCE: float = 40.0    # px

@onready var note_container: Node2D = $Notes
@onready var hit_line: ColorRect = $HitLine
@onready var score_label: Label = $ScoreLabel
@onready var hint_label: Label = $HintLabel

var _notes: Array = []              # {node, y}
var _spawned: int = 0
var _score: int = 0
var _next_spawn_time: float = 0.0
var _elapsed: float = 0.0
var _active: bool = true

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    hit_line.position.y = HIT_ZONE_Y
    _next_spawn_time = 0.8
    score_label.text = "0 / %d" % NOTE_COUNT

func _process(delta: float) -> void:
    if not _active:
        return
    _elapsed += delta
    if _spawned < NOTE_COUNT and _elapsed >= _next_spawn_time:
        _spawn_note()
        _spawned += 1
        _next_spawn_time = _elapsed + randf_range(0.8, 1.4)
    for n in _notes:
        n["y"] += NOTE_SPEED * delta
        n["node"].position.y = n["y"]
        if n["y"] > HIT_ZONE_Y + HIT_TOLERANCE + 20 and not n["hit"]:
            n["hit"] = true
            n["node"].modulate = Color(1, 0.3, 0.3, 0.4)
            AudioManager.play_sfx("miss")
            _cleanup_done()
    if _spawned >= NOTE_COUNT and _all_notes_resolved():
        _end_game()

func _spawn_note() -> void:
    var note := ColorRect.new()
    note.color = Color(1, 0.85, 0.3, 1)
    note.size = Vector2(40, 40)
    note.position = Vector2(460 - 20, -40)
    note_container.add_child(note)
    _notes.append({"node": note, "y": -40.0, "hit": false})

func _input(event: InputEvent) -> void:
    if not _active:
        return
    if event.is_action_pressed("confirm") or (event is InputEventMouseButton and event.pressed):
        _try_hit()

func _try_hit() -> void:
    for n in _notes:
        if n["hit"]:
            continue
        if abs(n["y"] - HIT_ZONE_Y) <= HIT_TOLERANCE:
            n["hit"] = true
            n["node"].modulate = Color(0.3, 1, 0.3, 1.0)
            _score += 1
            score_label.text = "%d / %d" % [_score, NOTE_COUNT]
            AudioManager.play_sfx("hit")
            return
    AudioManager.play_sfx("miss")

func _all_notes_resolved() -> bool:
    for n in _notes:
        if not n["hit"]:
            return false
    return true

func _cleanup_done() -> void:
    var to_remove: Array = []
    for n in _notes:
        if n["hit"] and n["y"] > HIT_ZONE_Y + 100:
            to_remove.append(n)
    for n in to_remove:
        n["node"].queue_free()
        _notes.erase(n)

func _end_game() -> void:
    _active = false
    hint_label.text = "结算: 击中 %d / %d" % [_score, NOTE_COUNT]
    var tw := create_tween()
    tw.tween_interval(1.0)
    tw.tween_callback(func() -> void: finished.emit(_score))
