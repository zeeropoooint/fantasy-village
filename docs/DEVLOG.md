# 开发日志 · Fantasy Village（西幻生活模拟）

> 规则:每次重要更新(新功能、Bug 修复、设计变更、里程碑推进)都在本文档顶部追加一条记录。
> 设计规格见 [2026-10-11-fantasy-village-design.md](specs/2026-10-11-fantasy-village-design.md)。

---

## 2026-10-31 · v1.0 发布

### 里程碑
- 初始化 Git 仓库,以 M0「村庄漫步」作为首个可玩版本打 `v1.0` 标签并发布 GitHub Release
- 仓库:[zeeropoooint/fantasy-village](https://github.com/zeeropoooint/fantasy-village)(公开)
- Release:https://github.com/zeeropoooint/fantasy-village/releases/tag/v1.0
- 新增 `.gitignore`:忽略 `.godot/` 运行时缓存与导出产物,保留所有 `*.import` 元数据

## 2026-10-24 · 修复:屏幕级 UI 脱离相机变换

### 修复
- **对话框/天数横幅/奖励提示漂移**:npc.gd 对话框、bed.gd「第 N 天」横幅、sign.gd 奖励 toast 之前直接挂 `get_tree().root`(默认画布),受玩家相机 transform 影响,UI 以地图坐标系渲染,玩家只能看到一小部分;现统一挂入独立 CanvasLayer(对话框 layer=40、横幅/toast layer=60),固定于屏幕:对话框铺满底部、天数横幅屏幕居中、toast 屏幕上方居中
- 横幅/toast 改用全屏锚点 + 居中对齐,不再手写像素偏移猜文字宽度

### 技术决策
- Godot 相机变换作用于整个默认画布:直接加到场景根/Window 的 Control 会跟着相机跑;屏幕级 UI 必须放 CanvasLayer(HUD/小游戏宿主原本就是,无此问题)
- 验证方式:临时 capture_ui.tscn 直接调 `npc.interact()`/`bed.interact()` 截图确认对话框铺满屏幕底部、横幅居中(验证后已删)

---

## 2026-10-24 · M0 完善:村庄大地图 + 防穿模重构 + 视觉修复

### 新增
- **村庄地图重设计**(`village.gd`):40×22 石墙环绕村庄,含石板围栏水塘、栅栏农田、横贯主路+支路、12 棵 y-sort 树(树冠可遮挡玩家)、3×3 房子、药剂师 NPC、木牌;碰撞由字符地图自动生成(`collision_rects_for` 按行合并),与视觉严格对齐
- **全景截图工具** `tests/capture_village.tscn`(常驻):实例化村庄 + zoom=1 相机对准地图中心,保存 `user://village_overview.png`;本轮靠它定位深色方块缺陷,效果见 [m0-village-2026-10-24.png](screenshots/m0-village-2026-10-24.png)
- **村庄地图回归测试** `tests/test_village_map.tscn`:静态校验(22 行×40 字符)+ 实心格碰撞覆盖穷举 + 物理防穿模(水塘/栅栏/房门/北墙阻挡 + 主路通行)8 项断言

### 修复
- **玩家穿模**:碰撞不再手写坐标,树木干碰撞加宽防钻树冠,房子碰撞与 sprite 对齐
- **深色方块(瓦片缺失)**:装饰字符(F/W/X/,/*)只在 Decor 层绘制,Ground 层留空透出视口底色;改为地面层先全图铺不透明草地兜底再按字符绘制,Python 逐格复扫确认 0 缺失
- **bed.png / alchemist.png 深色背景**:生成时留了不透明 (30,30,40) 底色,床会盖住卧室地板;边缘洪泛填充转透明(player.png 内部深色为衣服设计色,未动)
- **bedroom.gd**:地图 17 字符行修正 + 床碰撞错位修复;`interactable.gd` 解析错误修复
- **瓦片美化**:蘑菇/小草改透明底座、石子草改草绿底(tiles.png)

### 技术决策
- Godot 命令行运行不自动刷新导入缓存:改 PNG 后须删 `.godot/imported/<name>-*` 并跑 `--import`(或靠编辑器文件监听自动重导),否则 preload 到旧图甚至空图
- PowerShell 启动 Godot(GUI 子系统)不等待退出,自动化须 `Start-Process -Wait -RedirectStandardOutput/Error`
- 全景图坐标系:1280×720 视口,格(col,row)→像素(320+col×16, 184+row×16);逐格匹配视口底色 (59,59,77) 可判定瓦片缺失

### 测试
- 三套 headless 全绿:核心 25 项 + 卧室回归 3 项 + 村庄地图 8 项(`--quit-after 2000`,物理测试需足够帧数)

## 2026-10-11 · 新增玩家操作指南

### 新增
- `docs/player_guide.md`:面向玩家的操作说明,覆盖移动(WASD/方向键/虚拟摇杆)、互动(空格/E/右下按钮)、对话推进与选项、节奏小游戏玩法、睡觉过天与自动存档、HUD 说明及快速上手路线;内容与当前输入映射逐一核对过

## 2026-10-11 · M0 村庄漫步 完成

### 新增
- **Godot 4.7.2 项目骨架**(`fantasy_village/`):640×360 视口、`canvas_items` 拉伸、GL Compatibility 渲染、16px 像素过滤
- **Autoload 单例六件套**:
  - `GameState`:金币/好感度/剧情标志/背包 + 变更信号;跨场景临时传递 `pending_spawn`
  - `TimeManager`:day + minute_of_day 最小时钟,`sleep_to_next_day()` 重置 6:00;季节/星期预留
  - `SaveManager`:JSON 存档至 `user://save_slot_N.json`,带 version 字段与迁移函数链
  - `SceneManager`:淡入淡出转场(0.4s,转场期拦截输入)
  - `InputManager`:键盘 WASD 与虚拟摇杆统一抽象为 `move_vector`
  - `AudioManager`:4 池音效播放 + BGM 通道
- **交互系统**:`interactable` 组约定 + `InteractionDetector`(范围内选最近目标,信号驱动 UI)
- **对话系统**:JSON 驱动、打字机逐字、选项分支、条件表达式(`has_flag` / `affinity[...]` / `day`)
- **小游戏宿主** `MiniGameHost`:暂停世界 → 装载 → `finished(score)` → 恢复 + 回调结算;首个小游戏「节奏点击」(5 音符,≥3 次击中发 30 金币,否则 10)
- **场景**:卧室(床/门) ↔ 村庄(药剂师 NPC/木牌/树/房/水塘),ASCII 字符地图 + 运行时 TileSet 构建
- **UI**:HUD(金币+时间)、虚拟摇杆(左下)、交互按钮(右下 ≥88px)
- **占位素材**:Python 程序化生成 16×16 像素图(角色四向三帧/药剂师/地块/树/房/床/木牌)+ 7 个波形音效;架构与美术解耦,后续整体换手绘
- **测试**:`tests/run_tests.gd` 25 项断言(时间/状态/存档往返/对话条件/成绩结算)全通过;`tests/test_bedroom_regression.tscn` 场景级回归

### 修复
- **右向行走贴图缺失**:素材脚本漏贴 spritesheet 第 4 行,改为左向帧水平翻转写入
- **靠近床 1 格崩溃**:交互按钮 `pressed.connect(fn).bind(t)` 在 connect 返回值(int)上调用 bind,信号触发即报错;改为按钮只连一次、回调时读 detector 当前目标(卧室+村庄同修)

### 技术决策
- `Interactable` 不用 `extends "path"`/`class_name` 继承链(Godot 4.7 headless 解析有坑),各交互物直接 `extends StaticBody2D` 内联 3 行共享逻辑
- TileSet 手写 `.tres` 过繁琐,用 `tile_set_factory.gd` 运行时从 `tiles.png` 切片构建
- 测试不依赖 GUT 插件,自带最小断言 runner(以主场景方式跑,`--script` 模式下 Autoload 不注册)

### 待办 / 下一步
- [ ] 安卓真机 APK 验证(摇杆+交互按钮误触测试) — M0 验收剩余项
- [ ] M1 种植经营:地块网格(翻/种/浇)、作物按天生长、背包、出货箱经济
