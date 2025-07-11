# Setup Windows Task Scheduler for Database Backups
# This script creates scheduled tasks for automatic database backups

Write-Host "[INFO] Setting up Windows Task Scheduler for Database Backups" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Yellow

# Configuration
$SCRIPT_PATH = "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\scripts\scheduled_backup.ps1"
$TASK_NAME_DAILY = "DatabaseBackup_Daily"

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[ERROR] This script must be run as Administrator to create scheduled tasks!" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Verify backup script exists
if (-not (Test-Path $SCRIPT_PATH)) {
    Write-Host "[ERROR] Backup script not found at: $SCRIPT_PATH" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Backup script found: $SCRIPT_PATH" -ForegroundColor Green

try {
    # Remove existing tasks if they exist
    Write-Host "[INFO] Removing existing backup tasks..." -ForegroundColor Yellow
    
    try {
        $task = Get-ScheduledTask -TaskName $TASK_NAME_DAILY -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -TaskName $TASK_NAME_DAILY -Confirm:$false
            Write-Host "   [SUCCESS] Removed existing task: $TASK_NAME_DAILY" -ForegroundColor Green
        }
    } catch {
        # Task doesn't exist, continue
    }

    # Create Daily Backup Task (Every day at 4:15 AM)
    Write-Host "[INFO] Creating Daily Backup Task..." -ForegroundColor Cyan
    
    $dailyAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$SCRIPT_PATH`" -BackupType complete -RetentionDays 30"
    $dailyTrigger = New-ScheduledTaskTrigger -Daily -At "04:15"
    $dailySettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    $dailyPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName $TASK_NAME_DAILY -Action $dailyAction -Trigger $dailyTrigger -Settings $dailySettings -Principal $dailyPrincipal -Description "Daily database backup at 4:15 AM with 30-day retention"
    
    Write-Host "   [SUCCESS] Daily backup task created successfully" -ForegroundColor Green
    Write-Host "      Schedule: Every day at 4:15 AM" -ForegroundColor Gray
    Write-Host "      Retention: 30 days" -ForegroundColor Gray

    Write-Host ""
    Write-Host "[SUCCESS] Daily backup task created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Summary:" -ForegroundColor Yellow
    Write-Host "   * Daily Backup    : Every day at 4:15 AM (30-day retention)" -ForegroundColor White
    Write-Host ""
    Write-Host "Backup Location  : D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backups" -ForegroundColor Cyan
    Write-Host "Log Location     : D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\logs" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Management Commands:" -ForegroundColor Yellow
    Write-Host "   View tasks        : Get-ScheduledTask | Where-Object {`$_.TaskName -like 'DatabaseBackup*'}" -ForegroundColor Gray
    Write-Host "   Run task manually : Start-ScheduledTask -TaskName 'DatabaseBackup_Daily'" -ForegroundColor Gray
    Write-Host "   Disable task      : Disable-ScheduledTask -TaskName 'DatabaseBackup_Daily'" -ForegroundColor Gray
    Write-Host "   Remove task       : Unregister-ScheduledTask -TaskName 'DatabaseBackup_Daily'" -ForegroundColor Gray

} catch {
    Write-Host "[ERROR] Error creating scheduled tasks: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[SUCCESS] Scheduled backup setup completed successfully!" -ForegroundColor Green
