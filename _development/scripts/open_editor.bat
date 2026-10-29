@echo off
title NOCTELYRA - Godot 4 Editor
set "PROJECT_ROOT=%~dp0..\.."
cd /d "%PROJECT_ROOT%"
echo ==============================================
echo   Mo Godot 4 Editor cho NOCTELYRA...
echo ==============================================
start "" "D:\program\Godot\Godot_v4.3-stable_win64.exe" -e --path "%PROJECT_ROOT%"
