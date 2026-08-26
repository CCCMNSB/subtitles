# subtitles

给 PipePipe（弹幕翻译 fork）用的「在线字幕」仓库。

## 用途
PipePipe 播放视频时，手动点播放器里的「字幕」按钮，会按 **视频 ID** 在这个仓库的 `subtitles/` 文件夹里在线拉取字幕文件并渲染。

## 目录结构
```
subtitles/                     ← App 默认只在这个文件夹里找
  index.json                    ← 字幕清单：[{id, title}]，顺序即显示顺序（建议最新在前）
  9FLSPQT12mA.ass                <视频ID>.ass    （Aegisub，含说话人分离/位置/标签）
  9FLSPQT12mA.srt                <视频ID>.srt    （兜底/纯文本）
generate-index.ps1              ← 扫描 subtitles/ 自动生成 index.json（oEmbed 填标题）
README.md
```

## 命名约定（App 端加载地址）
- App 加载地址 = `https://raw.githubusercontent.com/CCCMNSB/subtitles/main/subtitles/<视频ID>.ass`，失败再试 `.srt`。
- 视频 ID = 该视频链接 `?v=` 后的那串（如 `9FLSPQT12mA`）。
- 所以**把字幕文件命名为 `<视频ID>.ass`**（或 `.srt`）放进 `subtitles/` 文件夹即可。
- **列表/搜索**：维护 `subtitles/index.json`（`[{id,title}]`），App 会显示标题+封面、按标题搜索、按数组顺序（最新在前）排列。新增字幕后在仓库根目录跑 `generate-index.ps1` 可自动补标题。

## ASS 说话人分离建议
- 用 Aegisub 分配好**固定位置**和**说话人标签**（写入 `Dialogue` 的 `Name` 字段或独立 `Style`），App 会尊重位置、并按说话人分配不同的边框颜色。

## 说明
- 仅个人/爱好者用途，字幕著作权归原作者；请勿放置版权受限的外文字幕。
- 仓库公开，供 App 在线加载。
