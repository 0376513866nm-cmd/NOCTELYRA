# repack_sprites.ps1
# Script to regenerate player_idle_atlas.png and player_run_atlas.png from source sprite strips.
# Requirements: Windows PowerShell with System.Drawing (.NET Framework built-in)

Add-Type -AssemblyName System.Drawing

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$TargetDir = Join-Path $ProjectDir "assets\sprites\player"

function Repack-Strip {
    param(
        [string]$StripPath,
        [string]$OutputPath,
        [int]$FrameCount,
        [int]$Cols,
        [int]$Rows,
        [int]$TargetFrameWidth,
        [int]$TargetFrameHeight
    )

    Write-Host "Packing $StripPath -> $OutputPath..."
    $stripImg = [System.Drawing.Image]::FromFile($StripPath)
    $srcFrameWidth = [int]($stripImg.Width / $FrameCount)
    $srcFrameHeight = $stripImg.Height

    $atlasWidth = $Cols * $TargetFrameWidth
    $atlasHeight = $Rows * $TargetFrameHeight

    $atlasBmp = New-Object System.Drawing.Bitmap($atlasWidth, $atlasHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($atlasBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    for ($i = 0; $i -lt $FrameCount; $i++) {
        $col = $i % $Cols
        $row = [math]::Floor($i / $Cols)

        $srcRect = New-Object System.Drawing.Rectangle(($i * $srcFrameWidth), 0, $srcFrameWidth, $srcFrameHeight)
        $destRect = New-Object System.Drawing.Rectangle(($col * $TargetFrameWidth), ($row * $TargetFrameHeight), $TargetFrameWidth, $TargetFrameHeight)

        $g.DrawImage($stripImg, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    }

    $g.Dispose()
    $stripImg.Dispose()

    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Force
    }
    $atlasBmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $atlasBmp.Dispose()
    Write-Host "Successfully generated $OutputPath ($($atlasWidth)x$($atlasHeight))"
}

# 1. Idle Atlas: 48 frames, 8 cols x 6 rows, 256x340 per frame -> 2048x2040
$idleStrip = Join-Path $ScriptDir "player_idle_strip.png"
$idleOut = Join-Path $TargetDir "player_idle_atlas.png"
if (Test-Path $idleStrip) {
    Repack-Strip -StripPath $idleStrip -OutputPath $idleOut -FrameCount 48 -Cols 8 -Rows 6 -TargetFrameWidth 256 -TargetFrameHeight 340
}

# 2. Run Atlas: 14 frames, 4 cols x 4 rows, 256x340 per frame -> 1024x1360
$runStrip = Join-Path $ScriptDir "player_run_strip.png"
$runOut = Join-Path $TargetDir "player_run_atlas.png"
if (Test-Path $runStrip) {
    Repack-Strip -StripPath $runStrip -OutputPath $runOut -FrameCount 14 -Cols 4 -Rows 4 -TargetFrameWidth 256 -TargetFrameHeight 340
}

Write-Host "Repack complete!"
