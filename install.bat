@echo off
chcp 65001 >nul
title CNC Pipeline — Встановлення

:: ─────────────────────────────────────────
::  Admin check — перезапуск з правами адміна
:: ─────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Потрібні права адміністратора. Перезапуск...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  ════════════════════════════════════════
echo    CNC Pipeline  ^|  Stack 2
echo    MiDaS AI + Syncthing + Telegram
echo  ════════════════════════════════════════
echo.

:: ─────────────────────────────────────────
::  [1/5] Python
:: ─────────────────────────────────────────
echo [1/5] Перевірка Python...

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo       Не знайдено. Встановлення Python 3.11 через winget...
    winget install Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements
    if %errorlevel% neq 0 (
        echo.
        echo  ПОМИЛКА: winget недоступний або немає інтернету.
        echo  Завантаж Python вручну: https://www.python.org/downloads/
        echo  Потім запусти install.bat ще раз.
        pause
        exit /b 1
    )
    :: Refresh PATH for current session
    set "PATH=%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts;%PATH%"
    set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"
)

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  ПОМИЛКА: Python все ще не знайдено після встановлення.
    echo  Перезапусти ПК і спробуй знову.
    pause
    exit /b 1
)
echo       OK

:: ─────────────────────────────────────────
::  [2/5] Папки
:: ─────────────────────────────────────────
echo [2/5] Створення C:\CNC-Pipeline\...

for %%d in (
    "C:\CNC-Pipeline"
    "C:\CNC-Pipeline\incoming"
    "C:\CNC-Pipeline\output"
    "C:\CNC-Pipeline\rejected"
    "C:\CNC-Pipeline\processing"
    "C:\CNC-Pipeline\logs"
    "C:\CNC-Pipeline\pipeline"
) do mkdir %%d 2>nul

echo       OK

:: ─────────────────────────────────────────
::  [3/5] Завантаження з GitHub
:: ─────────────────────────────────────────
echo [3/5] Завантаження файлів пайплайна...

set "ZIP_URL=https://github.com/gonzotrixter/gonzotrixtrer-proton.me/archive/refs/heads/claude/work-in-progress-evkDk.zip"
set "ZIP_PATH=C:\CNC-Pipeline\src.zip"
set "SRC_DIR=C:\CNC-Pipeline\src"

powershell -NoProfile -Command ^
  "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_PATH%' -UseBasicParsing"

if not exist "%ZIP_PATH%" (
    echo  ПОМИЛКА: Файл не завантажився. Перевір інтернет.
    pause
    exit /b 1
)

powershell -NoProfile -Command ^
  "Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%SRC_DIR%' -Force"

:: Copy files from extracted folder (name depends on GitHub branch naming)
for /d %%i in ("%SRC_DIR%\*") do (
    if exist "%%i\pipeline" (
        xcopy "%%i\pipeline\*" "C:\CNC-Pipeline\pipeline\" /E /Y /Q >nul
    )
    if exist "%%i\setup_wizard.py"     copy "%%i\setup_wizard.py"     "C:\CNC-Pipeline\" /Y >nul
    if exist "%%i\config.yaml.template" copy "%%i\config.yaml.template" "C:\CNC-Pipeline\" /Y >nul
    if exist "%%i\start.bat"           copy "%%i\start.bat"           "C:\CNC-Pipeline\" /Y >nul
)

rmdir /s /q "%SRC_DIR%" 2>nul
del "%ZIP_PATH%" 2>nul

echo       OK

:: ─────────────────────────────────────────
::  [4/5] pip install
:: ─────────────────────────────────────────
echo [4/5] Встановлення пакетів...
echo.
echo   Важливо:
echo   - Загальний час: 5–15 хвилин
echo   - PyTorch CPU: ~200 MB одноразово
echo   - MiDaS модель: ~200 MB при першому запуску пайплайна
echo.

python -m pip install --upgrade pip -q

if exist "C:\CNC-Pipeline\pipeline\requirements.txt" (
    python -m pip install -r "C:\CNC-Pipeline\pipeline\requirements.txt" -q
) else (
    echo   ПОПЕРЕДЖЕННЯ: requirements.txt не знайдено.
)

echo   Встановлення PyTorch CPU...
python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu -q

echo       OK

:: ─────────────────────────────────────────
::  [5/5] Майстер налаштування
:: ─────────────────────────────────────────
echo [5/5] Запуск майстра налаштування Telegram...
echo.

cd /d C:\CNC-Pipeline
python setup_wizard.py

pause
