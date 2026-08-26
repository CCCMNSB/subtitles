# generate-index.ps1
# 扫描本仓库 subtitles/ 文件夹里的 <视频ID>.ass/.srt，生成 subtitles/index.json。
# 格式: [ { "id": "...", "title": "..." } ]，数组顺序即列表显示顺序（建议最新在前）。
# 标题通过 YouTube 公开 oEmbed 获取（无需 key）；失败则用视频 ID 兜底。
# 已有索引的顺序/标题会被保留（新增的追加在末尾；已删除的剔除）。
Set-Location $PSScriptRoot

$subsDir  = Join-Path $PSScriptRoot "subtitles"
$indexPath = Join-Path $subsDir "index.json"

# 1) 扫描字幕文件 -> 视频ID列表（去重）
$ids = @(Get-ChildItem $subsDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in ".ass", ".srt" } |
    ForEach-Object { $_.BaseName } |
    Select-Object -Unique)

# 2) 读旧索引（保留顺序与标题）
$oldList = @()
if (Test-Path $indexPath) {
    try {
        $parsed = Get-Content $indexPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $oldList = @($parsed)
    } catch { $oldList = @() }
}
$titleMap = @{}
foreach ($e in $oldList) { if ($e -and $e.id) { $titleMap[$e.id] = $e.title } }

# 3) 顺序 = 旧索引里仍存在的顺序，后面追加新 id
$order = New-Object System.Collections.ArrayList
foreach ($e in $oldList) {
    if ($e -and $e.id -and $ids -contains $e.id) { [void]$order.Add($e.id) }
}
foreach ($id in $ids) { if ($order -notcontains $id) { [void]$order.Add($id) } }

# 4) 补标题（已有则用已有，否则 oEmbed，再兜底 ID）
$entries = @()
foreach ($id in $order) {
    $title = $id
    if ($titleMap.ContainsKey($id) -and $titleMap[$id]) { $title = $titleMap[$id] }
    else {
        try {
            $u = "https://www.youtube.com/oembed?url=" + [uri]::EscapeDataString("https://www.youtube.com/watch?v=$id") + "&format=json"
            $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15
            $j = $r.Content | ConvertFrom-Json
            if ($j.title) { $title = $j.title }
        } catch { $title = $id }
    }
    $entries += [pscustomobject]@{ id = $id; title = $title }
    Write-Output ("OK: {0} -> {1}" -f $id, $title)
}

# 5) 写回（UTF-8 无 BOM）—— 手工拼数组，避免不同 PowerShell 版本对单元素数组行为不同
$parts = @($entries) | ForEach-Object { ($_ | ConvertTo-Json -Depth 5 -Compress) }
$json = "[`n" + ($parts -join ",`n") + "`n]"
[System.IO.File]::WriteAllText($indexPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Output ("已写入 {0}（共 {1} 条，顺序即显示顺序，最新在前）" -f $indexPath, @($entries).Count)
