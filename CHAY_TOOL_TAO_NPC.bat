@echo off
chcp 65001 >nul
title NOCTELYRA - Tool Tạo NPC Tự Động Từ Video
echo =======================================================
echo    NOCTELYRA - CÔNG CỤ TỰ ĐỘNG TẠO NPC TỪ VIDEO
echo =======================================================
echo Đang khởi động giao diện...
python "%~dp0_development\tools\video_to_npc.py"
if %errorlevel% neq 0 (
    echo.
    echo [Lỗi] Không thể khởi chạy script Python.
    echo Vui lòng kiểm tra lại môi trường Python trên máy.
    pause
)
