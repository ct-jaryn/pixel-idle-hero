# 像素挂机勇者 (Pixel Idle Hero)

一个使用 **Godot 4.3** 制作的 2.5D 像素风格自动挂机 RPG，灵感来自经典《勇者斗恶龙》系列。

在线试玩：https://ct-jaryn.github.io/pixel-idle-hero/（如已部署 GitHub Pages）

仓库地址：https://github.com/ct-jaryn/pixel-idle-hero

## 核心玩法

- **自动战斗**：勇者自动攻击敌人，无需手动操作。
- **挂机升级**：击败敌人获得 EXP 和金币，自动升级提升属性。
- **关卡推进**：普通敌人随波次增强，每 5 关可挑战一次 Boss。
- **Boss 挑战**：点击「挑战 Boss」讨伐更强敌人，胜利后进入下一区域。
- **装备系统**：击败敌人会掉落武器、头盔、护甲、鞋子、戒指；装备后可大幅提升战力，支持装备、卸下、出售、一键最佳、强化。
- **技能系统**：战斗中积攒能量，释放治疗术、重击、狂暴三种主动技能。
- **商店系统**：购买生命药水、永久攻击/防御卷轴、经验药水、装备宝箱。
- **成就与任务**：完成击杀、升级、Boss 等成就获取奖励；日常任务提供额外目标。
- **统计面板**：查看击杀数、金币、伤害、死亡次数、最高关卡等数据。
- **暂停菜单**：按 ESC 打开暂停菜单，可继续、返回标题、重置存档、退出。
- **自动存档**：每 10 秒自动保存进度，关闭后可通过标题画面「继续游戏」读取。
- **新手引导**：首次进入游戏时提供高亮分步引导。
- **音效与 BGM**：包含攻击、受击、升级、金币音效及 8-bit 风格循环背景音乐。

## 快捷键

| 按键 | 功能 |
|---|---|
| `Esc` | 打开/关闭暂停菜单（子界面打开时先关闭子界面） |
| `E` | 打开装备栏 |
| `S` | 打开商店 |
| `T` | 打开统计面板 |
| `A` | 打开成就面板 |
| `Q` | 打开任务面板 |
| `1` / `2` / `3` | 施放技能 |

## 项目结构

```
pixel-idle-hero/
├── project.godot              # Godot 项目配置
├── export_presets.cfg         # Web 导出预设
├── default_bus_layout.tres    # 音频总线布局
├── assets/
│   ├── fonts/                 # 中文字体（Noto Sans CJK SC）
│   ├── images/                # 像素素材（角色、怪物、UI、背景）
│   ├── sounds/                # 8-bit 音效与 BGM
│   └── themes/                # 全局主题（default_theme / enhanced_theme）
├── scripts/
│   ├── autoload/              # 自动加载单例（EventBus、BalanceConfig）
│   ├── characters/            # 勇者、敌人视觉与动画
│   ├── data/                  # 玩家、装备、技能、成就、任务数据
│   ├── effects/               # 音频、飘字、震动、粒子
│   ├── enemies/               # 敌人数据、Boss 机制
│   ├── managers/              # 战斗、关卡、装备、技能、商店、存档、成就、任务、奖励、总控
│   └── ui/                    # 标题画面、子界面基类
├── scenes/                    # 游戏场景（标题、主场景、勇者、敌人、音频、粒子）
├── ui/                        # 战斗、装备、商店、统计、成就、任务、暂停、引导、成就提示等 UI
├── tests/                     # 单元测试框架（test_runner）
├── tasks/                     # 生图/动画任务定义（JSON）
└── tools/                     # 截图、动画生成、资源处理脚本
```

## 运行方式

### 1. Godot 编辑器

1. 用 Godot 4.3 打开 `pixel-idle-hero/` 文件夹。
2. 按 **F5** 或点击「运行项目」。

### 2. 命令行导出 Web

```bash
./Godot_v4.3-stable_win64_console.exe --headless --export-release "Web" ../web-export/index.html
```

启动本地服务器预览：

```bash
cd ../web-export
python -m http.server 8765
# 浏览器打开 http://localhost:8765
```

> Web 导出产物位于仓库根目录的 `web-export/`（`index.html` / `index.js` / `index.wasm` / `index.pck` 等），可直接部署到静态托管（如 GitHub Pages）。

### 3. 运行单元测试

```bash
./Godot_v4.3-stable_win64_console.exe --headless --script res://tests/test_runner.gd
```

## 中文显示说明

本项目使用 **Noto Sans CJK SC（思源黑体）** 作为默认字体，已在 `assets/themes/default_theme.tres` 中配置，并通过 `project.godot` 的全局主题生效，确保 Label、Button、RichTextLabel 等 UI 控件正确显示中文。

> 完整中文字体约 16 MB，Web 导出的 `.pck` 会因此变大。如需优化加载速度，可替换为只包含常用汉字的子集字体。

## 美术与音频素材

- **图片素材**：勇者/怪物动画、装备图标、背景等均通过生图服务生成，并经本地脚本切分、去背、缩放。
- **音效与 BGM**：使用 Python 脚本程序化生成 8-bit 风格 WAV 文件。

## 后续可扩展方向

- 技能树与更多主动/被动技能
- 宠物/伙伴系统
- 转生（Prestige）与天赋系统
- 更多 Boss 机制与阶段
- 更多怪物动画与精英怪
- 云端存档与排行榜
