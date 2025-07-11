# 🚀 Scheduled Backup System - Quick Setup Guide

## 📋 Prerequisites Checklist

Before setting up scheduled backups, ensure you have:

- ✅ **PostgreSQL installed** with `pg_dump` and `psql` in your PATH
- ✅ **Node.js 16+** installed for application-level scheduling
- ✅ **Administrator privileges** for Windows Task Scheduler setup
- ✅ **Database running** and accessible with provided credentials
- ✅ **Sufficient disk space** for backup files (recommend 1GB+ free)

### Verify Prerequisites

```powershell
# Test PostgreSQL tools
pg_dump --version
psql --version

# Test database connection
psql -h localhost -p 5432 -U postgres -d ecommerce_db -c "SELECT 1;"

# Check Node.js version
node --version
npm --version

# Verify current user has admin rights (should show "True")
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
```

---

## 🎯 Method 1: Windows Task Scheduler (Recommended for Production)

### Step 1: Navigate to Scripts Directory
```powershell
# Open PowerShell in your project directory
cd "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\scripts"

# Verify scripts exist
dir *.ps1, *.bat
```

### Step 2: Run Setup as Administrator

**Option A: Double-click setup (Easiest)**
```
1. Right-click on "setup_backup_scheduler.bat"
2. Select "Run as administrator"
3. Follow the prompts
```

**Option B: PowerShell command (Advanced)**
```powershell
# Run as Administrator
.\setup_scheduled_backups.ps1
```

### Step 3: Verify Task Creation
```powershell
# Check if tasks were created
Get-ScheduledTask | Where-Object {$_.TaskName -like 'DatabaseBackup*'} | 
    Select-Object TaskName, State, LastRunTime, NextRunTime

# View task details
schtasks /query /tn "DatabaseBackup_Daily" /fo LIST /v
```

### Step 4: Test Manual Execution
```powershell
# Run daily backup task manually
schtasks /run /tn "DatabaseBackup_Daily"

# Monitor the backup process
Get-Content "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\logs\backup_$(Get-Date -Format 'yyyy-MM-dd').log" -Wait -Tail 10
```

### Step 5: Verify Backup Files
```powershell
# Check backup directory
dir "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backups\*.sql" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object Name, Length, LastWriteTime -First 5
```

---

## 🎯 Method 2: Application-Level Scheduling (Development)

### Step 1: Configure Environment Variables

Create or update `.env` file in backend directory:
```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ecommerce_db
DB_USER=postgres
DB_PASSWORD=hengmengly123

# Backup Configuration
ENABLE_SCHEDULED_BACKUPS=true
BACKUP_RETENTION_DAYS=30

# Optional: Timezone setting
TZ=America/New_York
```

### Step 2: Install Dependencies
```powershell
cd "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backend"

# Install node-cron if not already installed
npm install node-cron --save

# Verify installation
npm list node-cron
```

### Step 3: Start Backend with Scheduling
```powershell
# Start backend server
npm start

# You should see these messages:
# 🕐 Initializing backup scheduler...
# 🕐 Setting up backup schedules...
# ✅ Backup scheduler initialized successfully
```

### Step 4: Test Schedule Status API
```powershell
# Test the backup schedule endpoint (after starting backend)
curl http://localhost:3001/api/backup/schedule -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Or use browser to test (login first): 
# http://localhost:3000 → Database Tools → Scheduled Backups tab
```

---

## 🔧 Configuration Customization

### Modify Backup Schedules

Edit `backend/services/backupScheduler.js`:
```javascript
// Change schedule times (cron format: minute hour day month dayOfWeek)
cron.schedule('0 2 * * *', () => {    // Daily at 2:00 AM
cron.schedule('0 3 * * 0', () => {    // Sunday at 3:00 AM  
cron.schedule('0 4 1 * *', () => {    // 1st of month at 4:00 AM
cron.schedule('0 1 * * *', () => {    // Daily at 1:00 AM (schema)
```

### Change Retention Policies

Edit retention days in the scheduler:
```javascript
this.performBackup('daily', 'complete', 7);     // 7 days
this.performBackup('weekly', 'complete', 30);   // 30 days
this.performBackup('monthly', 'complete', 365); // 365 days
```

### Custom Backup Location

Edit paths in `backupScheduler.js`:
```javascript
this.backupDir = path.join(__dirname, '..', 'custom_backup_location');
this.logDir = path.join(__dirname, '..', 'custom_log_location');
```

---

## 🔍 Monitoring and Verification

### Check Backup Status in Web Interface

1. **Access Application**: http://localhost:3000
2. **Login as Admin**: admin@example.com / admin123
3. **Navigate**: Database Tools → Scheduled Backups tab
4. **Monitor**: View schedule status, next run time, and configuration

### Monitor Logs in Real-time
```powershell
# Watch backup logs as they happen
Get-Content "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\logs\backup_$(Get-Date -Format 'yyyy-MM-dd').log" -Wait -Tail 20

# View Windows Task Scheduler logs
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'; ID=201} | 
    Where-Object {$_.Message -like '*DatabaseBackup*'} | 
    Select-Object TimeCreated, LevelDisplayName, Message -First 5
```

