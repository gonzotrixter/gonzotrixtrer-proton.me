@echo off
chcp 65001 >nul
title Очистка ПК

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cls
echo.
echo  ╔══════════════════════════════════════════╗
echo  ║   Очистка ПК                              ║
echo  ║   Не закривайте це вікно!                 ║
echo  ╚══════════════════════════════════════════╝
echo.

echo  ── Крок 1: Тимчасові файли Windows ─────────
del /f /s /q "%TEMP%\*" >nul 2>&1
del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
echo      ✓ Виконано
echo.

echo  ── Крок 2: Кеш браузерів ────────────────────
:: Chrome
del /f /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache\*" >nul 2>&1
:: Edge
del /f /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache\*" >nul 2>&1
:: Firefox
for /d %%p in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do del /f /s /q "%%p\cache2\*" >nul 2>&1
echo      ✓ Виконано
echo.

echo  ── Крок 3: Очистка диска (системні файли) ───
cleanmgr /sagerun:1 >nul 2>&1
echo      ✓ Виконано
echo.

echo  ── Крок 4: DNS-кеш ──────────────────────────
ipconfig /flushdns >nul 2>&1
echo      ✓ Виконано
echo.

echo  ── Крок 5: Перевірка диска ──────────────────
echo      (тільки аналіз, нічого не видаляє)
chkdsk C: >nul 2>&1
echo      ✓ Виконано
echo.

echo  ── Крок 6: Оновлення Windows ────────────────
powershell -Command "Install-Module PSWindowsUpdate -Force -Confirm:$false >nul 2>&1; Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot >nul 2>&1" >nul 2>&1
echo      ✓ Виконано
echo.

cls
echo.
echo  ╔══════════════════════════════════════════╗
echo  ║                                           ║
echo  ║   ✅  ОЧИСТКУ ЗАВЕРШЕНО!                  ║
echo  ║                                           ║
echo  ║   Рекомендується перезавантажити ПК.      ║
echo  ║                                           ║
echo  ╚══════════════════════════════════════════╝
echo.
pause
