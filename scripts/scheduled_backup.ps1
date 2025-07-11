# Automated Database Backup Script for Windows Task Scheduler
# This script performs automated backups with rotation and logging
# Updated to match web interface backup format for proper restoration

param(
    [string]$BackupType = "complete",
    [int]$RetentionDays = 30
)

# Configuration
$DB_HOST = "localhost"
$DB_PORT = "5432"
$DB_NAME = "ecommerce_db"
$DB_USER = "postgres"
$DB_PASSWORD = "hengmengly123"  # Use environment variable in production
$BACKUP_DIR = "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backups"
$LOG_DIR = "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\logs"

# Ensure directories exist
if (!(Test-Path $BACKUP_DIR)) { New-Item -ItemType Directory -Path $BACKUP_DIR -Force }
if (!(Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Path $LOG_DIR -Force }

# Generate timestamp and filenames
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupFile = "$BACKUP_DIR\scheduled_backup_$timestamp.sql"
$logFile = "$LOG_DIR\backup_log_$(Get-Date -Format 'yyyy-MM-dd').log"

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Output $logEntry
    Add-Content -Path $logFile -Value $logEntry
}

Write-Log "Starting scheduled backup process" "INFO"
Write-Log "Backup type: $BackupType, Retention: $RetentionDays days" "INFO"

try {
    # Set PostgreSQL password environment variable
    $env:PGPASSWORD = $DB_PASSWORD
    
    # Build pg_dump command based on backup type
    $pgDumpArgs = @(
        "-h", $DB_HOST,
        "-p", $DB_PORT,
        "-U", $DB_USER,
        "-d", $DB_NAME,
        "-f", $backupFile,
        "--verbose"
    )
    
    switch ($BackupType.ToLower()) {
        "schema" { 
            $pgDumpArgs += "--schema-only", "--clean", "--if-exists", "--create", "--no-owner"
        }
        "data" { 
            $pgDumpArgs += "--data-only", "--disable-triggers", "--no-owner"
        }
        default { 
            # Complete backup (default) - matches web interface backup format
            $pgDumpArgs += "--clean", "--if-exists", "--create", "--no-owner", "--no-privileges"
        }
    }
    
    Write-Log "Executing pg_dump with args: $($pgDumpArgs -join ' ')" "INFO"
    Write-Log "Backup format: Compatible with web interface restore functionality" "INFO"
    
    # Execute backup
    $process = Start-Process -FilePath "pg_dump" -ArgumentList $pgDumpArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        # Verify backup file exists and has content
        if (Test-Path $backupFile) {
            $fileSize = (Get-Item $backupFile).Length
            $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
            
            if ($fileSize -gt 0) {
                Write-Log "Backup completed successfully" "SUCCESS"
                Write-Log "File: $backupFile" "INFO"
                Write-Log "Size: $fileSizeMB MB" "INFO"
                
                # Update backup registry (for web interface)
                $registryFile = "$BACKUP_DIR\backup_registry.json"
                $backupInfo = @{
                    filename = Split-Path $backupFile -Leaf
                    filepath = $backupFile
                    type = $BackupType
                    size = $fileSize
                    created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    created_by = "Scheduled Task"
                    status = "completed"
                }
                
                if (Test-Path $registryFile) {
                    $registry = Get-Content $registryFile | ConvertFrom-Json
                    $registry += $backupInfo
                } else {
                    $registry = @($backupInfo)
                }
                
                $registry | ConvertTo-Json -Depth 3 | Set-Content $registryFile
                Write-Log "Backup registry updated" "INFO"
                
            } else {
                Write-Log "Backup file is empty!" "ERROR"
                Remove-Item $backupFile -Force
                exit 1
            }
        } else {
            Write-Log "Backup file was not created!" "ERROR"
            exit 1
        }
    } else {
        Write-Log "pg_dump failed with exit code: $($process.ExitCode)" "ERROR"
        exit 1
    }
    
} catch {
    Write-Log "Backup failed with exception: $($_.Exception.Message)" "ERROR"
    exit 1
} finally {
    # Clear password environment variable
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

# Cleanup old backups (retention policy)
try {
    Write-Log "Starting cleanup of old backups (retention: $RetentionDays days)" "INFO"
    
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $oldBackups = Get-ChildItem -Path $BACKUP_DIR -Filter "scheduled_backup_*.sql" | 
                  Where-Object { $_.CreationTime -lt $cutoffDate }
    
    foreach ($oldBackup in $oldBackups) {
        try {
            Remove-Item $oldBackup.FullName -Force
            Write-Log "Deleted old backup: $($oldBackup.Name)" "INFO"
        } catch {
            Write-Log "Failed to delete old backup $($oldBackup.Name): $($_.Exception.Message)" "WARNING"
        }
    }
    
    Write-Log "Cleanup completed. Deleted $($oldBackups.Count) old backup(s)" "INFO"
    
} catch {
    Write-Log "Cleanup failed: $($_.Exception.Message)" "WARNING"
}

# Cleanup old log files (keep 90 days)
try {
    $logCutoffDate = (Get-Date).AddDays(-90)
    $oldLogs = Get-ChildItem -Path $LOG_DIR -Filter "backup_log_*.log" | 
               Where-Object { $_.CreationTime -lt $logCutoffDate }
    
    foreach ($oldLog in $oldLogs) {
        Remove-Item $oldLog.FullName -Force
    }
    
    if ($oldLogs.Count -gt 0) {
        Write-Log "Deleted $($oldLogs.Count) old log file(s)" "INFO"
    }
    
} catch {
    Write-Log "Log cleanup failed: $($_.Exception.Message)" "WARNING"
}

Write-Log "Scheduled backup process completed successfully" "SUCCESS"
exit 0
