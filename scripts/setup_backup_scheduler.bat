@echo off
REM Database Backup Scheduler Setup
REM This batch file sets up automated database backups using Windows Task Scheduler

echo.
echo ================================================================
echo      Database Administration System - Backup Scheduler Setup
echo ================================================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✓ Running as Administrator - proceeding with setup...
    echo.
) else (
    echo ❌ This script must be run as Administrator!
    echo    Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Set script path
set SCRIPT_DIR=%~dp0
set SETUP_SCRIPT=%SCRIPT_DIR%setup_scheduled_backups.ps1

REM Check if PowerShell script exists
if exist "%SETUP_SCRIPT%" (
    echo ✓ Found setup script: %SETUP_SCRIPT%
    echo.
) else (
    echo ❌ Setup script not found: %SETUP_SCRIPT%
    echo    Please ensure setup_scheduled_backups.ps1 exists in the scripts directory
    echo.
    pause
    exit /b 1
)

echo This will create the following scheduled task:
echo    * Daily Backup    : Every day at 2:00 AM (30-day retention)
echo.

set /p CONFIRM="Do you want to continue? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Setup cancelled.
    pause
    exit /b 0
)

echo.
echo 🚀 Running PowerShell setup script...
echo.

REM Execute PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%SETUP_SCRIPT%"

if %errorLevel% == 0 (
    echo.
    echo ✅ Backup scheduler setup completed successfully!
    echo.
    echo 🔧 Management Commands:
    echo    • View tasks: schtasks /query /tn "DatabaseBackup*"
    echo    • Run manual backup: schtasks /run /tn "DatabaseBackup_Daily"
    echo    • Delete tasks: schtasks /delete /tn "DatabaseBackup_Daily" /f
    echo.
    echo 📁 Backup location: %~dp0..\backups\
    echo 📝 Log location: %~dp0..\logs\
    echo.
) else (
    echo.
    echo ❌ Setup failed. Please check the error messages above.
    echo.
)

pause
