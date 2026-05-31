@echo off
chcp 65001 >nul
title CNC Pipeline

cls
echo.
echo =========================================
echo  CNC Pipeline - started
echo  Waiting for photos in incoming folder...
echo  Ctrl+C to stop
echo =========================================
echo.

cd /d C:\CNC-Pipeline\pipeline

if not exist "main.py" (
    echo  ERROR: main.py not found
    echo  Run install.bat first
    pause
    exit /b 1
)

if not exist "..\config.yaml" (
    echo  ERROR: config.yaml not found
    echo  Run configure.bat to set up Telegram
    pause
    exit /b 1
)

python main.py

echo.
echo  Pipeline stopped.
pause
