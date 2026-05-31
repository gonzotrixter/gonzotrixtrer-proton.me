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

if not exist "main.py" (
    echo  ПОМИЛКА: main.py не знайдено
    echo  Запустіть спочатку install.bat
    pause
    exit /b 1
)

if not exist "..\config.yaml" (
    echo  ПОМИЛКА: config.yaml не знайдено
    echo  Запустіть configure.bat для налаштування
    pause
    exit /b 1
)

python main.py

echo.
echo  Pipeline зупинено.
pause
