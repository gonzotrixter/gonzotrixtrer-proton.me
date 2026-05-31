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
::  [1/6] Python
:: ─────────────────────────────────────────
echo  ── Крок 1 з 6: Перевірка Python ────────────

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo      Встановлення Python 3.11...
    winget install Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements >nul 2>&1

    :: Refresh PATH for known install locations
    for %%v in (Python313 Python312 Python311 Python310) do (
        if exist "%LOCALAPPDATA%\Programs\Python\%%v\python.exe" (
            set "PATH=%LOCALAPPDATA%\Programs\Python\%%v;%LOCALAPPDATA%\Programs\Python\%%v\Scripts;%PATH%"
        )
    )

    :: Wait for winget to finish and retry up to 5 times
    for /l %%i in (1,1,5) do (
        python --version >nul 2>&1
        if not errorlevel 1 goto :python_ok
        echo      Очікування... (спроба %%i з 5)
        timeout /t 4 /nobreak >nul
    )

    :: winget failed — fallback: open Python download page
    echo.
    echo  winget не спрацював. Відкриваємо сторінку завантаження Python...
    start "" "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
    echo.
    echo  ╔══════════════════════════════════════════╗
    echo  ║  Встановіть Python з файлу що завантажився║
    echo  ║  (обов'язково: "Add Python to PATH" ✓)   ║
    echo  ║  Потім запустіть install.bat ще раз.      ║
    echo  ╚══════════════════════════════════════════╝
    echo.
    pause
    exit /b 1
)

:python_ok
echo      ✓ Python готовий
echo.

:: ─────────────────────────────────────────
::  [2/6] Папки
:: ─────────────────────────────────────────
echo  ── Крок 2 з 6: Створення папок ─────────────
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
::  [3/6] Завантаження файлів з GitHub
:: ─────────────────────────────────────────
echo  ── Крок 3 з 6: Завантаження пайплайна ──────

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

:: Verify critical files
if not exist "C:\CNC-Pipeline\pipeline\main.py" (
    echo  ПОМИЛКА: Файли пайплайна не знайдено після розпаковки.
    echo  Зателефонуйте Роману.
    pause
    exit /b 1
)

echo      ✓ Файли завантажено
echo.

:: ─────────────────────────────────────────
::  [4/6] pip install
:: ─────────────────────────────────────────
echo  ── Крок 4 з 6: Встановлення програм ────────
echo      (може зайняти 10–20 хвилин, зачекайте)
echo.

python -m pip install --upgrade pip -q --no-warn-script-location

if exist "C:\CNC-Pipeline\pipeline\requirements.txt" (
    python -m pip install -r "C:\CNC-Pipeline\pipeline\requirements.txt" -q --no-warn-script-location
)

echo      Встановлення PyTorch (CPU ~200 MB)...
python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu -q --no-warn-script-location

echo      ✓ Програми встановлено
echo.

:: ─────────────────────────────────────────
::  [5/6] Syncthing
:: ─────────────────────────────────────────
echo  ── Крок 5 з 6: Встановлення Syncthing ──────
winget install SyncThing.SyncThing --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
if %errorlevel% equ 0 (
    echo      ✓ Syncthing встановлено
) else (
    echo      ⚠ Syncthing не встановився через winget
    echo        Роман встановить вручну при приїзді
)
echo.

:: ─────────────────────────────────────────
::  [6/6] Завантаження AI-моделі MiDaS
:: ─────────────────────────────────────────
echo  ── Крок 6 з 6: Завантаження AI-моделі ──────
echo      (~200 MB, один раз, може зайняти 5+ хвилин)
echo.

powershell -NoProfile -Command ^
  "$proc = Start-Process python -ArgumentList 'C:\CNC-Pipeline\preload_models.py' -NoNewWindow -PassThru; ^
   if (-not $proc.WaitForExit(600000)) { $proc.Kill(); Write-Host 'Timeout — модель завантажиться при першому запуску' }"

echo.
echo      ✓ Готово
echo.

:: ─────────────────────────────────────────
::  Ярлик "CNC Налаштування" на Desktop
:: ─────────────────────────────────────────
powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; ^
   $sc = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\CNC Налаштування.lnk'); ^
   $sc.TargetPath = 'C:\CNC-Pipeline\configure.bat'; ^
   $sc.WorkingDirectory = 'C:\CNC-Pipeline'; ^
   $sc.Description = 'CNC Pipeline — Налаштування Telegram'; ^
   $sc.Save()" >nul 2>&1

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
