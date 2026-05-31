@echo off
chcp 65001 >nul

echo.
echo =========================================
echo  DIAGNOSTICS - checking system...
echo =========================================
echo.

set OK=0
set FAIL=0

echo [1] Python...
python --version 2>&1
if %errorlevel%==0 (
    echo     RESULT: OK - Python found
    set /a OK+=1
) else (
    echo     RESULT: NOT FOUND - Python not installed
    set /a FAIL+=1
)
echo.

echo [2] winget...
winget --version >nul 2>&1
if %errorlevel%==0 (
    echo     RESULT: OK - winget found
    set /a OK+=1
) else (
    echo     RESULT: NOT FOUND - winget missing
    set /a FAIL+=1
)
echo.

echo [3] Internet (ping 8.8.8.8)...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel%==0 (
    echo     RESULT: OK - internet works
    set /a OK+=1
) else (
    echo     RESULT: FAIL - no internet
    set /a FAIL+=1
)
echo.

echo [4] GitHub access...
ping -n 1 github.com >nul 2>&1
if %errorlevel%==0 (
    echo     RESULT: OK - github.com reachable
    set /a OK+=1
) else (
    echo     RESULT: FAIL - github.com unreachable
    set /a FAIL+=1
)
echo.

echo [5] Admin rights...
net session >nul 2>&1
if %errorlevel%==0 (
    echo     RESULT: OK - have admin rights
    set /a OK+=1
) else (
    echo     RESULT: NO ADMIN - run as administrator
    set /a FAIL+=1
)
echo.

echo [6] CNC Pipeline installed?
if exist "C:\CNC-Pipeline\pipeline\main.py" (
    echo     RESULT: OK - installed
    set /a OK+=1
) else (
    echo     RESULT: NOT INSTALLED - run install.bat first
    set /a FAIL+=1
)
echo.

echo [7] Telegram config?
if exist "C:\CNC-Pipeline\config.yaml" (
    echo     RESULT: OK - config.yaml found
    set /a OK+=1
) else (
    echo     RESULT: NOT CONFIGURED - run configure.bat
    set /a FAIL+=1
)
echo.

echo [8] Windows version:
ver
echo.

echo =========================================
echo  TOTAL: OK=%OK%   PROBLEMS=%FAIL%
echo.
if %FAIL%==0 (
    echo  STATUS: ALL GOOD - ready to use
) else (
    echo  STATUS: PROBLEMS FOUND - see above
)
echo =========================================
echo.
echo  Take a screenshot and send to Roman.
echo.
pause
