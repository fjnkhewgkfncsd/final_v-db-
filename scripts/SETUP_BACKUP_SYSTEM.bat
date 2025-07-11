REM ===============================================================
REM   Database Backup System - One-Click Setup
REM ===============================================================
REM
REM This batch file provides a quick setup for the backup system.
REM It will test your system and guide you through the setup process.
REM
REM Prerequisites:
REM   - PostgreSQL installed with pg_dump in PATH
REM   - Node.js installed
REM   - Running as Administrator (for Task Scheduler setup)
REM
REM ===============================================================

@echo off
title Database Backup System Setup

echo.
echo  ███████╗ ██████╗██╗  ██╗███████╗██████╗ ██╗   ██╗██╗     ███████╗██████╗ 
echo  ██╔════╝██╔════╝██║  ██║██╔════╝██╔══██╗██║   ██║██║     ██╔════╝██╔══██╗
echo  ███████╗██║     ███████║█████╗  ██║  ██║██║   ██║██║     █████╗  ██║  ██║
echo  ╚════██║██║     ██╔══██║██╔══╝  ██║  ██║██║   ██║██║     ██╔══╝  ██║  ██║
echo  ███████║╚██████╗██║  ██║███████╗██████╔╝╚██████╔╝███████╗███████╗██████╔╝
echo  ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚═════╝ 
echo.
echo            ██████╗  █████╗  ██████╗██╗  ██╗██╗   ██╗██████╗ 
echo            ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗
echo            ██████╔╝███████║██║     █████╔╝ ██║   ██║██████╔╝
echo            ██╔══██╗██╔══██║██║     ██╔═██╗ ██║   ██║██╔═══╝ 
echo            ██████╔╝██║  ██║╚██████╗██║  ██╗╚██████╔╝██║     
echo            ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     
echo.
echo ===============================================================
echo          Automated Database Backup System Setup
echo ===============================================================
echo.

REM Check if running from correct directory
if not exist "scheduled_backup.ps1" (
    echo ❌ Error: This script must be run from the scripts directory
    echo.
    echo Current directory: %CD%
    echo Expected files: scheduled_backup.ps1, setup_scheduled_backups.ps1
    echo.
    echo Please navigate to: D:\year2\year2_term3\DatabaseAdmin\project_db^(v2^)\scripts
    echo Then run this script again.
    echo.
    pause
    exit /b 1
)

echo 📋 What this setup will do:
echo    ✓ Test your system prerequisites
echo    ✓ Verify PostgreSQL and Node.js installation
echo    ✓ Test database connectivity
echo    ✓ Create backup directories
echo    ✓ Run a test backup
echo    ✓ Set up Windows Task Scheduler (if Administrator)
echo    ✓ Configure automated backup schedules
echo.

set /p CONTINUE="Ready to proceed? (Y/N): "
if /i not "%CONTINUE%"=="Y" (
    echo Setup cancelled.
    pause
    exit /b 0
)

echo.
echo 🔍 Step 1: Running system tests...
echo ======================================
powershell.exe -ExecutionPolicy Bypass -File "test_backup_system.ps1"

if %errorLevel% neq 0 (
    echo.
    echo ❌ System tests revealed issues. Please resolve them before continuing.
    echo.
    pause
    exit /b 1
)

echo.
echo 🚀 Step 2: Setting up scheduled tasks...
echo =========================================

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✓ Administrator privileges detected
    echo.
    
    set /p SETUP_TASKS="Set up Windows Task Scheduler tasks? (Y/N): "
    if /i "%SETUP_TASKS%"=="Y" (
        powershell.exe -ExecutionPolicy Bypass -File "setup_scheduled_backups.ps1"
        
        if %errorLevel% == 0 (
            echo.
            echo ✅ Task Scheduler setup completed successfully!
        ) else (
            echo.
            echo ⚠️  Task Scheduler setup encountered issues.
        )
    )
) else (
    echo ⚠️  Not running as Administrator
    echo    Task Scheduler setup will be skipped
    echo    Run this script as Administrator to create scheduled tasks
)

echo.
echo 📊 Step 3: Testing web interface integration...
echo ===============================================

REM Check if backend is running
powershell.exe -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:3001/health' -TimeoutSec 5; Write-Host '✓ Backend server is running' } catch { Write-Host '⚠️  Backend server not running' }"

echo.
echo 🎉 Setup Complete!
echo ==================
echo.
echo 📁 Backup Location: %~dp0..\backups\
echo 📝 Log Location: %~dp0..\logs\
echo.
echo 🌐 Web Interface:
echo    • Main App: http://localhost:3000
echo    • Login: admin@example.com / admin123
echo    • Navigate: Database Tools → Scheduled Backups
echo.
echo 🔧 Management Commands:
echo    • View tasks: schtasks /query /tn "DatabaseBackup*"
echo    • Run manual: schtasks /run /tn "DatabaseBackup_Daily"
echo    • Test script: powershell .\test_backup_system.ps1
echo.
echo 📚 Documentation:
echo    • QUICK_SETUP_SCHEDULED_BACKUPS.md
echo    • SCHEDULED_BACKUP_GUIDE.md
echo    • SYSTEM_DOCUMENTATION.md
echo.

set /p OPEN_DOCS="Open quick setup guide? (Y/N): "
if /i "%OPEN_DOCS%"=="Y" (
    if exist "..\QUICK_SETUP_SCHEDULED_BACKUPS.md" (
        start "" "..\QUICK_SETUP_SCHEDULED_BACKUPS.md"
    )
)

echo.
echo ✅ Your database backup system is ready!
echo    Scheduled backups will run automatically according to the configured schedule.
echo.
pause
