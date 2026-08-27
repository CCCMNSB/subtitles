# add-subtitle.ps1
# 一键把两个字幕文件推送进 subtitle 仓库：复制到 subtitles/ + 更新 index/index.json + git 推送。
# 用法（在仓库根目录运行）：
#   powershell -ExecutionPolicy Bypass -File add-subtitle.ps1                # 弹窗选文件 + 提示输入
#   powershell -ExecutionPolicy Bypass -File add-subtitle.ps1 -Ass a.ass -Srt a.srt -Id abc123
#   powershell -ExecutionPolicy Bypass -File add-subtitle.ps1 ... -NoPush    # 只更新本地，不推送
# title/date 不填则自动用 oEmbed 标题 + watch 页 uploadDate；也可手动传 -Title / -Date。
param(
    [string]$Ass,
    [string]$Srt,
    [string]$Id,
    [string]$Title,
    [string]$Date,
    [switch]$NoPush
)

Set-Location $PSScriptRoot
$subsDir  = Join-Path $PSScriptRoot "subtitles"
$indexDir = Join-Path $PSScriptRoot "index"
$indexPath = Join-Path $indexDir "index.json"
if (-not (Test-Path $subsDir)) { New-Item -ItemType Directory -Force -Path $subsDir | Out-Null }
if (-not (Test-Path $indexDir)) { New-Item -ItemType Directory -Force -Path $indexDir | Out-Null }

Add-Type -AssemblyName System.Windows.Forms

function Pick-File($title, $filter) {
    $d = New-Object System.Windows.Forms.OpenFileDialog
    $d.Title = $title
    $d.Filter = $filter
    if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $d.FileName }
    return ""
}

# 1) 收集文件
if (-not $Ass)  { $Ass  = Pick-File "选择 ASS 字幕文件" "ASS 字幕 (*.ass)|*.ass" }
if (-not $Srt)  { $Srt  = Pick-File "选择 SRT 字幕文件" "SRT 字幕 (*.srt)|*.srt" }
if (-not $Ass -or -not $Srt) { Write-Host "未选择两个字幕文件，退出。" ; exit 1 }
if (-not (Test-Path $Ass) -or -not (Test-Path $Srt)) { Write-Host "文件不存在。" ; exit 1 }

# 2) 收集 id / title / date
if (-not $Id)  { $Id = Read-Host "视频 ID（必填，如 P-xXhiCJieI）" }
if (-not $Id)  { Write-Host "缺少视频 ID，退出。" ; exit 1 }

# 3) 自动取 title / date
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
        if ($m.Success) { return $m.Groups[1].Value.Substring(0, 10) }
    } catch { }
    return ""
}
if (-not $Title) { $Title = Get-EmbedTitle $Id }
if (-not $Title) { $Title = $Id }
if (-not $Date)  { $Date  = Get-UploadDate $Id }

# 4) 复制字幕文件
$assDest = Join-Path $subsDir "$Id.ass"
$srtDest = Join-Path $subsDir "$Id.srt"
Copy-Item $Ass $assDest -Force
Copy-Item $Srt $srtDest -Force
Write-Host "已复制 -> $assDest"
Write-Host "        -> $srtDest"

# 5) 更新 index.json（新增放最前=最新在前；已存在则原位更新）
$list = @()
if (Test-Path $indexPath) {
    try { $raw = Get-Content $indexPath -Raw -Encoding UTF8 | ConvertFrom-Json; $list = @($raw) } catch { $list = @() }
}
if ($Date) {
    $entry = [pscustomobject]@{ id = $Id; title = $Title; date = $Date }
} else {
    $entry = [pscustomobject]@{ id = $Id; title = $Title }
}
$found = $false
$newList = New-Object System.Collections.ArrayList
foreach ($e in $list) {
    if ($e -and $e.id -eq $Id) { $found = $true; [void]$newList.Add($entry) } else { [void]$newList.Add($e) }
}
if (-not $found) {
    # 新增：插到最前（最新在前）
    $newList = New-Object System.Collections.ArrayList
    [void]$newList.Add($entry)
    foreach ($e in $list) { [void]$newList.Add($e) }
}
$parts = @()
foreach ($e in $newList) { $parts += ($e | ConvertTo-Json -Depth 5 -Compress) }
$json = "[`n" + ($parts -join ",`n") + "`n]"
[System.IO.File]::WriteAllText($indexPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "已更新 $indexPath（共 $($parts.Count) 条）"

# 6) git 提交 + 推送
if (-not $NoPush) {
    git add "$subsDir/$Id.ass" "$subsDir/$Id.srt" $indexPath 2>&1 | Out-Null
    git -c core.editor=true commit -m "feat: add subtitle $Id ($Title)" 2>&1 | Out-String | Write-Host
    git pull --rebase origin main 2>&1 | Out-Null
    git push origin main 2>&1 | Out-String | Write-Host
    Write-Host "已推送 GitHhub."
} else {
    Write-Host "(NoPush) 仅更新本地文件，未推送。"
}

Write-Host "完成：$Id  $Title  $Date"
