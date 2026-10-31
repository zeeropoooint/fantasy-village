extends Node2D
## 村庄场景:石墙环绕,含药剂师 NPC、木牌(小游戏)、房门(回卧室)、水塘、栅栏农田。
## 碰撞由字符地图自动生成(w/F/W/X 为实心),杜绝手写坐标与视觉错位的穿模问题。

@onready var ground: TileMapLayer = $Ground
@onready var deco_layer: TileMapLayer = $Decor
@onready var player: CharacterBody2D = $Player

const MAP_W: int = 40
const MAP_H: int = 22
## 实心字符:水 w / 栅栏 F / 石墙 W / 苔藓墙 X / 石板 s
const SOLID: String = "wFWXs"
# 字符含义:.=草地 b=花草地 c=石子草 d=泥土 D=泥路 w=水 s=石板
#           F=栅栏 W=石墙 X=苔藓墙 ,=小草 *=花(装饰,画在 Decor 层)
const MAP: Array[String] = [
	"WWWXWWWWWWWWWWWWWXWWWWWWWWWWWWXWWWWWWWWW",
	"W.........b............................W",
	"W...*.......................,.........cW",
	"W..................b.......sssssssss..bW",
	"W.............b.......c....swwwwwwws...W",
	"W.....D..,.............,...swwwwwwws..,X",
	"X.*c*.D...................cswwwwwwws...W",
	"W.....D*.............c..,..swwwwwwws...W",
	"W.....D.*..................sssssssss...W",
	"W.....D..*...................*...,.....W",
	"WDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDW",
	"WDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDW",
	"W...............................b......W",
	"W..FFFF.FFFF......b....,...............W",
	"W..FdddddddF.,b.........c.........,.b.,W",
	"W..FdddddddF....c.....c.c......b.......X",
	"X..FdddddddF.,..........,.*......,.....W",
	"W..FdddddddF......*................,...W",
	"W..FFFFFFFFF.....,...............*..b..W",
	"W.....,.........c......................W",
	"W.......b........,...,....bb..........bW",
	"WWWWWWWWWWXWWWWWWWWWWWWWWWXWWWWWWWWWWWWW",
]

## 把字符地图中所有实心格按行合并为碰撞矩形(静态可测)。
static func collision_rects_for(map: Array, solids: String) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for y in range(map.size()):
		var line: String = map[y]
		var x: int = 0
		while x < line.length():
			if solids.contains(line.substr(x, 1)):
				var start: int = x
				while x < line.length() and solids.contains(line.substr(x, 1)):
					x += 1
				out.append(Rect2(start * 16, y * 16, (x - start) * 16, 16))
			else:
				x += 1
	return out

func _ready() -> void:
	var tsf: Script = preload("res://systems/world/tile_set_factory.gd")
	var ts: TileSet = tsf.build()
	ground.tile_set = ts
	deco_layer.tile_set = ts
	# 地面层:完整不透明 tile
	var ground_map := {
		".": {"atlas": Vector2i(0, 0)},
		"b": {"atlas": Vector2i(1, 0)},
		"c": {"atlas": Vector2i(2, 0)},
		"d": {"atlas": Vector2i(3, 0)},
		"D": {"atlas": Vector2i(4, 0)},
		"w": {"atlas": Vector2i(5, 0)},
		"s": {"atlas": Vector2i(6, 0)},
	}
	# 装饰层:栅栏/墙/稀疏小草,画在 Ground 之上(栅栏与草透出草地底色)
	var deco_map := {
		"F": {"atlas": Vector2i(7, 0)},
		"W": {"atlas": Vector2i(6, 1)},
		"X": {"atlas": Vector2i(7, 1)},
		",": {"atlas": Vector2i(0, 2)},
		"*": {"atlas": Vector2i(1, 2)},
	}
	# 先全图铺不透明草地兜底:装饰字符(F/W/X/,/*)格与瓦片透明处不再透出视口底色
	var full_map := PackedStringArray()
	for i in range(MAP_H):
		full_map.append(".".repeat(MAP_W))
	tsf.paint(ground, full_map, ground_map)
	tsf.paint(ground, PackedStringArray(MAP), ground_map)
	tsf.paint(deco_layer, PackedStringArray(MAP), deco_map)

	# y-sort 世界层:树/房/木牌/NPC/门/玩家按脚部位置互相遮挡
	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)

	_place_decor(world)
	_build_collision()

	# 玩家位置
	if GameState.pending_spawn != Vector2.ZERO:
		player.global_position = GameState.pending_spawn
		GameState.pending_spawn = Vector2.ZERO
		GameState.pending_scene = ""
	else:
		player.global_position = Vector2(20 * 16, 14 * 16)
	player.reparent(world)

	_add_ui()

