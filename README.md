# subtitles

给 PipePipe（弹幕翻译 fork）用的「在线字幕」仓库。

## 用途
PipePipe 播放视频时，手动点播放器里的「字幕」按钮，会按 **视频 ID** 在这个仓库的 `subtitles/` 文件夹里在线拉取字幕文件并渲染。

## 目录结构
```
subtitles/                     ← App 默认只在这个文件夹里找
  9FLSPQT12mA.ass                <视频ID>.ass    （Aegisub，含说话人分离/位置/标签）
  9FLSPQT12mA.srt                <视频ID>.srt    （兜底/纯文本）
README.md
```

## 命名约定（App 端加载地址）
- App 加载地址 = `https://raw.githubusercontent.com/CCCMNSB/subtitles/main/subtitles/<视频ID>.ass`，失败再试 `.srt`。
- 视频 ID = 该视频链接 `?v=` 后的那串（如 `9FLSPQT12mA`）。
- 所以**把字幕文件命名为 `<视频ID>.ass`**（或 `.srt`）放进 `subtitles/` 文件夹即可。

## ASS 说话人分离建议
- 用 Aegisub 分配好**固定位置**和**说话人标签**（写入 `Dialogue` 的 `Name` 字段或独立 `Style`），App 会尊重位置、并按说话人分配不同的边框颜色。

## 说明
- 仅个人/爱好者用途，字幕著作权归原作者；请勿放置版权受限的外文字幕。
- 仓库公开，供 App 在线加载。
