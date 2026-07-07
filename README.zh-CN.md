# BlackPoint

[English](README.md) · **简体中文**

BlackPoint 是一个紧凑的 macOS 菜单栏工具，用来把暂时不需要的应用安静收起，而不是退出它们。

## 安装

```sh
curl -fsSL https://7757.github.io/BlackPoint/install.sh | bash
```

也可以从 [GitHub Releases](https://github.com/7757/BlackPoint/releases/latest) 下载最新版。

## 功能

- 用全局快捷键收起当前应用。
- 保留当前应用，批量收起其他运行中的应用。
- 已收起应用被重新激活时，可自动再次收起。
- 可选过滤 `Command + Tab`，跳过已收起应用。
- 支持自定义快捷键。
- 支持开机启动。
- 应用内支持英文和简体中文。

## 默认快捷键

| 操作 | 快捷键 |
| --- | --- |
| 收起当前应用 | `Control + Option + Command + B` |
| 收起其他应用 | `Control + Option + Command + A` |
| 打开 BlackPoint | `Control + Option + Command + Space` |
| 切到下一个可见应用 | `Command + Tab` |
| 切到上一个可见应用 | `Shift + Command + Tab` |

## 说明

macOS 不允许普通应用永久把其他应用改成后台代理。BlackPoint 使用公开 API 隐藏窗口、保持已收起应用隐藏，并在开启后过滤应用切换。
