@echo off
chcp 65001 >nul
title Test install.bat

cls
echo.
echo =========================================
echo  TEST - checking install.bat steps
echo  (nothing installs, read-only check)
echo =========================================
echo.

echo [1] Admin rights...
net session >nul 2>&1
if %errorlevel%==0 (
    echo     OK - have admin rights
) else (
    echo     FAIL - no admin rights, run as administrator
)
echo.

echo [2] Python...
python --version 2>&1
if %errorlevel%==0 (
    echo     OK - Python found
) else (
    echo     NOT FOUND - install.bat will install via winget
)
echo.

echo [3] winget...
winget --version >nul 2>&1
if %errorlevel%==0 (
    echo     OK - winget found
    winget --version
) else (
    echo     NOT FOUND - old Windows 10 or LTSB
)
echo.

echo [4] Internet...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel%==0 (
    echo     OK - internet works
) else (
    echo     FAIL - no internet connection
)
echo.

echo [5] GitHub...
ping -n 1 github.com >nul 2>&1
if %errorlevel%==0 (
    echo     OK - github.com reachable
) else (
    echo     FAIL - github.com not reachable
)
echo.

echo [6] Free disk space on C:...
for /f "tokens=3" %%a in ('dir C:\ /-c 2^>nul ^| findstr /i "bytes free"') do (
    echo     %%a bytes free
)
echo.

echo [7] Pipeline files after installation...
for %%f in (
    "C:\CNC-Pipeline\pipeline\main.py"
    "C:\CNC-Pipeline\pipeline\requirements.txt"
    "C:\CNC-Pipeline\setup_wizard.py"
    "C:\CNC-Pipeline\start.bat"
    "C:\CNC-Pipeline\configure.bat"
) do (
    if exist %%f (
        echo     OK   %%f
    ) else (
        echo     --   %%f  (not installed yet)
    )
)
echo.

echo =========================================
echo  Test complete. Screenshot and send to Roman.
echo =========================================
echo.
pause
