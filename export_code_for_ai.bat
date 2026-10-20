@echo off
setlocal enabledelayedexpansion
title Export Code for AI Review
cd /d "%~dp0"

powershell -ExecutionPolicy Bypass -Command "$outFile = 'CODE_EXPORT.txt'; if (Test-Path $outFile) { Remove-Item $outFile -Force }; Set-Content -Path $outFile -Value ('===================================================' + [Environment]::NewLine + '  PROJECT: NOCTELYRA (Godot 4.3 - Milestone M3.1 FINAL)' + [Environment]::NewLine + '  EXPORTED AT: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + [Environment]::NewLine + '===================================================' + [Environment]::NewLine) -Encoding UTF8; $files = @('project.godot', 'README.md', 'test_m2_1_flow.gd', 'test_m3_flow.gd', 'test_m3_1_flow.gd'); $srcFiles = Get-ChildItem -Path 'src' -Recurse -Include *.gd,*.tscn | ForEach-Object { $_.FullName.Replace((Get-Location).Path + '\', '') }; foreach ($f in ($files + $srcFiles)) { if (Test-Path $f) { Add-Content -Path $outFile -Value ([Environment]::NewLine + '===================================================' + [Environment]::NewLine + 'FILE: ' + $f + [Environment]::NewLine + '===================================================' + [Environment]::NewLine) -Encoding UTF8; Get-Content -Path $f -Raw -Encoding UTF8 | Add-Content -Path $outFile -Encoding UTF8 } }; Write-Host 'Da xuat toan bo ma nguon ra file: CODE_EXPORT.txt'"

echo.
pause
