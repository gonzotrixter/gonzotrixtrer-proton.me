@echo off
chcp 65001 >nul
title Діагностика ПК

cls
echo.
echo  ════════════════════════════════════════
echo   ДІАГНОСТИКА — зачекайте...
echo  ════════════════════════════════════════
echo.

set OK=0
set FAIL=0

:: Python
echo  [1] Python...
python --version >nul 2>&1
if %errorlevel%==0 (
    echo      OK - Python є
    set /a OK+=1
) else (
    echo      НЕ ЗНАЙДЕНО - Python не встановлено
    set /a FAIL+=1
)

:: winget
echo  [2] winget...
winget --version >nul 2>&1
if %errorlevel%==0 (
    echo      OK - winget є
    set /a OK+=1
) else (
    echo      НЕ ЗНАЙДЕНО - winget відсутній
    set /a FAIL+=1
)

:: Internet
echo  [3] Інтернет...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel%==0 (
    echo      OK - інтернет є
    set /a OK+=1
) else (
    echo      НЕМАЄ - немає підключення до інтернету
    set /a FAIL+=1
)

:: GitHub
echo  [4] GitHub...
ping -n 1 github.com >nul 2>&1
if %errorlevel%==0 (
    echo      OK - GitHub доступний
    set /a OK+=1
) else (
    echo      НЕДОСТУПНИЙ - github.com не відповідає
    set /a FAIL+=1
)

:: Admin
echo  [5] Права адміністратора...
net session >nul 2>&1
if %errorlevel%==0 (
    echo      OK - є права адміна
    set /a OK+=1
) else (
    echo      НЕМАЄ - запустіть від імені адміністратора
    set /a FAIL+=1
)

:: CNC-Pipeline installed
echo  [6] CNC Pipeline встановлено?
if exist "C:\CNC-Pipeline\pipeline\main.py" (
    echo      OK - встановлено
    set /a OK+=1
) else (
    echo      НЕ ВСТАНОВЛЕНО - запустіть install.bat
    set /a FAIL+=1
)

:: Config
echo  [7] Налаштування Telegram?
if exist "C:\CNC-Pipeline\config.yaml" (
    echo      OK - config.yaml є
    set /a OK+=1
) else (
    echo      НЕ НАЛАШТОВАНО - запустіть configure.bat
    set /a FAIL+=1
)

:: Disk space
echo  [8] Місце на диску C:...
for /f "tokens=3" %%a in ('dir C:\ /-c 2^>nul ^| findstr /i "bytes free"') do set FREE=%%a
if defined FREE (
    echo      %FREE% байт вільно
    set /a OK+=1
) else (
    echo      Не вдалося визначити
)

echo.
echo  ════════════════════════════════════════
echo.
echo   РЕЗУЛЬТАТ:  OK=%OK%   ПРОБЛЕМ=%FAIL%
echo.

if %FAIL%==0 (
    echo   СТАТУС: ВСЕ ГОТОВО
) else (
    echo   СТАТУС: Є ПРОБЛЕМИ - подивіться вище що НЕ ЗНАЙДЕНО
)

echo.
echo  ════════════════════════════════════════
echo.
echo  Зробіть скріншот і надішліть Роману.
echo.
pause
