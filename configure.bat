@echo off
chcp 65001 >nul
title CNC Pipeline — Налаштування Telegram

echo.
echo  ════════════════════════════════════════
echo    CNC Pipeline — Налаштування
echo    Запускай цей файл коли приїдеш
echo  ════════════════════════════════════════
echo.

cd /d C:\CNC-Pipeline
python setup_wizard.py

pause
