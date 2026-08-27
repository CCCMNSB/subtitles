# subtitles

给 PipePipe（弹幕翻译 fork）用的「在线字幕」仓库。

## 用途
PipePipe 播放视频时，手动点播放器里的「字幕」按钮，会按 **视频 ID** 在这个仓库的 `subtitles/` 文件夹里在线拉取字幕文件并渲染。

## 目录结构
```
subtitles/                     ← 字幕文件（App 按视频 ID 在这里找）
  9FLSPQT12mA.ass                <视频ID>.ass    （Aegisub，含说话人分离/位置/标签）
  9FLSPQT12mA.srt                <视频ID>.srt    （兜底/纯文本）
index/                         ← 清单单独一个文件夹
  index.json                    [{id, title, date}]，顺序即显示顺序（建议最新在前）
add-subtitle.ps1                ← 一键推送：选两个文件+填id/标题/日期 → 复制+更新index+git推送
generate-index.ps1              ← 扫描 subtitles/ 自动补 index（标题 oEmbed、日期 uploadDate）
README.md
```

## 一键添加字幕（推荐）
在仓库根目录运行：`powershell -ExecutionPolicy Bypass -File add-subtitle.ps1`
- 弹窗选 **ASS** 和 **SRT** 两个字幕文件；
- 输入 **视频 ID**（必填）、**标题**（可选，不填自动用 oEmbed）、**日期**（可选，不填自动抓 uploadDate）；
- 自动：复制到 `subtitles/<id>.ass|.srt` + 更新 `index/index.json`（新增放最前=最新在前）+ `git commit` + `git push`。
- 参数模式：`-Ass a.ass -Srt a.srt -Id abc123 -Title "标题" -Date 2024-01-01`；加 `-NoPush` 只改本地不推送。

## 命名约定（App 端加载地址）
- App 加载字幕 = `https://raw.githubusercontent.com/CCCMNSB/subtitles/main/subtitles/<视频ID>.ass`，失败再试 `.srt`。
- 视频 ID = 该视频链接 `?v=` 后的那串（如 `9FLSPQT12mA`）。
- 所以**把字幕文件命名为 `<视频ID>.ass`**（或 `.srt`）放进 `subtitles/` 文件夹即可。
- **列表/搜索**：维护 `index/index.json`（`[{id,title}]`），App 会显示标题+封面、按标题搜索、按数组顺序（最新在前）排列。新增字幕后在仓库根目录跑 `generate-index.ps1` 可自动补标题。

## ASS 说话人分离建议
- 用 Aegisub 分配好**固定位置**和**说话人标签**（写入 `Dialogue` 的 `Name` 字段或独立 `Style`），App 会尊重位置、并按说话人分配不同的边框颜色。

## 说明
- 仅个人/爱好者用途，字幕著作权归原作者；请勿放置版权受限的外文字幕。
- 仓库公开，供 App 在线加载。
