@echo off
title NOCTELYRA - Godot 4 Test Runner
set "PROJECT_ROOT=%~dp0..\.."
cd /d "%PROJECT_ROOT%"
echo ==============================================
echo   Khoi dong game NOCTELYRA (Godot 4.3)...
echo ==============================================
start "" "D:\program\Godot\Godot_v4.3-stable_win64.exe" --path "%PROJECT_ROOT%"
