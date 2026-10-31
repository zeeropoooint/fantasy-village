extends Node2D
## 卧室场景:室内,含床(睡觉过天)与门(转场到村庄)。

@onready var ground: TileMapLayer = $Ground
@onready var walls_layer: TileMapLayer = $Walls
@onready var player: CharacterBody2D = $Player
@onready var bed: StaticBody2D = $Bed
@onready var door: StaticBody2D = $Door
@onready var decor: Node2D = $Decor

const MAP_W: int = 16
const MAP_H: int = 12
# 字符地图:.=空 f=地板 w=墙 W=带窗墙 r=地毯 m=门垫
const MAP: Array[String] = [
	"wwwwwwwwwwwwwwww",
	"wffffffffffffffw",
	"wffffffffffffffw",
	"wffrrrrrrrrffffw",
	"wffrrrrrrrrffffw",
	"wffrrrrrrrrffffw",
	"wffffffffffffffw",
	"wffffffffffffffw",
	"wffffffffffffffw",
	"wffffffffffffffw",
	"wfffffffffmmmffw",
	"wwwwwwwwwwwwwwww",
]

func _ready() -> void:
	var tsf: Script = preload("res://systems/world/tile_set_factory.gd")
	var ts: TileSet = tsf.build()
	ground.tile_set = ts
	walls_layer.tile_set = ts

	var char_map := {
		"f": {"atlas": Vector2i(0, 1)},
		"w": {"atlas": Vector2i(1, 1), "layer": 1},
		"W": {"atlas": Vector2i(5, 1), "layer": 1},
		"r": {"atlas": Vector2i(2, 1)},
		"m": {"atlas": Vector2i(4, 1)},
	}
	tsf.paint(ground, PackedStringArray(MAP), char_map)
	tsf.paint(walls_layer, PackedStringArray(MAP), char_map)

	# 碰撞:四周墙(床的碰撞由 tscn 内与 sprite 对齐的碰撞体提供)
	_build_collision()

	# y-sort:玩家与床按位置互相遮挡
	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	bed.reparent(world)
	player.reparent(world)

	# 玩家位置:若从村庄回来则用 pending_spawn，否则默认
	if GameState.pending_scene != "" and GameState.pending_spawn != Vector2.ZERO:
		player.global_position = GameState.pending_spawn
		GameState.pending_spawn = Vector2.ZERO
		GameState.pending_scene = ""
	else:
		player.global_position = Vector2(8 * 16, 9 * 16)

	# UI
	_add_ui()

func _build_collision() -> void:
	# 外墙:四条边
	_add_static_box(Vector2(MAP_W * 8, -8), Vector2(MAP_W * 16, 16))            # 顶
	_add_static_box(Vector2(MAP_W * 8, MAP_H * 16 + 8), Vector2(MAP_W * 16, 16)) # 底
	_add_static_box(Vector2(-8, MAP_H * 8), Vector2(16, MAP_H * 16))             # 左
	_add_static_box(Vector2(MAP_W * 16 + 8, MAP_H * 8), Vector2(16, MAP_H * 16)) # 右

func _add_static_box(pos: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)
	return body

func _add_ui() -> void:
	var hud := preload("res://scenes/ui/hud.tscn").instantiate()
	add_child(hud)
	var joy := preload("res://scenes/ui/virtual_joystick.tscn").instantiate()
	add_child(joy)
	var btn := preload("res://scenes/ui/interact_button.tscn").instantiate()
	add_child(btn)
	# pressed 只连接一次,回调时读取 detector 的当前目标,避免重复连接
	btn.pressed.connect(func() -> void:
		if btn.visible:
			player.detector.interact_current(player)
	)
	player.detector.target_changed.connect(func(_t, p) -> void:
		btn.visible = true
		btn.text = p
	)
	player.detector.target_cleared.connect(func() -> void:
		btn.visible = false
	)
	InputManager.interact_pressed.connect(func() -> void:
		if btn.visible:
			player.detector.interact_current(player)
	)
