@echo off
chcp 65001 > nul
title Tool Tach Nen Hang Loat (Batch Background Remover)

echo ========================================================
echo   KHOI DONG CONG CU TACH NEN ANH HANG LOAT (AI REMBG)
echo ========================================================
echo.

python "%~dp0..\tools\batch_remove_bg.py"

pause
