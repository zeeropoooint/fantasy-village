extends Control
class_name ScreenJoystick
## 屏幕左下虚拟摇杆。触摸拖动输出归一化向量到 InputManager。

const DEADZONE: float = 0.25
const MAX_RADIUS: float = 64.0

@onready var base: Control = $Base
@onready var knob: Control = $Knob

var _active: bool = false
var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO

func _ready() -> void:
    base.mouse_filter = Control.MOUSE_FILTER_STOP
    knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _center = base.position + base.size * 0.5
    knob.position = _center - knob.size * 0.5

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and not _active:
            _active = true
            _touch_index = event.index
            _update(event.position)
        elif not event.pressed and event.index == _touch_index:
            _release()
    elif event is InputEventScreenDrag and event.index == _touch_index:
        _update(event.position)
    # 鼠标模拟(PC 调试用)
    if event is InputEventMouseButton:
        if event.pressed and not _active:
            _active = true
            _touch_index = -2
            _update(event.position)
        elif not event.pressed:
            _release()
    elif event is InputEventMouseMotion and _active and _touch_index == -2:
        _update(event.position)

func _update(pos: Vector2) -> void:
    var delta := pos - _center
    var dist := delta.length()
    if dist < DEADZONE * MAX_RADIUS:
        knob.position = _center - knob.size * 0.5
        InputManager.set_joystick_vector(Vector2.ZERO)
        return
    var clamped := delta.limit_length(MAX_RADIUS)
    knob.position = _center + clamped - knob.size * 0.5
    InputManager.set_joystick_vector(clamped / MAX_RADIUS)

func _release() -> void:
    _active = false
    _touch_index = -1
    knob.position = _center - knob.size * 0.5
    InputManager.reset_joystick()
