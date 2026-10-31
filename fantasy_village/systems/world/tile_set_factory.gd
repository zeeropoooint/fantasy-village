class_name TileSetFactory
extends RefCounted
## 运行时从 tiles.png 构建 TileSet。避免手写复杂的 .tres。
## tiles.png: 8 列 x 3 行，每格 16x16。

static func build(tiles_path: String = "res://assets/sprites/tiles.png") -> TileSet:
    var tex: Texture2D = load(tiles_path)
    var ts := TileSet.new()
    ts.tile_size = Vector2i(16, 16)
    var src := TileSetAtlasSource.new()
    src.texture = tex
    src.texture_region_size = Vector2i(16, 16)
    src.separation = Vector2i(0, 0)
    var src_id: int = ts.add_source(src)
    # 创建所有 8x3 瓦片
    for y in range(3):
        for x in range(8):
            src.create_tile(Vector2i(x, y))
    return ts

## 把字符地图画到 TileMapLayer。map: String[] (每行等长)。
## char_map: char -> {atlas: Vector2i, layer: int, solid: bool}
static func paint(map: TileMapLayer, rows: PackedStringArray, char_map: Dictionary) -> void:
    for y in range(rows.size()):
        var line: String = rows[y]
        for x in range(line.length()):
            var ch: String = line.substr(x, 1)
            if char_map.has(ch):
                var spec: Dictionary = char_map[ch]
                var atlas: Vector2i = spec.get("atlas", Vector2i(0, 0))
                var layer: int = int(spec.get("layer", 0))
                map.set_cell(Vector2i(x, y), 0, atlas, layer)
