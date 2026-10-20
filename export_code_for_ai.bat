@echo off
setlocal enabledelayedexpansion
title Export Code for AI Review
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$outFile = 'CODE_EXPORT.txt'; if (Test-Path $outFile) { Remove-Item $outFile -Force }; $header = '===================================================' + [Environment]::NewLine + '  PROJECT: NOCTELYRA (Godot 4.3 - Milestone M8 FINAL)' + [Environment]::NewLine + '  EXPORTED AT: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + [Environment]::NewLine + '===================================================' + [Environment]::NewLine; Set-Content -Path $outFile -Value $header -Encoding UTF8; $files = @('project.godot', 'README.md', 'test_m2_1_flow.gd', 'test_m3_flow.gd', 'test_m3_1_flow.gd', 'test_m3_2_flow.gd', 'test_m4_flow.gd', 'test_m5_flow.gd', 'test_m6_flow.gd', 'test_m7_flow.gd', 'test_m8_flow.gd'); $srcFiles = Get-ChildItem -Path 'src' -Recurse -Include *.gd,*.tscn | ForEach-Object { $_.FullName.Replace((Get-Location).Path + '\', '') }; foreach ($item in ($files + $srcFiles)) { if (Test-Path $item) { $sep = [Environment]::NewLine + '===================================================' + [Environment]::NewLine + 'FILE: ' + $item + [Environment]::NewLine + '===================================================' + [Environment]::NewLine; Add-Content -Path $outFile -Value $sep -Encoding UTF8; Get-Content -Path $item -Raw -Encoding UTF8 | Add-Content -Path $outFile -Encoding UTF8 } }; Write-Host 'Da xuat toan bo ma nguon ra file: CODE_EXPORT.txt'"

echo.
pause
