<#
.SYNOPSIS
    image-gen for Windows (PowerShell 7+)

.DESCRIPTION
    Generates and edits images via the AiPai relay (gpt-image-2).
    PowerShell mirror of scripts/generate.sh.

.PARAMETER Prompt
    The text prompt (required).

.PARAMETER References
    Optional reference image paths. When provided, runs edit mode.

.EXAMPLE
    ./generate.ps1 "cyberpunk cat, neon lights"

.EXAMPLE
    $env:IMG_SIZE = "2k"
    ./generate.ps1 "make it oil painting" C:\Pictures\cat.png

.NOTES
    Requires PowerShell 7+ for multipart/form-data support (`Invoke-RestMethod -Form`).

    Env vars (or ~/.aidle/config.env):
      IMG_SIZE      1k (default) / 2k / 4k / explicit WxH like 1024x1536
      IMG_MODEL     gpt-image-2 (default)
      IMG_QUALITY   low | medium | high | auto
      IMG_N         number of variants (default 1)
      IMG_MASK      path to mask PNG (edit mode only)
      IMG_OUT       custom output path (when IMG_N=1)
      AIPAI_API_KEY
      AIPAI_BASE_URL
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Prompt,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$References = @()
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "❌ PowerShell 7+ is required (multipart/form-data support)." -ForegroundColor Red
    Write-Host "   Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    Write-Host "   Install via: winget install Microsoft.PowerShell" -ForegroundColor Yellow
    exit 1
}

# ─── Load ~/.aidle/config.env (does NOT override existing env vars) ───
$ConfigFile = Join-Path $HOME ".aidle/config.env"
if (Test-Path $ConfigFile) {
    Get-Content $ConfigFile | ForEach-Object {
        $line = ($_ -replace '#.*$', '').Trim()
        if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
            $k = $matches[1]
            $v = $matches[2].Trim().Trim('"').Trim("'")
            if (-not [Environment]::GetEnvironmentVariable($k)) {
                Set-Item -Path "env:$k" -Value $v
            }
        }
    }
}

# ─── Parameters & size shortcuts ───
$Size = if ($env:IMG_SIZE) { $env:IMG_SIZE } else { "1k" }
switch -CaseSensitive ($Size) {
    "1k" { $Size = "1024x1024" }
    "1K" { $Size = "1024x1024" }
    "2k" { $Size = "2048x2048" }
    "2K" { $Size = "2048x2048" }
    "4k" { $Size = "4096x4096" }
    "4K" { $Size = "4096x4096" }
}

$Model     = if ($env:IMG_MODEL)      { $env:IMG_MODEL }      else { "gpt-image-2" }
$Quality   = $env:IMG_QUALITY
$N         = if ($env:IMG_N)          { [int]$env:IMG_N }     else { 1 }
$BaseUrl   = if ($env:AIPAI_BASE_URL) { $env:AIPAI_BASE_URL } else { "https://aipai.vip/v1" }
$AuthFile  = Join-Path $HOME ".codex/auth.json"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DefaultOut = Join-Path $HOME "Downloads\img_$Timestamp.png"

# ─── Resolve API key: env > config.env > codex auth.json ───
$Key = $env:AIPAI_API_KEY
if (-not $Key -and (Test-Path $AuthFile)) {
    try {
        $auth = Get-Content $AuthFile -Raw | ConvertFrom-Json
        foreach ($k in @('OPENAI_API_KEY', 'api_key', 'apiKey', 'key')) {
            if ($auth.PSObject.Properties.Name -contains $k -and $auth.$k) {
                $Key = $auth.$k
                break
            }
        }
        if (-not $Key) {
            foreach ($nested in @('tokens', 'openai', 'auth')) {
                if ($auth.PSObject.Properties.Name -contains $nested -and $auth.$nested) {
                    foreach ($k in @('OPENAI_API_KEY', 'api_key', 'apiKey', 'key', 'access_token')) {
                        if ($auth.$nested.PSObject.Properties.Name -contains $k -and $auth.$nested.$k) {
                            $Key = $auth.$nested.$k
                            break
                        }
                    }
                    if ($Key) { break }
                }
            }
        }
    } catch {
        Write-Warning "auth.json parse error: $_"
    }
}

