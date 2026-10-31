extends CanvasLayer
## HUD:显示金币与时间。订阅 GameState / TimeManager 信号。

@onready var coin_label: Label = $TopBar/CoinLabel
@onready var time_label: Label = $TopBar/TimeLabel

func _ready() -> void:
    GameState.coins_changed.connect(_on_coins_changed)
    TimeManager.time_changed.connect(_on_time_changed)
    _on_coins_changed(GameState.coins)
    _on_time_changed(TimeManager.day, TimeManager.minute_of_day)

func _on_coins_changed(c: int) -> void:
    coin_label.text = str(c)

func _on_time_changed(day: int, minute: int) -> void:
    time_label.text = "Day %d  %s" % [day, TimeManager.format_clock()]
