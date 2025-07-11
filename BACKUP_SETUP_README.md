# 🚀 Scheduled Backup System - Complete Quick Setup Guide

## 🎯 One-Line Setup (Easiest)

**Just double-click this file:**
```
📁 scripts/SETUP_BACKUP_SYSTEM.bat
```
*(Right-click → "Run as administrator" for full features)*

---

## 📋 Quick Setup Options

### Option 1: Complete Automated Setup (Recommended)
```cmd
cd "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\scripts"
SETUP_BACKUP_SYSTEM.bat
```
**What it does:**
- ✅ Tests all prerequisites automatically  
- ✅ Verifies PostgreSQL and database connectivity
- ✅ Creates backup directories
- ✅ Runs test backup to validate system
- ✅ Sets up Windows Task Scheduler (if admin)
- ✅ Provides status and next steps

### Option 2: Windows Task Scheduler Only
```cmd
cd scripts
setup_backup_scheduler.bat
```
**When to use:** You only want scheduled tasks, no testing

### Option 3: Application-Level Scheduling
```env
# Add to backend/.env
ENABLE_SCHEDULED_BACKUPS=true
```
```cmd
cd backend
npm start
```
**When to use:** Development environment or when you can't use Task Scheduler

### Option 4: Manual PowerShell Setup
```powershell
# Run as Administrator
cd scripts
.\setup_scheduled_backups.ps1
```
**When to use:** Advanced users who want PowerShell control

---

## ⚡ Super Quick Commands

### Test Everything
```powershell
cd scripts
.\test_backup_system.ps1
```

### Run Manual Backup
```powershell
cd scripts
.\scheduled_backup.ps1 -BackupType "complete"
```

### Check Backup Status
```powershell
# View scheduled tasks
schtasks /query /tn "DatabaseBackup*"

# Check recent backups
dir ..\backups\*.sql | sort LastWriteTime -desc | select -first 5
```

### Monitor Logs
```powershell
# Watch backup logs in real-time
Get-Content "..\logs\backup_$(Get-Date -Format 'yyyy-MM-dd').log" -Wait -Tail 10
```

---

## 🔧 Prerequisites (Auto-checked by setup)

- ✅ **PostgreSQL** with `pg_dump` and `psql` in PATH
- ✅ **Node.js 16+** installed  
- ✅ **Administrator privileges** (for Task Scheduler)
- ✅ **Database running** and accessible
- ✅ **1GB+ free disk space**

### Quick Prerequisite Check
```powershell
# Test database connection
psql -h localhost -p 5432 -U postgres -d ecommerce_db -c "SELECT 1;"

# Test PostgreSQL tools
pg_dump --version
psql --version

# Check Node.js
node --version
```

---

## 📅 Default Backup Schedule

| Schedule | Time | Frequency | Retention | File Pattern |
|----------|------|-----------|-----------|--------------|
| **Daily** | 2:00 AM | Every day | 7 days | `daily_backup_*.sql` |
| **Weekly** | 3:00 AM | Every Sunday | 30 days | `weekly_backup_*.sql` |
| **Monthly** | 4:00 AM | 1st of month | 365 days | `monthly_backup_*.sql` |
| **Schema** | 1:00 AM | Every day | 7 days | `schema_backup_*.sql` |

---

## 🖥️ Web Interface Access

1. **Start your application:**
   ```cmd
   # Terminal 1: Backend
   cd backend && npm start
   
   # Terminal 2: Frontend  
   cd frontend && npm start
   ```

2. **Access web interface:**
   - URL: http://localhost:3000
   - Login: `admin@example.com` / `admin123`
   - Navigate: **Database Tools** → **Scheduled Backups** tab

3. **Monitor status:**
   - View schedule configuration
   - Check next run times
   - Monitor backup history
   - Access management tools

---

## 📁 File Locations

```
project_db(v2)/
├── scripts/
│   ├── SETUP_BACKUP_SYSTEM.bat      ← 🎯 Main setup file
│   ├── test_backup_system.ps1       ← System validation
│   ├── scheduled_backup.ps1          ← Core backup script
│   ├── setup_scheduled_backups.ps1   ← Task Scheduler setup
│   └── setup_backup_scheduler.bat    ← Task Scheduler (simple)
├── backups/                          ← Backup files stored here
├── logs/                             ← Backup logs stored here
├── backend/services/
│   └── backupScheduler.js            ← Node.js cron scheduler
└── frontend/src/components/
    └── ScheduledBackups.js            ← Web interface
```

---

## 🚨 Common Issues & Quick Fixes

### "pg_dump not found"
```powershell
# Add PostgreSQL to PATH
$env:PATH += ";C:\Program Files\PostgreSQL\14\bin"
```

### "Access denied creating tasks"  
```
Solution: Run as Administrator
Right-click PowerShell → "Run as administrator"
```

### "Database connection failed"
```powershell
# Check PostgreSQL service
Get-Service -Name "*postgresql*"
Start-Service postgresql-x64-14
```

### "Backup directory not accessible"
```powershell
# Create directory manually
New-Item -Path "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)\backups" -ItemType Directory -Force
```

---

## 🔍 Verification Steps

After setup, verify these work:

1. **Scheduled tasks created:**
   ```cmd
   schtasks /query /tn "DatabaseBackup*"
   ```

2. **Manual backup works:**
   ```cmd
   schtasks /run /tn "DatabaseBackup_Daily"
   ```

3. **Backup files generated:**
   ```cmd
   dir backups\*.sql
   ```

4. **Web interface accessible:**
   - http://localhost:3000 → Database Tools → Scheduled Backups

5. **Logs contain success messages:**
   ```cmd
   type logs\backup_2025-07-11.log
   ```

---

## 📞 Need Help?

1. **Run the test script:** `scripts\test_backup_system.ps1`
2. **Check documentation:** 
   - `QUICK_SETUP_SCHEDULED_BACKUPS.md` (detailed guide)
   - `SCHEDULED_BACKUP_GUIDE.md` (complete docs)
   - `SYSTEM_DOCUMENTATION.md` (full system)
3. **Check logs:** Review files in `logs\` directory
4. **Test manually:** Run backup scripts directly
5. **Emergency backup:** Use manual backup from web interface

---

## 🎉 Success Indicators

✅ **Setup Complete When You See:**
- Scheduled tasks appear in Task Scheduler
- Backup files generated in `backups/` directory  
- Log files show success messages
- Web interface displays schedule status
- Manual backup test completes successfully

**🛡️ Your database is now protected with automated backups!**

---

*For additional help and advanced configuration, see the complete documentation in `SCHEDULED_BACKUP_GUIDE.md`*