if (-not $Key) {
    Write-Host "❌ No API key found. Configure one of:" -ForegroundColor Red
    Write-Host "   1) `$env:AIPAI_API_KEY = 'sk-...'" -ForegroundColor Yellow
    Write-Host "   2) Add AIPAI_API_KEY=sk-... to ~/.aidle/config.env" -ForegroundColor Yellow
    Write-Host "   3) Ensure ~/.codex/auth.json contains OPENAI_API_KEY" -ForegroundColor Yellow
    exit 1
}

$Headers = @{ "Authorization" = "Bearer $Key" }
$Resp = $null

# ─── Text-to-image OR Image edit ───
if ($References.Count -eq 0) {
    Write-Host "🎨 Generating ($Model, $Size, n=$N) ..."
    $Body = [ordered]@{
        model  = $Model
        prompt = $Prompt
        n      = $N
        size   = $Size
    }
    if ($Quality) { $Body.quality = $Quality }
    $Resp = Invoke-RestMethod -Method Post `
        -Uri "$BaseUrl/images/generations" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($Body | ConvertTo-Json -Depth 4)
} else {
    Write-Host "🎨 Editing with $($References.Count) reference(s) ($Model, $Size, n=$N) ..."
    foreach ($ref in $References) {
        if (-not (Test-Path $ref)) {
            Write-Host "❌ Reference file not found: $ref" -ForegroundColor Red
            exit 1
        }
    }

    $Form = [ordered]@{
        model  = $Model
        prompt = $Prompt
        size   = $Size
        n      = $N.ToString()
    }
    if ($Quality) { $Form.quality = $Quality }

    if ($References.Count -eq 1) {
        $Form.image = Get-Item -LiteralPath $References[0]
    } else {
        $Form."image[]" = $References | ForEach-Object { Get-Item -LiteralPath $_ }
    }

    if ($env:IMG_MASK) {
        if (-not (Test-Path $env:IMG_MASK)) {
            Write-Host "❌ Mask file not found: $env:IMG_MASK" -ForegroundColor Red
            exit 1
        }
        $Form.mask = Get-Item -LiteralPath $env:IMG_MASK
    }

    $Resp = Invoke-RestMethod -Method Post `
        -Uri "$BaseUrl/images/edits" `
        -Headers $Headers `
        -Form $Form
}

# ─── Parse response & save ───
if (-not $Resp.data -or $Resp.data.Count -eq 0) {
    Write-Host "❌ Unexpected response:" -ForegroundColor Red
    $Resp | ConvertTo-Json -Depth 6
    exit 1
}

$CustomOut = $env:IMG_OUT
$Saved = @()
for ($i = 0; $i -lt $Resp.data.Count; $i++) {
    $item = $Resp.data[$i]

    if ($Resp.data.Count -eq 1) {
        $out = if ($CustomOut) { $CustomOut } else { $DefaultOut }
    } else {
        $base = if ($CustomOut) { $CustomOut } else { $DefaultOut }
        $dir = Split-Path -Parent $base
        $name = [System.IO.Path]::GetFileNameWithoutExtension($base)
        $ext = [System.IO.Path]::GetExtension($base)
        if (-not $ext) { $ext = ".png" }
        $out = Join-Path $dir "${name}_$($i + 1)$ext"
    }

    $outDir = Split-Path -Parent $out
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    if ($item.b64_json) {
        [System.IO.File]::WriteAllBytes($out, [Convert]::FromBase64String($item.b64_json))
    } elseif ($item.url) {
        Invoke-WebRequest -Uri $item.url -OutFile $out
    } else {
        Write-Warning "❌ No image data in item $i"
        continue
    }

    $Saved += $out
    Write-Host "✅ Saved: $out" -ForegroundColor Green
    if ($item.revised_prompt) {
        Write-Host "📝 Revised prompt: $($item.revised_prompt)"
    }
}

# Open the first image with the system default viewer
if ($Saved.Count -gt 0) {
    try { Invoke-Item -LiteralPath $Saved[0] } catch { Write-Warning "Could not open image: $_" }
}
