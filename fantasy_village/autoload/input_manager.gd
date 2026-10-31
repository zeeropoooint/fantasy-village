extends Node
## 输入统一抽象:把虚拟摇杆(屏幕)与键盘/WASD 合并成同一个接口。
## 玩家脚本只读 InputManager.move_vector，不直接读 Input。

signal interact_pressed()
signal confirm_pressed()
signal cancel_pressed()

var move_vector: Vector2 = Vector2.ZERO

var _joystick_vector: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        interact_pressed.emit()
    if event.is_action_pressed("confirm"):
        confirm_pressed.emit()
    if event.is_action_pressed("cancel"):
        cancel_pressed.emit()

func _process(_delta: float) -> void:
    var kb := Vector2.ZERO
    if Input.is_action_pressed("move_left"):
        kb.x -= 1.0
    if Input.is_action_pressed("move_right"):
        kb.x += 1.0
    if Input.is_action_pressed("move_up"):
        kb.y -= 1.0
    if Input.is_action_pressed("move_down"):
        kb.y += 1.0
    if kb.length() > 0.0:
        kb = kb.normalized()
    move_vector = kb if kb.length() > 0.0 else _joystick_vector

## 虚拟摇杆调用此接口更新向量(已归一化)。
func set_joystick_vector(v: Vector2) -> void:
    _joystick_vector = v

## 虚拟摇杆调用此接口复位。
func reset_joystick() -> void:
    _joystick_vector = Vector2.ZERO