func _place_decor(world: Node2D) -> void:
	# 树:sprite 锚点移到树根,y-sort 下树冠可遮挡玩家
	for cell: Vector2i in [Vector2i(2, 2), Vector2i(37, 2), Vector2i(14, 3), Vector2i(24, 2),
			Vector2i(2, 8), Vector2i(37, 5), Vector2i(2, 15), Vector2i(37, 14),
			Vector2i(15, 19), Vector2i(30, 19), Vector2i(9, 20), Vector2i(24, 18)]:
		_place_tree(Vector2(cell.x * 16, cell.y * 16), world)
	# 房子(3x3 格,列5-7 行2-4)
	var house := Sprite2D.new()
	house.texture = preload("res://assets/sprites/house.png")
	house.position = Vector2(5 * 16, 2 * 16)
	house.centered = false
	world.add_child(house)
	_add_static_box(Vector2(5 * 16 + 24, 2 * 16 + 22), Vector2(48, 44))
	# 木牌(交互)
	_add_interactable(Vector2(20 * 16 + 8, 9 * 16 + 8), preload("res://assets/sprites/sign.png"),
			Vector2(16, 16), preload("res://systems/interaction/sign.gd"), "看看木牌", world)
	# 药剂师 NPC(交互)
	_add_interactable(Vector2(14 * 16 + 8, 9 * 16 + 8), preload("res://assets/sprites/alchemist.png"),
			Vector2(12, 14), preload("res://systems/interaction/npc.gd"), "对话", world)
	# 房门(回卧室)
	var door := StaticBody2D.new()
	door.position = Vector2(6 * 16 + 8, 5 * 16 + 8)
	var dcs := CollisionShape2D.new()
	var dr := RectangleShape2D.new(); dr.size = Vector2(16, 16)
	dcs.shape = dr
	door.add_child(dcs)
	door.set_script(preload("res://systems/interaction/door.gd"))
	door.set("target_scene", "res://scenes/world/bedroom.tscn")
	door.set("target_spawn", Vector2(8 * 16, 10 * 16))
	door.set("prompt_text", "回家")
	world.add_child(door)

func _place_tree(pos: Vector2, world: Node2D) -> void:
	var tree := Sprite2D.new()
	tree.texture = preload("res://assets/sprites/tree.png")
	tree.position = pos + Vector2(8, 32)
	tree.offset = Vector2(0, -16)  # y-sort 锚点落在树根
	tree.centered = true
	world.add_child(tree)
	# 树干碰撞加宽,玩家无法钻进树冠
	_add_static_box(pos + Vector2(8, 27), Vector2(14, 10))

func _add_interactable(pos: Vector2, tex: Texture2D, shape_size: Vector2, script: Script, prompt: String, world: Node2D) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var sp := Sprite2D.new()
	sp.texture = tex
	body.add_child(sp)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new(); rect.size = shape_size
	cs.shape = rect
	body.add_child(cs)
	body.set_script(script)
	body.prompt_text = prompt
	world.add_child(body)

func _build_collision() -> void:
	# 实心格(w/F/W/X)按地图自动生成碰撞,与视觉严格对齐
	for r: Rect2 in collision_rects_for(MAP, SOLID):
		_add_static_box(r.get_center(), r.size)
	# 地图外边界兜底
	_add_static_box(Vector2(MAP_W * 8, -8), Vector2(MAP_W * 16, 16))
	_add_static_box(Vector2(MAP_W * 8, MAP_H * 16 + 8), Vector2(MAP_W * 16, 16))
	_add_static_box(Vector2(-8, MAP_H * 8), Vector2(16, MAP_H * 16))
	_add_static_box(Vector2(MAP_W * 16 + 8, MAP_H * 8), Vector2(16, MAP_H * 16))

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
