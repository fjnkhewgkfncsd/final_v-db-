# 🕐 Scheduled Backup System

## Overview

The Database Administration System now supports automated scheduled backups using multiple approaches. This ensures your database is regularly backed up without manual intervention.

## 🚀 Quick Setup

### Option 1: Windows Task Scheduler (Recommended)

1. **Run as Administrator:**
   ```cmd
   cd scripts
   setup_backup_scheduler.bat
   ```

2. **Or manually run PowerShell:**
   ```powershell
   cd scripts
   # Run as Administrator
   .\setup_scheduled_backups.ps1
   ```

### Option 2: Application-Level Scheduling

1. **Enable in environment:**
   ```env
   ENABLE_SCHEDULED_BACKUPS=true
   ```

2. **Restart backend server:**
   ```cmd
   cd backend
   npm start
   ```

## 📅 Default Backup Schedules

| Schedule | Frequency | Time | Retention | Type |
|----------|-----------|------|-----------|------|
| **Daily** | Every day | 2:00 AM | 7 days | Complete |
| **Weekly** | Every Sunday | 3:00 AM | 30 days | Complete |
| **Monthly** | 1st of month | 4:00 AM | 365 days | Complete |
| **Schema** | Every day | 1:00 AM | 7 days | Schema-only |

## 📁 File Organization

```
project_db(v2)/
├── backups/
│   ├── scheduled_backup_2025-07-11_02-00-00.sql
│   ├── weekly_backup_2025-07-07_03-00-00.sql
│   ├── monthly_backup_2025-07-01_04-00-00.sql
│   └── backup_registry.json
├── logs/
│   ├── backup_log_2025-07-11.log
│   └── backup_log_2025-07-10.log
└── scripts/
    ├── scheduled_backup.ps1
    ├── setup_scheduled_backups.ps1
    └── setup_backup_scheduler.bat
```

## 🔧 Configuration

### Environment Variables

```env
# Database Connection
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ecommerce_db
DB_USER=postgres
DB_PASSWORD=your_password

# Backup Settings
ENABLE_SCHEDULED_BACKUPS=true
BACKUP_RETENTION_DAYS=30
```

### PowerShell Script Parameters

```powershell
# Run specific backup type
.\scheduled_backup.ps1 -BackupType "complete" -RetentionDays 30
.\scheduled_backup.ps1 -BackupType "schema" -RetentionDays 7
.\scheduled_backup.ps1 -BackupType "data" -RetentionDays 14
```

## 📊 Monitoring

### Web Interface

1. **Access Database Tools → Scheduled Backups tab**
2. **View schedule status and configuration**
3. **Monitor last run and next scheduled run**

### Command Line

```powershell
# View all backup tasks
Get-ScheduledTask | Where-Object {$_.TaskName -like 'DatabaseBackup*'}

# Check task status
Get-ScheduledTask -TaskName "DatabaseBackup_Daily" | Select-Object State, LastRunTime, NextRunTime

# View task history
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'; ID=201} | 
    Where-Object {$_.Message -like '*DatabaseBackup*'} | 
    Select-Object TimeCreated, LevelDisplayName, Message -First 10
```

### Log Files

```powershell
# View today's backup log
Get-Content "logs\backup_log_$(Get-Date -Format 'yyyy-MM-dd').log" -Tail 20

# Monitor backup log in real-time
Get-Content "logs\backup_log_$(Get-Date -Format 'yyyy-MM-dd').log" -Wait -Tail 10
```

## 🛠️ Management Commands

### Windows Task Scheduler

```cmd
# List backup tasks
schtasks /query /tn "DatabaseBackup*"

# Run backup manually
schtasks /run /tn "DatabaseBackup_Daily"

# Enable/disable task
schtasks /change /tn "DatabaseBackup_Daily" /enable
schtasks /change /tn "DatabaseBackup_Daily" /disable

# Delete task
schtasks /delete /tn "DatabaseBackup_Daily" /f
```

### PowerShell Direct

```powershell
# Manual backup execution
.\scripts\scheduled_backup.ps1 -BackupType "complete"

# Test backup without retention cleanup
.\scripts\scheduled_backup.ps1 -BackupType "complete" -RetentionDays 999
```

## 🚨 Troubleshooting

### Common Issues

**1. Permission Denied**
```
Error: Access denied when creating scheduled task
Solution: Run PowerShell as Administrator
```

**2. pg_dump Not Found**
```
Error: 'pg_dump' is not recognized as an internal or external command
Solution: Add PostgreSQL bin directory to PATH environment variable
```

**3. Database Connection Failed**
```
Error: Connection to database failed
Solution: Verify database credentials and ensure PostgreSQL is running
```

**4. Backup File Not Created**
```
Error: Backup file was not created
Solution: Check disk space and backup directory permissions
```

### Validation Commands

```powershell
# Test database connection
psql -h localhost -p 5432 -U postgres -d ecommerce_db -c "SELECT 1;"

# Verify pg_dump accessibility
pg_dump --version

# Check backup directory permissions
Test-Path "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backups" -PathType Container

# Manual backup test
.\scripts\scheduled_backup.ps1 -BackupType "complete" -RetentionDays 1
```

## 📈 Performance Considerations

### Backup Performance

- **Complete backups**: ~2-5 minutes for typical database
- **Schema-only backups**: ~30 seconds
- **Data-only backups**: ~1-3 minutes

### Storage Requirements

- **Daily backups (7 days)**: ~70-350 MB
- **Weekly backups (4 weeks)**: ~40-200 MB  
- **Monthly backups (12 months)**: ~120-600 MB
- **Total estimated**: ~230-1150 MB

### System Impact

- **CPU usage**: Low (during backup execution)
- **Disk I/O**: Moderate (during backup creation)
- **Network**: None (local backup only)
- **Memory**: Low (~50-100 MB during backup)

## 🔐 Security

### File Permissions

- **Backup files**: Read/write for system administrators only
- **Log files**: Read/write for system administrators only
- **Scripts**: Execute permissions for administrators only

### Credential Management

- **Database password**: Stored in environment variables
- **Scheduled tasks**: Run under SYSTEM account
- **Emergency access**: Separate credentials for recovery

### Audit Trail

- **All backup operations logged**
- **File creation timestamps preserved**
- **Backup registry maintains metadata**
- **Windows Event Log integration**

## 📚 Additional Resources

- **Main Documentation**: `SYSTEM_DOCUMENTATION.md`
- **Emergency Recovery**: `EMERGENCY_RECOVERY_GUIDE.md`
- **Database Setup**: `SETUP.md`
- **Demo Credentials**: `DEMO_CREDENTIALS.md`

## 🆘 Support

If you encounter issues with scheduled backups:

1. **Check logs**: Review backup log files for error messages
2. **Verify configuration**: Ensure environment variables are set correctly
3. **Test manually**: Run backup script manually to isolate issues
4. **System requirements**: Verify PostgreSQL tools are installed and accessible
5. **Permissions**: Ensure proper file system and database permissions

For emergency database recovery, use the Emergency Recovery System at `http://localhost:3002`.
