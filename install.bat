@echo off
chcp 65001 >nul
title CNC Pipeline - Installation

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo =========================================
echo  CNC Pipeline - Automatic Installation
echo  Do not close this window!
echo  Process takes 15-30 minutes.
echo =========================================
echo.
echo  Started: %date% %time%
echo.

:: -----------------------------------------
::  [1/6] Python
:: -----------------------------------------
echo -- Step 1 of 6: Python --

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo    Installing Python 3.11...
    winget install Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements >nul 2>&1

    for %%v in (Python313 Python312 Python311 Python310) do (
        if exist "%LOCALAPPDATA%\Programs\Python\%%v\python.exe" (
            set "PATH=%LOCALAPPDATA%\Programs\Python\%%v;%LOCALAPPDATA%\Programs\Python\%%v\Scripts;%PATH%"
        )
    )

    for /l %%i in (1,1,5) do (
        python --version >nul 2>&1
        if not errorlevel 1 goto :python_ok
        echo    Waiting... (attempt %%i of 5)
        timeout /t 4 /nobreak >nul
    )

    echo.
    echo  winget failed. Opening Python download page...
    start "" "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
    echo.
    echo =========================================
    echo  Install Python from the downloaded file.
    echo  IMPORTANT: check "Add Python to PATH"
    echo  Then run install.bat again.
    echo =========================================
    echo.
    pause
    exit /b 1
)

:python_ok
echo    OK - Python ready
echo.

:: -----------------------------------------
::  [2/6] Folders
:: -----------------------------------------
echo -- Step 2 of 6: Creating folders --
for %%d in (
    "C:\CNC-Pipeline"
    "C:\CNC-Pipeline\incoming"
    "C:\CNC-Pipeline\output"
    "C:\CNC-Pipeline\rejected"
    "C:\CNC-Pipeline\processing"
    "C:\CNC-Pipeline\logs"
    "C:\CNC-Pipeline\pipeline"
) do mkdir %%d 2>nul
echo    OK - Folders created
echo.

:: -----------------------------------------
::  [3/6] Download from GitHub
:: -----------------------------------------
echo -- Step 3 of 6: Downloading pipeline --

set "ZIP_URL=https://github.com/gonzotrixter/gonzotrixtrer-proton.me/archive/refs/heads/main.zip"

powershell -NoProfile -Command ^
  "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile 'C:\CNC-Pipeline\src.zip' -UseBasicParsing" >nul 2>&1

if not exist "C:\CNC-Pipeline\src.zip" (
    cls
    echo.
    echo =========================================
    echo  ERROR
    echo.
    echo  No internet or server unavailable.
    echo  Check connection and run install.bat again.
    echo.
    echo  Call Roman.
    echo =========================================
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

if not exist "C:\CNC-Pipeline\pipeline\main.py" (
    echo  ERROR: Pipeline files not found after extraction.
    echo  Call Roman.
    pause
    exit /b 1
)

echo    OK - Files downloaded
echo.

:: -----------------------------------------
::  [4/6] pip install
:: -----------------------------------------
echo -- Step 4 of 6: Installing packages --
echo    (may take 10-20 minutes, please wait)
echo.

python -m pip install --upgrade pip -q --no-warn-script-location

if exist "C:\CNC-Pipeline\pipeline\requirements.txt" (
    python -m pip install -r "C:\CNC-Pipeline\pipeline\requirements.txt" -q --no-warn-script-location
)

echo    Installing PyTorch CPU (~200 MB)...
python -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu -q --no-warn-script-location

echo    OK - Packages installed
echo.

:: -----------------------------------------
::  [5/6] Syncthing
:: -----------------------------------------
echo -- Step 5 of 6: Installing Syncthing --
winget install SyncThing.SyncThing --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
if %errorlevel% equ 0 (
    echo    OK - Syncthing installed
) else (
    echo    WARNING - Syncthing not installed via winget
    echo    Roman will install manually when he arrives
)
echo.

:: -----------------------------------------
::  [6/6] Download AI model MiDaS
:: -----------------------------------------
echo -- Step 6 of 6: Downloading AI model --
echo    (~200 MB, one time, may take 5+ minutes)
echo.

powershell -NoProfile -Command ^
  "$proc = Start-Process python -ArgumentList 'C:\CNC-Pipeline\preload_models.py' -NoNewWindow -PassThru; ^
   if (-not $proc.WaitForExit(600000)) { $proc.Kill(); Write-Host 'Timeout - model will download on first run' }"

echo.
echo    OK - Done
echo.

:: -----------------------------------------
::  Desktop shortcut
:: -----------------------------------------
powershell -NoProfile -Command ^
  "$ws = New-Object -ComObject WScript.Shell; ^
   $sc = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\CNC Settings.lnk'); ^
   $sc.TargetPath = 'C:\CNC-Pipeline\configure.bat'; ^
   $sc.WorkingDirectory = 'C:\CNC-Pipeline'; ^
   $sc.Description = 'CNC Pipeline - Telegram setup'; ^
   $sc.Save()" >nul 2>&1

:: -----------------------------------------
::  DONE
:: -----------------------------------------
cls
echo.
echo =========================================
echo.
echo   COMPUTER IS READY!
echo.
echo   Nothing else needs to be done.
echo.
echo   Call Roman -
echo   he will configure the rest when he arrives.
echo.
echo =========================================
echo.
echo  Finished: %date% %time%
echo.
pause
