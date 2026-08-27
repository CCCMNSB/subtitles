# generate-index.ps1
# 扫描本仓库 subtitles/ 文件夹里的 <视频ID>.ass/.srt，生成 index/index.json。
# 格式: [ { "id": "...", "title": "...", "date": "YYYY-MM-DD" } ]，数组顺序即列表默认顺序；
#       有 date 时 App 会按 date 新→旧排序（最新在前）。
# title 通过 YouTube oEmbed 获取（无 key）；date 通过抓取 watch 页面的 uploadDate 获取（无 key，失败留空）。
# 已有索引里保留的 title/date 不会被覆盖。
Set-Location $PSScriptRoot

$subsDir  = Join-Path $PSScriptRoot "subtitles"
$indexDir = Join-Path $PSScriptRoot "index"
$indexPath = Join-Path $indexDir "index.json"
if (-not (Test-Path $indexDir)) { New-Item -ItemType Directory -Force -Path $indexDir | Out-Null }

# 1) 扫描字幕文件 -> 视频ID列表（去重）
$ids = @(Get-ChildItem $subsDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in ".ass", ".srt" } |
    ForEach-Object { $_.BaseName } |
    Select-Object -Unique)

# 2) 读旧索引（保留 title 与 date）
$oldList = @()
if (Test-Path $indexPath) {
    try { $oldRaw = Get-Content $indexPath -Raw -Encoding UTF8 | ConvertFrom-Json; $oldList = @($oldRaw) } catch { $oldList = @() }
}
$titleMap = @{}
$dateMap  = @{}
foreach ($e in $oldList) {
    if ($e -and $e.id) {
        if ($e.title) { $titleMap[$e.id] = $e.title }
        if ($e.date)  { $dateMap[$e.id] = $e.date }
    }
}

# 3) 顺序 = 旧索引仍存在的，再追加新 id
$order = New-Object System.Collections.ArrayList
foreach ($e in $oldList) { if ($e -and $e.id -and $ids -contains $e.id) { [void]$order.Add($e.id) } }
foreach ($id in $ids) { if ($order -notcontains $id) { [void]$order.Add($id) } }

# 4) 补 title / date（已有则保留；否则 oEmbed / 抓页面）
function Get-EmbedTitle($id) {
    try {
        $u = "https://www.youtube.com/oembed?url=" + [uri]::EscapeDataString("https://www.youtube.com/watch?v=$id") + "&format=json"
        $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15
        $j = $r.Content | ConvertFrom-Json
        if ($j.title) { return $j.title }
    } catch { }
    return ""
}
function Get-UploadDate($id) {
    try {
        $u = "https://www.youtube.com/watch?v=$id"
        $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 20 -Headers @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
        $m = [regex]::Match($r.Content, '"uploadDate":"([^"]+)"')
        if ($m.Success) { return $m.Groups[1].Value.Substring(0, 10) }  # YYYY-MM-DD
    } catch { }
    return ""
}

$parts = @()
foreach ($id in $order) {
    $title = if ($titleMap[$id]) { $titleMap[$id] } else { Get-EmbedTitle $id }
    if (-not $title) { $title = $id }
    $date = if ($dateMap[$id]) { $dateMap[$id] } else { Get-UploadDate $id }
    if ($date) {
        $obj = [pscustomobject]@{ id = $id; title = $title; date = $date }
    } else {
        $obj = [pscustomobject]@{ id = $id; title = $title }
    }
    $parts += ($obj | ConvertTo-Json -Depth 5 -Compress)
    Write-Output ("OK: {0}  title={1}  date={2}" -f $id, $title, $date)
}

# 5) 写回（UTF-8 无 BOM）—— 手动拼数组，避免单元素/数组序列化差异
$json = "[`n" + ($parts -join ",`n") + "`n]"
[System.IO.File]::WriteAllText($indexPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Output ("已写入 {0}（共 {1} 条）" -f $indexPath, $parts.Count)