### Backup File Verification
```powershell
# List recent backups with sizes
Get-ChildItem "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backups\*.sql" | 
    Sort-Object LastWriteTime -Descending | 
    ForEach-Object { 
        "{0,-30} {1,10} MB  {2}" -f $_.Name, 
        [math]::Round($_.Length/1MB, 2), 
        $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    } | Select-Object -First 10
```

### Test Backup Integrity
```powershell
# Test if backup file can be read by PostgreSQL
$latestBackup = Get-ChildItem "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backups\*.sql" | 
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

psql -h localhost -p 5432 -U postgres -d ecommerce_db -c "\q" -f $latestBackup.FullName --dry-run
```

---

## 🛠️ Management Commands

### Windows Task Scheduler Management
```powershell
# View all backup tasks
schtasks /query /tn "DatabaseBackup*"

# Enable/Disable tasks
schtasks /change /tn "DatabaseBackup_Daily" /enable
schtasks /change /tn "DatabaseBackup_Daily" /disable

# Delete specific task
schtasks /delete /tn "DatabaseBackup_Daily" /f

# Export task configuration
schtasks /query /tn "DatabaseBackup_Daily" /xml > backup_task_config.xml
```

### Manual Backup Execution
```powershell
# Run PowerShell backup script directly
cd "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\scripts"

# Complete backup
.\scheduled_backup.ps1 -BackupType "complete" -RetentionDays 30

# Schema-only backup
.\scheduled_backup.ps1 -BackupType "schema" -RetentionDays 7

# Data-only backup
.\scheduled_backup.ps1 -BackupType "data" -RetentionDays 14
```

### Application-Level Management
```powershell
# Disable scheduled backups in application
$env:ENABLE_SCHEDULED_BACKUPS="false"

# Check backup scheduler status via API
curl -X GET "http://localhost:3001/api/backup/schedule" -H "Authorization: Bearer YOUR_TOKEN"

# Restart backend to reload configuration
# Ctrl+C to stop, then: npm start
```

---

## 🚨 Troubleshooting Guide

### Common Issues and Solutions

#### **Issue 1: "pg_dump is not recognized"**
```powershell
# Solution: Add PostgreSQL to PATH
$env:PATH += ";C:\Program Files\PostgreSQL\14\bin"  # Adjust version as needed

# Permanent solution: Add to system PATH via System Properties
# Or create a batch file with full path:
"C:\Program Files\PostgreSQL\14\bin\pg_dump.exe" --version
```

#### **Issue 2: "Access denied" when creating tasks**
```powershell
# Solution: Run PowerShell as Administrator
# Right-click PowerShell → "Run as administrator"

# Verify admin privileges:
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
```

#### **Issue 3: Database connection failed**
```powershell
# Test connection manually
psql -h localhost -p 5432 -U postgres -d ecommerce_db -c "SELECT version();"

# Check if PostgreSQL service is running
Get-Service -Name "*postgresql*"

# Start PostgreSQL if needed
Start-Service postgresql-x64-14  # Adjust service name as needed
```

#### **Issue 4: Backup directory not accessible**
```powershell
# Create backup directory manually
New-Item -Path "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backups" -ItemType Directory -Force

# Check directory permissions
Get-Acl "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backups"

# Grant full access to current user
icacls "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backups" /grant "$env:USERNAME:(F)"
```

#### **Issue 5: Node.js cron jobs not starting**
```powershell
# Check backend logs for errors
cd "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backend"
npm start

# Look for these messages:
# ❌ Failed to initialize backup scheduler: [error message]
# ✅ Backup scheduler initialized successfully

# Check node-cron installation
npm list node-cron
```

---

## 📊 Performance Tuning

### Optimize Backup Performance
```powershell
# Use compression for large databases
# Edit scheduled_backup.ps1 and add --compress=9 to pg_dump args

# Parallel backup for faster execution
# Add --jobs=4 to pg_dump args (PostgreSQL 9.3+)

# Exclude unnecessary tables
# Add --exclude-table=table_name to pg_dump args
```

### Monitor Resource Usage
```powershell
# Monitor backup process CPU/Memory usage
Get-Process | Where-Object {$_.ProcessName -like "*pg_dump*" -or $_.ProcessName -like "*postgres*"}

# Check disk space during backup
Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "D:"} | Select-Object Size, FreeSpace
```

---

## 📝 Validation Checklist

After setup, verify these items:

- [x] **PowerShell scripts execute without errors** ✅
- [x] **Windows tasks are created and enabled** ✅
- [ ] **Backup files are generated in correct location**
- [ ] **Log files contain success messages**
- [ ] **Web interface shows schedule status**
- [ ] **Manual task execution works**
- [ ] **Backup file integrity verified**
- [ ] **Old backups are cleaned up according to retention policy**
- [ ] **Backup registry JSON file is updated**
- [ ] **Scheduled tasks run at specified times**

## 🆘 Getting Help

If you encounter persistent issues:

1. **Check logs**: Review backup log files for detailed error messages
2. **Verify prerequisites**: Ensure all requirements are met
3. **Test manually**: Run backup scripts manually to isolate issues
4. **Check documentation**: Review `SCHEDULED_BACKUP_GUIDE.md` for additional details
5. **Emergency backup**: Use manual backup from Database Tools tab as fallback

---

**🎉 Congratulations!** Your scheduled backup system is now ready to protect your database automatically!
