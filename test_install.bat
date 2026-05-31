@echo off
chcp 65001 >nul
title Тест install.bat — перевірка кроків

cls
echo.
echo  ╔══════════════════════════════════════════╗
echo  ║   ТЕСТ — перевіряємо кроки install.bat   ║
echo  ║   (нічого не встановлює, лише перевіряє) ║
echo  ╚══════════════════════════════════════════╝
echo.

:: ── 1. Admin rights ────────────────────────────
echo  [1] Права адміністратора...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo      ❌ Немає прав адміна — треба запускати від адміна
) else (
    echo      ✓ Є права адміна
)
echo.

:: ── 2. Python ──────────────────────────────────
echo  [2] Python...
python --version 2>&1
if %errorlevel% neq 0 (
    echo      ❌ Python не знайдено — install.bat встановить через winget
) else (
    echo      ✓ Python знайдено
)
echo.

:: ── 3. winget ──────────────────────────────────
echo  [3] winget (менеджер пакетів)...
winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo      ❌ winget не знайдено — Windows 10 старий або LTSB
    echo         install.bat відкриє сторінку python.org для ручного завантаження
) else (
    echo      ✓ winget знайдено
    winget --version
)
echo.

:: ── 4. Інтернет ────────────────────────────────
echo  [4] Інтернет (ping github.com)...
ping -n 1 github.com >nul 2>&1
if %errorlevel% neq 0 (
    echo      ❌ Немає доступу до github.com
) else (
    echo      ✓ Інтернет є
)
echo.

:: ── 5. Місце на диску C: ───────────────────────
echo  [5] Вільне місце на C:...
for /f "tokens=3" %%a in ('dir C:\ /-c ^| findstr /i "bytes free"') do (
    set FREE_BYTES=%%a
)
echo      %FREE_BYTES% байт вільно
echo      (потрібно ~1 GB для моделей PyTorch + MiDaS)
echo.

:: ── 6. PowerShell Invoke-WebRequest ────────────
echo  [6] PowerShell + Invoke-WebRequest...
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://github.com' -UseBasicParsing -TimeoutSec 10 -OutFile NUL" >nul 2>&1
if %errorlevel% neq 0 (
    echo      ❌ PowerShell не може завантажити файли
) else (
    echo      ✓ PowerShell Invoke-WebRequest працює
)
echo.

:: ── 7. Папки ───────────────────────────────────
echo  [7] Папка C:\CNC-Pipeline...
if exist "C:\CNC-Pipeline\" (
    echo      ℹ Вже існує — install.bat не перезапише файли
    dir "C:\CNC-Pipeline\" /b 2>nul
) else (
    echo      ✓ Не існує — install.bat створить
)
echo.

:: ── 8. Pipeline файли ──────────────────────────
echo  [8] Файли pipeline після встановлення...
for %%f in (
    "C:\CNC-Pipeline\pipeline\main.py"
    "C:\CNC-Pipeline\pipeline\requirements.txt"
    "C:\CNC-Pipeline\setup_wizard.py"
    "C:\CNC-Pipeline\start.bat"
    "C:\CNC-Pipeline\configure.bat"
) do (
    if exist %%f (
        echo      ✓ %%f
    ) else (
        echo      - %%f  ^(ще не встановлено^)
    )
)
echo.

echo  ══════════════════════════════════════════
echo  Тест завершено. Вище видно що є і чого немає.
echo  ══════════════════════════════════════════
echo.
pause
