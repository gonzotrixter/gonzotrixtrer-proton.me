@echo off
chcp 65001 >nul
title CNC Pipeline
cd /d C:\CNC-Pipeline\pipeline
python main.py
pause
