@echo off
setlocal enabledelayedexpansion
title Export Code for ChatGPT
cd /d "%~dp0"

set "OUTFILE=%~dp0CODE_EXPORT.txt"
if exist "%OUTFILE%" del "%OUTFILE%"

echo =================================================== >> "%OUTFILE%"
echo   PROJECT: NOCTELYRA (Godot 4 - Milestone M0)       >> "%OUTFILE%"
echo   EXPORTED AT: %DATE% %TIME%                        >> "%OUTFILE%"
echo =================================================== >> "%OUTFILE%"
echo. >> "%OUTFILE%"

for %%F in (
    "project.godot"
    "src\actors\player\player_movement_data.gd"
    "src\actors\player\player.gd"
    "src\actors\player\player.tscn"
    "src\world\test_level.gd"
    "src\world\test_level.tscn"
    "README.md"
) do (
    if exist "%~dp0%%F" (
        echo =================================================== >> "%OUTFILE%"
        echo FILE: %%F >> "%OUTFILE%"
        echo =================================================== >> "%OUTFILE%"
        type "%~dp0%%F" >> "%OUTFILE%"
        echo. >> "%OUTFILE%"
        echo. >> "%OUTFILE%"
    )
)

echo Da xuat toan bo ma nguon ra file: %OUTFILE%
echo Ban chi can mo file CODE_EXPORT.txt, copy toan bo va gui cho ChatGPT!
pause
