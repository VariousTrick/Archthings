# Archthings

这是一个只保留“我们自己写的桌面资源”的仓库。

它目前主要收纳两类内容：

- `.codex-shell`
  - 基于 `Quickshell` 的自定义面板原型
  - 当前已完成：
    - 电池面板
    - 音量面板
    - Wi‑Fi 面板
- `.codex-waybar`
  - `waybar` 相关脚本与资源
  - 包含：
    - 剪贴板菜单脚本与主题
    - 电源菜单脚本与主题
    - 电池阈值切换脚本
    - 早期电池/waybar 原型资源

这个仓库**故意不包含**外部参考项目与整套主题仓库，例如：

- `HyDE`
- `DankMaterialShell / DMS`
- `orbit`
- `mechabar`
- `shorin-niri`

这些项目只作为参考，不作为最终依赖提交。

## 当前结构

```text
.codex-shell/
  battery-panel/
  volume-panel/
  wifi-panel/

.codex-waybar/
  clipboard-menu.sh
  clipboard-hyde.rasi
  power-menu.sh
  power-menu.rasi
  battery-care-toggle-user.sh
  ...
```

## 依赖

按当前仓库内容，比较重要的运行依赖有这些：

- `niri`
- `waybar`
- `quickshell`
- `qt6-base`
- `qt6-declarative`
- `qt6-wayland`
- `qt6-svg`
- `pipewire`
- `pipewire-pulse`
- `wireplumber`
- `wpctl`
- `power-profiles-daemon`
- `powerprofilesctl`
- `rofi`
- `cliphist`
- `wl-clipboard`
- `mako`
- `networkmanager`
- `nmcli`

如果你要使用仓库中的部分功能，还会遇到这些可选依赖：

- `sddm`
  - 登录管理器
- `fcitx5` / `fcitx5-rime`
  - 输入法

目前仓库里的 Wi‑Fi 面板已经不再依赖 `orbit-wifi` 作为入口。
如果以后继续做蓝牙面板，再视实现方式决定是否保留 `orbit`。

## 当前可用功能

### 1. 电池面板

路径：

- `.codex-shell/battery-panel`

能力：

- 电量信息
- 电量进度条
- 电源模式切换
- 80% 充电限制开关
- 位置可拖拽并记忆

### 2. 音量面板

路径：

- `.codex-shell/volume-panel`

能力：

- 扬声器 / 麦克风各自独立控制
- 点击图标静音 / 取消静音
- 0-100 音量滑条
- 默认输入 / 输出设备切换
- 二级设备列表

### 3. Waybar 辅助脚本

路径：

- `.codex-waybar`

包含：

- 剪贴板菜单
- 电源菜单
- 电池阈值切换
- 一些早期原型与样式资源

### 4. Wi‑Fi 面板

路径：

- `.codex-shell/wifi-panel`

能力：

- Wi‑Fi 总开关
- 已连接 / 可用网络分区
- 可用网络列表滚动
- 加密网络行内密码输入
- 隐藏网络手动连接
- 位置可拖拽并记忆

## 使用说明

这个仓库当前更像“资源与原型归档”，不是一键安装包。

你在新机器上大致需要：

1. 安装依赖
2. 把 `.codex-shell` / `.codex-waybar` 放到自己希望的位置
3. 再手动把 `waybar` 或 `niri` 配置接到这些脚本与面板入口

也就是说，它现在保存的是：

- 我们已经做好的面板和脚本
- 相关资源与主题
- 开发脉络

不是整套自动部署器。

## 后续计划

- 继续统一 `Quickshell` 面板风格
- 逐步把更多高频交互从 `waybar + 外部程序` 迁移到自定义面板
- 未来可能演进到统一常驻 shell，而不是“一按钮一实例”

详细开发过程见：

- `DEVELOPMENT_LOG.md`
