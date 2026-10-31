extends Node
## 游戏时钟。M0 只做最小版:day + minute_of_day(0..1439)。
## 不做真实推进(M0 不跑时钟循环)，仅由睡觉等事件改写。
## 季节/星期/年预留扩展位。

signal time_changed(day: int, minute_of_day: int)
signal day_changed(new_day: int)

const MINUTES_PER_DAY: int = 24 * 60
const WAKE_HOUR: int = 6    # 每天起床时间 6:00

var day: int = 1
var minute_of_day: int = WAKE_HOUR * 60

## 季节枚举(M2 扩展)
enum Season { SPRING, SUMMER, AUTUMN, WINTER }
var season: int = Season.SPRING
var weekday: int = 0   # 0..6

func set_time(d: int, minute: int) -> void:
    day = d
    minute_of_day = clamp(minute, 0, MINUTES_PER_DAY - 1)
    time_changed.emit(day, minute_of_day)

func add_minutes(delta_minutes: int) -> void:
    var total = minute_of_day + delta_minutes
    var rolled_days = int(floor(float(total) / float(MINUTES_PER_DAY)))
    minute_of_day = posmod(total, MINUTES_PER_DAY)
    if rolled_days != 0:
        day += rolled_days
        day_changed.emit(day)
    time_changed.emit(day, minute_of_day)

## 睡觉:天数 +1，时钟重置到起床时间。
func sleep_to_next_day() -> void:
    day += 1
    minute_of_day = WAKE_HOUR * 60
    day_changed.emit(day)
    time_changed.emit(day, minute_of_day)

## 把 minute_of_day 转成 "HH:MM" 显示串。
func format_clock() -> String:
    var h: int = minute_of_day / 60
    var m: int = minute_of_day % 60
    return "%02d:%02d" % [h, m]

func to_dict() -> Dictionary:
    return {
        "day": day,
        "minute_of_day": minute_of_day,
        "season": int(season),
        "weekday": weekday,
    }

func from_dict(d: Dictionary) -> void:
    day = int(d.get("day", 1))
    minute_of_day = int(d.get("minute_of_day", WAKE_HOUR * 60))
    season = int(d.get("season", Season.SPRING))
    weekday = int(d.get("weekday", 0))
    time_changed.emit(day, minute_of_day)
