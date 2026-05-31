@echo off
chcp 65001 >nul
title CNC Pipeline

cls
echo.
echo  ╔══════════════════════════════════════════╗
echo  ║   CNC Pipeline — запущено                 ║
echo  ║   Очікую фото у папці incoming...         ║
echo  ║   Ctrl+C для зупинки                      ║
echo  ╚══════════════════════════════════════════╝
echo.

cd /d C:\CNC-Pipeline\pipeline

:: Run pipeline — output goes to console AND log file
python main.py 2>&1 | powershell -NoProfile -Command ^
  "$input | Tee-Object -FilePath 'C:\CNC-Pipeline\logs\pipeline.log' -Append"

echo.
echo  Pipeline зупинено.
pause
