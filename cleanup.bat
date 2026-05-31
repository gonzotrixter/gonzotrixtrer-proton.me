@echo off
chcp 65001 >nul
title PC Cleanup

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo =========================================
echo  PC Cleanup
echo  Do not close this window!
echo =========================================
echo.

echo -- Step 1: Windows temp files --
del /f /s /q "%TEMP%\*" >nul 2>&1
del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
echo    OK - Done
echo.

echo -- Step 2: Browser cache --
del /f /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache\*" >nul 2>&1
del /f /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache\*" >nul 2>&1
for /d %%p in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do del /f /s /q "%%p\cache2\*" >nul 2>&1
echo    OK - Done
echo.

echo -- Step 3: Disk cleanup --
cleanmgr /sagerun:1 >nul 2>&1
echo    OK - Done
echo.

echo -- Step 4: DNS cache --
ipconfig /flushdns >nul 2>&1
echo    OK - Done
echo.

echo -- Step 5: Disk check (analysis only) --
echo    (read-only, nothing deleted)
chkdsk C: >nul 2>&1
echo    OK - Done
echo.

echo -- Step 6: Windows Update --
powershell -Command "Install-Module PSWindowsUpdate -Force -Confirm:$false >nul 2>&1; Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot >nul 2>&1" >nul 2>&1
echo    OK - Done
echo.

cls
echo.
echo =========================================
echo.
echo   CLEANUP COMPLETE!
echo.
echo   Recommended: restart the computer.
echo.
echo =========================================
echo.
pause
