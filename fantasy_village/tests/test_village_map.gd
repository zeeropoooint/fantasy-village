extends Node
## 村庄地图回归:静态校验(行宽/碰撞覆盖) + 物理防穿模(水塘/栅栏/房门/道路)。
## 运行: godot --headless --path <project> res://tests/test_village_map.tscn --quit-after 20

var _failed: int = 0

func _fail(msg: String) -> void:
	_failed += 1
	push_error(msg)

func _pass(msg: String) -> void:
	print("PASS: ", msg)

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var vscript: Script = load("res://scenes/world/village.gd")
	var vconsts: Dictionary = vscript.get_script_constant_map()

	# ---- 静态校验 ----
	var map: Array = vconsts["MAP"]
	if map.size() != 22:
		_fail("村庄地图行数应为22, 实际%d" % map.size())
	var width_ok: bool = true
	for line in map:
		if String(line).length() != 40:
			width_ok = false
	if width_ok:
		_pass("村庄地图 22 行全部 40 字符")
	else:
		_fail("村庄地图存在非 40 字符行")

	# 每个实心格(w/F/W/X)都必须被碰撞矩形覆盖
	var solids: String = vconsts["SOLID"]
	var rects: Array = vscript.collision_rects_for(map, solids)
	var covered: bool = true
	for y in range(map.size()):
		var line: String = map[y]
		for x in range(line.length()):
			if solids.contains(line.substr(x, 1)):
				var center := Vector2(x * 16 + 8, y * 16 + 8)
				var hit: bool = false
				for r: Rect2 in rects:
					if r.has_point(center):
						hit = true
						break
				if not hit:
					_fail("实心格(%d,%d)=%s 无碰撞覆盖" % [x, y, line.substr(x, 1)])
	if _failed == 0:
		_pass("全部实心格均被碰撞矩形覆盖(%d 个合并盒)" % rects.size())

	# 卧室地图每行 16 字符
	var bscript: Script = load("res://scenes/world/bedroom.gd")
	var bmap: Array = bscript.get_script_constant_map()["MAP"]
	var bok: bool = true
	for line in bmap:
		if String(line).length() != 16:
			bok = false
	if bok:
		_pass("卧室地图每行 16 字符")
	else:
		_fail("卧室地图存在非 16 字符行")

	# ---- 物理防穿模(实例化真实村庄) ----
	var village: Node2D = load("res://scenes/world/village.tscn").instantiate()
	get_tree().root.add_child(village)
	for i in 5:
		await get_tree().process_frame
	var player: CharacterBody2D = _find_player(village)
	if player == null:
		_fail("村庄中找不到玩家")
		_finish()
		return

	# 1) 向南走向水塘,应被石板岸挡住(s在行3 y48~64 → 玩家碰撞圆下缘y+9=48 → y=39)
	await _push(player, Vector2(31 * 16 + 8, 1 * 16 + 8), Vector2(0, 1), 90)
	var py: float = player.global_position.y
	if py > 36.0 and py < 42.0:
		_pass("水塘北岸阻挡正常, 玩家停在 y=%.1f" % py)
	else:
		_fail("水塘穿模或卡住: 玩家 y=%.1f (期望 36~42)" % py)

	# 2) 向西走向农田栅栏,应被列11栅栏挡住(玩家x不得小于约195)
	await _push(player, Vector2(13 * 16 + 8, 16 * 16 + 8), Vector2(-1, 0), 90)
	var px: float = player.global_position.x
	if px > 195.0 and px < 212.0:
		_pass("农田栅栏阻挡正常, 玩家停在 x=%.1f" % px)
	else:
		_fail("栅栏穿模或卡住: 玩家 x=%.1f (期望 195~212)" % px)

	# 3) 沿主路向东走,应畅通(玩家x明显增加)
	await _push(player, Vector2(20 * 16 + 8, 10 * 16 + 8), Vector2(1, 0), 90)
	px = player.global_position.x
	if px > 360.0:
		_pass("主路通行正常, 玩家走到 x=%.1f" % px)
	else:
		_fail("主路被阻挡: 玩家 x=%.1f (期望 >360)" % px)

	# 4) 沿支路向北走向房门,应被门挡住(门碰撞y80-96 → 玩家y不得小于约97)
	await _push(player, Vector2(6 * 16 + 8, 7 * 16 + 8), Vector2(0, -1), 90)
	py = player.global_position.y
	if py > 97.0 and py < 118.0:
		_pass("房门阻挡正常, 玩家停在 y=%.1f" % py)
	else:
		_fail("房门穿模或卡住: 玩家 y=%.1f (期望 97~118)" % py)

	# 5) 向北走向北墙,应被石墙挡住(墙在行0 y0~16 → 玩家碰撞圆上缘y-1=16 → y=17)
	await _push(player, Vector2(20 * 16 + 8, 2 * 16 + 8), Vector2(0, -1), 90)
	py = player.global_position.y
	if py > 15.0 and py < 19.0:
		_pass("北墙阻挡正常, 玩家停在 y=%.1f" % py)
	else:
		_fail("北墙穿模或卡住: 玩家 y=%.1f (期望 15~19)" % py)

	_finish()

func _find_player(root: Node) -> CharacterBody2D:
	if root is CharacterBody2D:
		return root
	for c in root.get_children():
		var found: CharacterBody2D = _find_player(c)
		if found != null:
			return found
	return null

## 把玩家放到 pos,用 InputManager 摇杆接口持续推 dir 方向 frames 帧。
func _push(player: CharacterBody2D, pos: Vector2, dir: Vector2, frames: int) -> void:
	player.global_position = pos
	await get_tree().process_frame
	InputManager.set_joystick_vector(dir)
	for i in frames:
		await get_tree().process_frame
	InputManager.reset_joystick()
	await get_tree().process_frame

func _finish() -> void:
	print("\n村庄地图回归: ", ("全部通过" if _failed == 0 else "%d 项失败" % _failed))
	get_tree().quit(_failed)
