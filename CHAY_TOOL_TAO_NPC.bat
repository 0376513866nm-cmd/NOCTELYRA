@echo off
setlocal
cd /d "%~dp0"
title NOCTELYRA - Tool Tao NPC Tu Video

echo =======================================================
echo    NOCTELYRA - TOOL TAO NPC TU DONG TU VIDEO
echo =======================================================
echo Dang khoi dong giao dien...

set "PYTHON_EXE="

where python.exe >nul 2>&1
if %errorlevel% equ 0 (
    set "PYTHON_EXE=python"
    goto :RUN
)

where py.exe >nul 2>&1
if %errorlevel% equ 0 (
    set "PYTHON_EXE=py"
    goto :RUN
)

if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set "PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    goto :RUN
)

:RUN
if "%PYTHON_EXE%"=="" (
    echo [LOI] Khong tim thay Python tren may tinh!
    pause
    exit /b 1
)

"%PYTHON_EXE%" "%~dp0_development\tools\video_to_npc.py"

if %errorlevel% neq 0 (
    echo.
    echo [LOI] Co van de khi chay tool.
    pause
)
