# subtitles

给 PipePipe（弹幕翻译 fork）用的「在线字幕」仓库。

## 用途
PipePipe App 在播放视频时，会按「视频 ID」从这个仓库在线拉取字幕文件并渲染。

## 目录结构
```
test.ja.pass1/          ← 每个视频一个文件夹（或用 <videoID>.ass 直接平铺）
  test.ja.pass1.ass       ASS 字幕（Aegisub，含说话人分离/位置/标签）
  test.ja.pass1.srt       SRT 字幕（纯文本）
```

## 命名约定（App 端加载地址）
- App 通过设置里的「仓库地址 + 视频 ID」拼出字幕 URL。
- 建议每部影片一个字幕文件：
  - `https://raw.githubusercontent.com/CCCMNSB/subtitles/main/<videoID>.ass`
  - 或按内容分类后平铺/分文件夹。
- ASS 建议用 Aegisub 分配好**固定位置**和**说话人标签**（写入 `Dialogue` 的 `Name` 字段或 `Style`），App 会按说话人自动分配不同的边框颜色并尊重 ASS 的位置。

## 说明
- 仅个人/爱好者用途，字幕著作权归原作者；请勿放置版权受限的外文字幕。
- 仓库公开，供 App 在线加载。
