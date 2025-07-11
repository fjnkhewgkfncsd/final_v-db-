# Safe File Cleanup Script
# This script removes unnecessary development, test, and debug files

Write-Host "[INFO] Starting safe file cleanup..." -ForegroundColor Yellow

# Navigate to project root
$PROJECT_ROOT = "D:\year2\year2_term3\DatabaseAdmin\project_db(v2)"
Set-Location $PROJECT_ROOT

# Debug files
$debugFiles = @(
    "debug_endpoints.py",
    "debug_login.py", 
    "debug_performance_fields.py",
    "debug_recent_queries.py",
    "debug_backup_restore_issue.py",
    "debug_restore_issue.py",
    "debug_restore_router.py"
)

# Demo files
$demoFiles = @(
    "demo_recent_queries.py",
    "demo_emergency_recovery.py",
    "demo_python_backup_restore.py"
)

# Test files
$testFiles = @(
    "test_demo_credentials.py",
    "test_demo_login.py",
    "test_frontend_proxy.py",
    "test_monitoring_fixed.py",
    "test_monitoring_visibility.py",
    "test_system.py",
    "test_updated_credentials.py",
    "test-all-real-features.js",
    "test_restore.py",
    "test_query_console.py",
    "test_query_stats.py",
    "test_recent_queries.py",
    "test_4_user_restore.py",
    "test_all_backup_restore_methods.py",
    "test_complete_integration.py",
    "test_complete_system.py",
    "test_data_restore.py",
    "test_database_down_scenario.py",
    "test_db_connection.py",
    "test_emergency_api.py",
    "test_emergency_capability.py",
    "test_emergency_recovery.py",
    "test_final_restore.py",
    "test_full_restore.py",
    "test_improved_restore.py",
    "test_main_restore_final.py",
    "test_main_system_restore.py",
    "test_multiple_backups.py",
    "test_python_backup_restore.py",
    "test_restore_10k_fixed.py",
    "test_restore_4_users.py",
    "test_restore_comprehensive.py",
    "test_restore_demo.py",
    "test_restore_functionality.py",
    "test_restore_with_10k_users.py",
    "test_safe_restore.py",
    "test_simple_restore.py",
    "test_specific_backup_restore.py"
)

# Analysis files
$analysisFiles = @(
    "analyze_and_test_restore.py",
    "analyze_copy_vs_insert.py",
    "backup_format_analysis.py",
    "detailed_restore_analysis.py",
    "direct_backup_analysis.py",
    "final_restore_diagnosis.py",
    "diagnose_backup_restore_issue.py",
    "diagnose_restore_issue.py",
    "diagnose_restore_issues.py",
    "verify_backup_compatibility.py",
    "verify_emergency_restore.py",
    "verify_recovery.py",
    "verify_restore_fix.py"
)

# Utility files
$utilityFiles = @(
    "extract_user_data.py",
    "find_4_user_backup.py",
    "generate_more_users.py",
    "generate_restore_flowchart.py",
    "show_insert_generation.py",
    "safe_backup_list.py",
    "manual_restore_test.py",
    "proper_restore.py",
    "fix_restore_issue.py",
    "reset_admin_password.py",
    "get_credentials.js",
    "clear_rate_limit.js",
    "simple_python_backup_test.py",
    "simple_python_restore_test.py",
    "simple_restore_test.py",
    "quick_test.py",
    "quick_api_test.py",
    "quick_restore_test.py",
    "performance_test.py",
    "test_performance_comprehensive.py",
    "test_performance_fix.py",
    "final_system_validation.py",
    "system_health_check.py",
    "prove_real_tracking.py",
    "test_queries.sql"
)

# Docker files (if not using Docker)
$dockerFiles = @(
    "docker-compose.yml",
    "backend\Dockerfile",
    "frontend\Dockerfile"
)

# Function to safely delete files
function Remove-SafeFiles {
    param([array]$files, [string]$category)
    
    Write-Host "[INFO] Removing $category files..." -ForegroundColor Cyan
    $removed = 0
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            try {
                Remove-Item $file -Force
                Write-Host "   [SUCCESS] Removed: $file" -ForegroundColor Green
                $removed++
            } catch {
                Write-Host "   [ERROR] Failed to remove: $file" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "   [SUMMARY] Removed $removed/$($files.Count) $category files" -ForegroundColor Gray
    Write-Host ""
}

# Execute cleanup
Remove-SafeFiles $debugFiles "debug"
Remove-SafeFiles $demoFiles "demo"  
Remove-SafeFiles $testFiles "test"
Remove-SafeFiles $analysisFiles "analysis"
Remove-SafeFiles $utilityFiles "utility"

Write-Host "[INFO] Docker files (only remove if not using Docker):" -ForegroundColor Yellow
foreach ($file in $dockerFiles) {
    if (Test-Path $file) {
        Write-Host "   [FOUND] File: $file" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "[INFO] Old backup files cleanup (June backups):" -ForegroundColor Yellow
$oldBackups = Get-ChildItem "backups\*2025-06-*" -ErrorAction SilentlyContinue
if ($oldBackups) {
    Write-Host "   [FOUND] $($oldBackups.Count) old backup files" -ForegroundColor Gray
    Write-Host "   [TIP] Run this to remove them: Remove-Item 'backups\*2025-06-*' -Force" -ForegroundColor Cyan
} else {
    Write-Host "   [SUCCESS] No old backup files found" -ForegroundColor Green
}

Write-Host ""
Write-Host "[SUCCESS] Safe file cleanup completed!" -ForegroundColor Green
Write-Host "[TIP] Review the removed files and commit changes to Git if satisfied." -ForegroundColor Cyan
