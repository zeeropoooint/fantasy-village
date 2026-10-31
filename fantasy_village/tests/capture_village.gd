extends Node
## 常驻开发工具:实例化村庄场景,用全景相机(zoom=1)对准地图中心,渲染后保存 PNG 到 user://。
## 用法: godot --path fantasy_village --resolution 1280x720 res://tests/capture_village.tscn
## 注意: PowerShell 启动 Godot(GUI 子系统)不等待退出,须用 Start-Process -Wait 包一层。

func _ready() -> void:
	var village: Node2D = load("res://scenes/world/village.tscn").instantiate()
	add_child(village)
	await get_tree().process_frame
	await get_tree().process_frame

	# 全景相机抢过玩家相机(玩家相机带 smoothing,会缓慢跟随)
	var cam := Camera2D.new()
	cam.position = Vector2(320, 176) # 40x22 格地图中心
	cam.zoom = Vector2(1, 1)
	add_child(cam)
	cam.make_current()

	# 隐藏 UI 层,只验证世界渲染
	for child in village.get_children():
		if child is CanvasLayer or child is Control:
			child.visible = false

	# 等几帧确保 TileMap/y-sort 渲染稳定
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var img := get_viewport().get_texture().get_image()
	var path: String = OS.get_data_dir() + "/village_overview.png"
	img.save_png(path)
	print("OVERVIEW_SAVED:" + path)
	get_tree().quit()
