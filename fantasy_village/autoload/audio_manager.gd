extends Node
## 音频统一播放入口。BGM 与音效分开管理。

const SFX_PATH := {
    "ui_click": "res://assets/audio/ui_click.wav",
    "coin": "res://assets/audio/coin.wav",
    "door": "res://assets/audio/door.wav",
    "sleep": "res://assets/audio/sleep.wav",
    "hit": "res://assets/audio/hit.wav",
    "miss": "res://assets/audio/miss.wav",
    "talk": "res://assets/audio/talk.wav",
}

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 4

func _ready() -> void:
    _music_player = AudioStreamPlayer.new()
    _music_player.bus = "Master"
    add_child(_music_player)
    for i in SFX_POOL_SIZE:
        var p := AudioStreamPlayer.new()
        add_child(p)
        _sfx_players.append(p)

func play_sfx(name: String) -> void:
    if not SFX_PATH.has(name):
        push_warning("AudioManager: 未知音效 %s" % name)
        return
    var stream := load(SFX_PATH[name])
    if stream == null:
        push_warning("AudioManager: 加载音效失败 %s" % SFX_PATH[name])
        return
    for p in _sfx_players:
        if not p.playing:
            p.stream = stream
            p.play()
            return
    # 池全忙，复用第一个
    var p := _sfx_players[0]
    p.stream = stream
    p.play()

func play_music(path: String, volume_db: float = -6.0) -> void:
    var stream := load(path)
    if stream == null:
        push_warning("AudioManager: 加载 BGM 失败 %s" % path)
        return
    if _music_player.stream == stream and _music_player.playing:
        return
    _music_player.stream = stream
    _music_player.volume_db = volume_db
    _music_player.play()

func stop_music() -> void:
    _music_player.stop()
