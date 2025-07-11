# Test Scheduled Backup System
# This script validates that the backup system is properly configured

Write-Host "🧪 Testing Scheduled Backup System" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Yellow
Write-Host ""

$projectRoot = "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)"
$scriptsDir = "$projectRoot\scripts"
$backupDir = "$projectRoot\backups"
$logDir = "$projectRoot\logs"
$backendDir = "$projectRoot\backend"

# Test 1: Check if required files exist
Write-Host "🔍 Test 1: Checking required files..." -ForegroundColor Cyan

$requiredFiles = @(
    "$scriptsDir\scheduled_backup.ps1",
    "$scriptsDir\setup_scheduled_backups.ps1", 
    "$scriptsDir\setup_backup_scheduler.bat",
    "$backendDir\services\backupScheduler.js"
)

$filesOK = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "   ✅ Found: $(Split-Path $file -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Missing: $(Split-Path $file -Leaf)" -ForegroundColor Red
        $filesOK = $false
    }
}

if (-not $filesOK) {
    Write-Host "❌ Some required files are missing. Please ensure all backup scripts are in place." -ForegroundColor Red
    exit 1
}

# Test 2: Check PostgreSQL tools
Write-Host "`n🔍 Test 2: Checking PostgreSQL tools..." -ForegroundColor Cyan

try {
    $pgDumpVersion = & pg_dump --version 2>&1
    Write-Host "   ✅ pg_dump: $pgDumpVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ pg_dump not found in PATH" -ForegroundColor Red
    Write-Host "      Add PostgreSQL bin directory to PATH" -ForegroundColor Yellow
}

try {
    $psqlVersion = & psql --version 2>&1
    Write-Host "   ✅ psql: $psqlVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ psql not found in PATH" -ForegroundColor Red
    Write-Host "      Add PostgreSQL bin directory to PATH" -ForegroundColor Yellow
}

# Test 3: Check database connectivity
Write-Host "`n🔍 Test 3: Testing database connectivity..." -ForegroundColor Cyan

$env:PGPASSWORD = "hengmengly123"
try {
    $result = & psql -h localhost -p 5432 -U postgres -d ecommerce_db -c "SELECT 'Connection successful' as status;" -t 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Database connection successful" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Database connection failed: $result" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Database connection error: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

# Test 4: Check directory structure
Write-Host "`n🔍 Test 4: Checking directory structure..." -ForegroundColor Cyan

$directories = @($backupDir, $logDir)
foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Host "   ✅ Directory exists: $(Split-Path $dir -Leaf)" -ForegroundColor Green
    } else {
        try {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "   ✅ Created directory: $(Split-Path $dir -Leaf)" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ Cannot create directory: $(Split-Path $dir -Leaf)" -ForegroundColor Red
        }
    }
}

# Test 5: Run a test backup
Write-Host "`n🔍 Test 5: Running test backup..." -ForegroundColor Cyan

try {
    $testResult = & powershell.exe -ExecutionPolicy Bypass -File "$scriptsDir\scheduled_backup.ps1" -BackupType "schema" -RetentionDays 1 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Test backup completed successfully" -ForegroundColor Green
        
        # Check if backup file was created
        $latestBackup = Get-ChildItem "$backupDir\schema_backup_*.sql" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestBackup) {
            $sizeMB = [math]::Round($latestBackup.Length / 1MB, 2)
            Write-Host "   ✅ Backup file created: $($latestBackup.Name) ($sizeMB MB)" -ForegroundColor Green
        }
    } else {
        Write-Host "   ❌ Test backup failed" -ForegroundColor Red
        Write-Host "      Error: $testResult" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Test backup error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Check Node.js dependencies
Write-Host "`n🔍 Test 6: Checking Node.js dependencies..." -ForegroundColor Cyan

try {
    Push-Location $backendDir
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    
    if ($packageJson.dependencies."node-cron") {
        Write-Host "   ✅ node-cron dependency found" -ForegroundColor Green
    } else {
        Write-Host "   ❌ node-cron dependency missing" -ForegroundColor Red
    }
    
    # Check if node_modules exists
    if (Test-Path "node_modules\node-cron") {
        Write-Host "   ✅ node-cron installed" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  node-cron not installed, run 'npm install'" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Error checking Node.js dependencies: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Pop-Location
}

# Test 7: Check Windows Task Scheduler tasks (if running as admin)
Write-Host "`n🔍 Test 7: Checking Windows Task Scheduler..." -ForegroundColor Cyan

if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    try {
        $tasks = Get-ScheduledTask | Where-Object {$_.TaskName -like 'DatabaseBackup*'}
        if ($tasks.Count -gt 0) {
            Write-Host "   ✅ Found $($tasks.Count) backup task(s):" -ForegroundColor Green
            foreach ($task in $tasks) {
                $state = $task.State
                $stateColor = if ($state -eq "Ready") { "Green" } else { "Yellow" }
                Write-Host "      • $($task.TaskName): $state" -ForegroundColor $stateColor
            }
        } else {
            Write-Host "   ⚠️  No backup tasks found" -ForegroundColor Yellow
            Write-Host "      Run setup_scheduled_backups.ps1 as Administrator to create tasks" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "   ❌ Error checking scheduled tasks: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "   ⚠️  Not running as Administrator, cannot check scheduled tasks" -ForegroundColor Yellow
    Write-Host "      Re-run this script as Administrator for full testing" -ForegroundColor Cyan
}

# Summary
Write-Host "`n📋 Test Summary" -ForegroundColor Green
Write-Host "=================" -ForegroundColor Yellow

Write-Host "`n🎯 Quick Actions:" -ForegroundColor Cyan
Write-Host "   • Install missing PostgreSQL tools if needed" -ForegroundColor White
Write-Host "   • Run 'npm install' in backend directory if node-cron is missing" -ForegroundColor White
Write-Host "   • Run setup_backup_scheduler.bat as Administrator to create scheduled tasks" -ForegroundColor White
Write-Host "   • Test the web interface: http://localhost:3000 → Database Tools → Scheduled Backups" -ForegroundColor White

Write-Host "`n📚 Documentation:" -ForegroundColor Cyan
Write-Host "   • QUICK_SETUP_SCHEDULED_BACKUPS.md - Detailed setup guide" -ForegroundColor White
Write-Host "   • SCHEDULED_BACKUP_GUIDE.md - Complete documentation" -ForegroundColor White
Write-Host "   • SYSTEM_DOCUMENTATION.md - Full system overview" -ForegroundColor White

Write-Host "`n✅ Testing completed!" -ForegroundColor Green
