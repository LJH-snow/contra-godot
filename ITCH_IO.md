# 发布到 itch.io 指南

网页版已构建完成（`export/web/`，约 39MB，无线程变体，任何静态托管都能跑）。
以下步骤需要你的 itch.io 账号，一分钟搞定。

## 方式一：网页上传（最快）

1. 打开 https://itch.io/game/new 创建新项目
2. 标题填 `魂斗罗 CONTRA`，项目 URL 如 `your-name/contra`
3. 「Kind of project」选 **HTML**（关键！这样 itch.io 会托管可玩的网页版）
4. 上传 `export/web.zip`（见下方打包命令），勾选 **"This file will be played in the browser"**
5. Viewport 尺寸填 `960×720`，勾选Fullscreen按钮
6. Publish → 完成，分享链接即可游玩

## 方式二：butler 命令行（后续更新方便）

```bash
# 安装一次
brew install butler

# 首次登录（浏览器授权）
butler login

# 推送（user name 换成你的 itch.io 用户名, game 名换成项目 URL）
butler push export/web your-name/contra:html5 --userversion "1.0.0"
```

以后改了游戏，重新 `--export-release` 再 push 同一条命令即可增量更新。

## 本地预览

```bash
cd export/web && python3 -m http.server 8767
# 浏览器打开 http://127.0.0.1:8767
```

## 桌面版（可选）

```bash
# macOS
GODOT="$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot"
"$GODOT" --headless --export-release "macOS" export/mac/魂斗罗.zip   # 需先建 macOS 预设
```

macOS 导出注意：非 App Store 分发需要签名/公证，或让玩家右键打开。
