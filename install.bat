@echo off
chcp 65001 >nul
title CNC Pipeline — Встановлення (не закривати!)

:: ─────────────────────────────────────────
::  Перезапуск з правами адміна якщо потрібно
:: ─────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo  ╔══════════════════════════════════════════╗
echo  ║   CNC Pipeline — Автоматичне              ║
echo  ║   встановлення                            ║
echo  ║                                           ║
echo  ║   Не закривайте це вікно!                 ║
echo  ║   Процес займе 15–30 хвилин.              ║
echo  ╚══════════════════════════════════════════╝
echo.
echo  Розпочато: %date% %time%
echo.

:: ─────────────────────────────────────────
::  [1/5] Python
:: ─────────────────────────────────────────
echo  ── Крок 1 з 5: Перевірка Python ────────────
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo      Встановлення Python 3.11...
    winget install Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
    set "PATH=%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts;%PATH%"
    set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"
)
python --version >nul 2>&1
if %errorlevel% neq 0 (
    cls
    echo.
    echo  ╔══════════════════════════════════════════╗
    echo  ║   ❌ ПОМИЛКА                              ║
    echo  ║                                           ║
    echo  ║   Python не вдалося встановити.           ║
    echo  ║   Зателефонуйте Роману.                   ║
    echo  ╚══════════════════════════════════════════╝
    echo.
    pause
    exit /b 1
)
echo      ✓ Python готовий
echo.

:: ─────────────────────────────────────────
::  [2/5] Папки
:: ─────────────────────────────────────────
echo  ── Крок 2 з 5: Створення папок ─────────────
for %%d in (
    "C:\CNC-Pipeline"
    "C:\CNC-Pipeline\incoming"
    "C:\CNC-Pipeline\output"
    "C:\CNC-Pipeline\rejected"
    "C:\CNC-Pipeline\processing"
    "C:\CNC-Pipeline\logs"
    "C:\CNC-Pipeline\pipeline"
) do mkdir %%d 2>nul
echo      ✓ Папки створено
echo.

:: ─────────────────────────────────────────
::  [3/5] Завантаження файлів з GitHub
:: ─────────────────────────────────────────
echo  ── Крок 3 з 5: Завантаження пайплайна ──────

set "ZIP_URL=https://github.com/gonzotrixter/gonzotrixtrer-proton.me/archive/refs/heads/claude/work-in-progress-evkDk.zip"

powershell -NoProfile -Command ^
  "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile 'C:\CNC-Pipeline\src.zip' -UseBasicParsing" >nul 2>&1

if not exist "C:\CNC-Pipeline\src.zip" (
    cls
    echo.
    echo  ╔══════════════════════════════════════════╗
    echo  ║   ❌ ПОМИЛКА                              ║
    echo  ║                                           ║
    echo  ║   Немає інтернету або сервер недоступний. ║
    echo  ║   Перевірте підключення і спробуйте       ║
    echo  ║   запустити install.bat ще раз.           ║
    echo  ║                                           ║
    echo  ║   Зателефонуйте Роману.                   ║
    echo  ╚══════════════════════════════════════════╝
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -Command ^
  "Expand-Archive -Path 'C:\CNC-Pipeline\src.zip' -DestinationPath 'C:\CNC-Pipeline\src' -Force" >nul 2>&1

for /d %%i in ("C:\CNC-Pipeline\src\*") do (
    if exist "%%i\pipeline" (
        xcopy "%%i\pipeline\*" "C:\CNC-Pipeline\pipeline\" /E /Y /Q >nul 2>&1
    )
    for %%f in (setup_wizard.py preload_models.py config.yaml.template configure.bat start.bat) do (
        if exist "%%i\%%f" copy "%%i\%%f" "C:\CNC-Pipeline\" /Y >nul 2>&1
    )
)

rmdir /s /q "C:\CNC-Pipeline\src" 2>nul
del "C:\CNC-Pipeline\src.zip" 2>nul

echo      ✓ Файли завантажено
echo.

:: ─────────────────────────────────────────
::  [4/5] pip install
:: ─────────────────────────────────────────
echo  ── Крок 4 з 5: Встановлення програм ────────
echo      (може зайняти 10–20 хвилин, зачекайте)
echo.

python -m pip install --upgrade pip -q --no-warn-script-location

if exist "C:\CNC-Pipeline\pipeline\requirements.txt" (
    python -m pip install -r "C:\CNC-Pipeline\pipeline\requirements.txt" -q --no-warn-script-location
)

echo      Встановлення PyTorch...
python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu -q --no-warn-script-location

echo      ✓ Програми встановлено
echo.

:: ─────────────────────────────────────────
::  [5/5] Завантаження AI-моделі MiDaS
:: ─────────────────────────────────────────
echo  ── Крок 5 з 5: Завантаження AI-моделі ──────
echo      (~200 MB, один раз)
echo.

python "C:\CNC-Pipeline\preload_models.py"

echo.
echo      ✓ Готово
echo.

:: ─────────────────────────────────────────
::  DONE
:: ─────────────────────────────────────────
cls
echo.
echo  ╔══════════════════════════════════════════╗
echo  ║                                           ║
echo  ║   ✅  КОМП'ЮТЕР ГОТОВИЙ!                 ║
echo  ║                                           ║
echo  ║   Більше нічого робити не потрібно.       ║
echo  ║                                           ║
echo  ║   Зателефонуйте Роману —                  ║
echo  ║   він налаштує решту коли приїде.         ║
echo  ║                                           ║
echo  ╚══════════════════════════════════════════╝
echo.
echo  Завершено: %date% %time%
echo.
pause
