extends Control
class_name DialogueBox
## 打字机对话框。JSON 驱动。
## 台词格式见 data/dialogues/alchemist.json。
## 推进:confirm 动作 / 鼠标点击 / 屏幕点击。

signal dialogue_finished(dialogue_id: String)
signal choice_selected(choice: Dictionary)

@export var typewriter_speed: float = 35.0   # 字/秒

var _dialogue_data: Array = []
var _index: int = 0
var _speaker_label: Label
var _text_label: RichTextLabel
var _next_indicator: Label
var _choice_container: VBoxContainer
var _typing: bool = false
var _type_timer: float = 0.0
var _type_pos: int = 0
var _full_text: String = ""
var _dialogue_id: String = ""
var _finished: bool = false

func _ready() -> void:
    _speaker_label = %SpeakerLabel
    _text_label = %TextLabel
    _next_indicator = %NextIndicator
    _choice_container = %ChoiceContainer
    _text_label.bbcode_enabled = true
    visible = false

func start_dialogue(data: Array, dialogue_id: String) -> void:
    _dialogue_data = data
    _index = 0
    _dialogue_id = dialogue_id
    _finished = false
    visible = true
    _show_current()

func _input(event: InputEvent) -> void:
    if not visible or _finished:
        return
    if event.is_action_pressed("confirm") or (event is InputEventMouseButton and event.pressed):
        if _typing:
            _skip_typewriter()
        else:
            advance()

func _process(delta: float) -> void:
    if _typing:
        _type_timer += delta
        var chars_to_show: int = int(_type_timer * typewriter_speed)
        if chars_to_show >= _full_text.length():
            _finish_typewriter()
        else:
            _text_label.text = _full_text.substr(0, chars_to_show)

func _show_current() -> void:
    if _index >= _dialogue_data.size():
        _finish_dialogue()
        return
    var line: Dictionary = _dialogue_data[_index]
    # 条件检查
    if line.has("if"):
        if not _eval_condition(line["if"]):
            _index += 1
            _show_current()
            return
    _speaker_label.text = str(line.get("speaker", ""))
    var raw_text: String = str(line.get("text", ""))
    _full_text = raw_text
    _text_label.text = ""
    _type_timer = 0.0
    _type_pos = 0
    _typing = true
    _next_indicator.visible = false
    _choice_container.visible = false
    for c in _choice_container.get_children():
        c.queue_free()

func _finish_typewriter() -> void:
    _typing = false
    _text_label.text = _full_text
    var line: Dictionary = _dialogue_data[_index]
    if line.has("choices") and line["choices"].size() > 0:
        _build_choices(line["choices"])
    else:
        _next_indicator.visible = true

func _skip_typewriter() -> void:
    _type_timer = _full_text.length() / typewriter_speed
    _finish_typewriter()

func advance() -> void:
    if _index < _dialogue_data.size():
        var line: Dictionary = _dialogue_data[_index]
        if line.has("choices") and line["choices"].size() > 0:
            return   # 等待选项点击
    _index += 1
    _show_current()

func _build_choices(choices: Array) -> void:
    _choice_container.visible = true
    for c in choices:
        var btn := Button.new()
        btn.text = str(c.get("text", "…"))
        btn.custom_minimum_size = Vector2(0, 40)
        btn.pressed.connect(_on_choice_pressed.bind(c))
        _choice_container.add_child(btn)

func _on_choice_pressed(choice: Dictionary) -> void:
    choice_selected.emit(choice)
    if choice.has("next"):
        # 跳转到指定 id 的台词(简单实现:按 id 查找)
        var target_id: String = str(choice["next"])
        for i in _dialogue_data.size():
            if str(_dialogue_data[i].get("id", "")) == target_id:
                _index = i
                _show_current()
                return
    advance()

func _finish_dialogue() -> void:
    _finished = true
    visible = false
    dialogue_finished.emit(_dialogue_id)

## 简单条件求值:支持 affinity[npc_id] >= N / has_flag("x") / day > N
func _eval_condition(expr: String) -> bool:
    var e: String = expr.strip_edges()
    # has_flag("x")
    var hf: RegExMatch = _regex_match(e, "^has_flag\\(\"([^\"]+)\"\\)$")
    if hf != null:
        return GameState.has_flag(hf.get_string(1))
    # affinity["npc"] >= N
    var af: RegExMatch = _regex_match(e, "^affinity\\[\"([^\"]+)\"\\]\\s*(>=|<=|>|<|==|!=)\\s*(\\d+)$")
    if af != null:
        var v: int = GameState.affinity.get(af.get_string(1), 0)
        var n: int = int(af.get_string(3))
        match af.get_string(2):
            ">=": return v >= n
            "<=": return v <= n
            ">":  return v > n
            "<":  return v < n
            "==": return v == n
            "!=": return v != n
    # day > N
    var dy: RegExMatch = _regex_match(e, "^day\\s*(>=|<=|>|<|==|!=)\\s*(\\d+)$")
    if dy != null:
        var d: int = TimeManager.day
        var n: int = int(dy.get_string(2))
        match dy.get_string(1):
            ">=": return d >= n
            "<=": return d <= n
            ">":  return d > n
            "<":  return d < n
            "==": return d == n
            "!=": return d != n
    push_warning("DialogueBox: 无法解析条件表达式: %s" % e)
    return true

func _regex_match(text: String, pattern: String) -> RegExMatch:
    var regex := RegEx.new()
    regex.compile(pattern)
    return regex.search(text)
