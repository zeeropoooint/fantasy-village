extends CharacterBody2D
class_name Player
## 玩家角色。四方向移动 + 精灵帧动画 + 相机跟随 + 交互探测。

const SPEED: float = 70.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detector: Area2D = $InteractionDetector
@onready var camera: Camera2D = $Camera2D

var _facing: String = "down"

func _ready() -> void:
    # 注册四个方向动画帧(从 player.png 切片)
    sprite.sprite_frames = _build_sprite_frames()
    sprite.play("idle_down")

func _process(_delta: float) -> void:
    var move := InputManager.move_vector
    if move.length() > 0.05:
        velocity = move * SPEED
        _update_facing(move)
        var anim := "walk_%s" % _facing
        if sprite.animation != anim:
            sprite.play(anim)
    else:
        velocity = Vector2.ZERO
        var anim := "idle_%s" % _facing
        if sprite.animation != anim:
            sprite.play(anim)
    move_and_slide()

func _update_facing(move: Vector2) -> void:
    if abs(move.x) > abs(move.y):
        _facing = "right" if move.x > 0 else "left"
    else:
        _facing = "down" if move.y > 0 else "up"

func _build_sprite_frames() -> SpriteFrames:
    var sf := SpriteFrames.new()
    var tex: Texture2D = preload("res://assets/sprites/player.png")
    var dirs := {
        "down": 0,
        "up": 1,
        "left": 2,
        "right": 3,
    }
    for dir_name in dirs.keys():
        var row: int = dirs[dir_name]
        var idle_name := "idle_%s" % dir_name
        var walk_name := "walk_%s" % dir_name
        sf.add_animation(idle_name)
        sf.set_animation_speed(idle_name, 3.0)
        sf.set_animation_loop(idle_name, false)
        sf.add_frame(idle_name, _frame(tex, 0, row))
        sf.add_animation(walk_name)
        sf.set_animation_speed(walk_name, 6.0)
        sf.set_animation_loop(walk_name, true)
        sf.add_frame(walk_name, _frame(tex, 0, row))
        sf.add_frame(walk_name, _frame(tex, 1, row))
        sf.add_frame(walk_name, _frame(tex, 2, row))
    return sf

func _frame(tex: Texture2D, col: int, row: int) -> AtlasTexture:
    var at := AtlasTexture.new()
    at.atlas = tex
    at.region = Rect2(col * 16, row * 16, 16, 16)
    return at
