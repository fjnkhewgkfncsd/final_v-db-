const cron = require('node-cron');
const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

class BackupScheduler {
    constructor() {
        this.backupDir = path.join(__dirname, '..', 'backups');
        this.logDir = path.join(__dirname, '..', 'logs');
        this.dbConfig = {
            host: process.env.DB_HOST || 'localhost',
            port: process.env.DB_PORT || '5432',
            database: process.env.DB_NAME || 'ecommerce_db',
            user: process.env.DB_USER || 'postgres',
            password: process.env.DB_PASSWORD || 'hengmengly123'
        };
        
        this.ensureDirectories();
        this.setupSchedules();
    }

    async ensureDirectories() {
        try {
            await fs.mkdir(this.backupDir, { recursive: true });
            await fs.mkdir(this.logDir, { recursive: true });
        } catch (error) {
            console.error('Failed to create directories:', error);
        }
    }

    setupSchedules() {
        console.log('🕐 Setting up daily backup schedule...');

        // Daily backup at 4:15 AM
        cron.schedule('15 4 * * *', () => {
            this.performBackup('daily', 'complete', 30); // Keep 30 days of daily backups
        }, {
            scheduled: true,
            timezone: 'America/New_York' // Adjust to your timezone
        });

        console.log('✅ Daily backup schedule configured:');
        console.log('   • Daily backups: 4:15 AM (30-day retention)');
    }

    async performBackup(schedule, type, retentionDays) {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
        const filename = `${schedule}_backup_${timestamp}.sql`;
        const filepath = path.join(this.backupDir, filename);
        const logFile = path.join(this.logDir, `backup_${new Date().toISOString().slice(0, 10)}.log`);

        try {
            await this.log(logFile, `Starting ${schedule} backup (${type})`);

            // Build pg_dump arguments
            const args = [
                '-h', this.dbConfig.host,
                '-p', this.dbConfig.port,
                '-U', this.dbConfig.user,
                '-d', this.dbConfig.database,
                '-f', filepath,
                '--verbose'
            ];

            if (type === 'schema') {
                args.push('--schema-only');
            } else if (type === 'data') {
                args.push('--data-only');
            } else {
                args.push('--no-owner', '--no-privileges');
            }

            // Execute pg_dump
            const success = await this.executePgDump(args, logFile);
            if (success) {
                // Verify backup
                const stats = await fs.stat(filepath);
                const sizeMB = (stats.size / (1024 * 1024)).toFixed(2);

                await this.log(logFile, `Backup completed successfully: ${filename} (${sizeMB} MB)`);

                // Update backup registry
                await this.updateBackupRegistry({
                    filename,
                    filepath,
                    type,
                    schedule,
                    size: stats.size,
                    created_at: new Date().toISOString(),
                    created_by: 'Scheduled Task',
                    status: 'completed'
                });

                // Cleanup old backups
                await this.cleanupOldBackups(schedule, retentionDays, logFile);

            } else {
                await this.log(logFile, `Backup failed: ${filename}`, 'ERROR');
            }

        } catch (error) {
            await this.log(logFile, `Backup error: ${error.message}`, 'ERROR');
        }
    }

    async executePgDump(args, logFile) {
        return new Promise((resolve) => {
            const env = { ...process.env, PGPASSWORD: this.dbConfig.password };
            const pgDump = spawn('pg_dump', args, { env });

            let output = '';
            let errorOutput = '';

            pgDump.stdout.on('data', (data) => {
                output += data.toString();
            });

            pgDump.stderr.on('data', (data) => {
                errorOutput += data.toString();
            });

            pgDump.on('close', async (code) => {
                if (code === 0) {
                    await this.log(logFile, 'pg_dump completed successfully');
                    resolve(true);
                } else {
                    await this.log(logFile, `pg_dump failed with code ${code}: ${errorOutput}`, 'ERROR');
                    resolve(false);
                }
            });

            pgDump.on('error', async (error) => {
                await this.log(logFile, `pg_dump process error: ${error.message}`, 'ERROR');
                resolve(false);
            });
        });
    }

    async updateBackupRegistry(backupInfo) {
        const registryFile = path.join(this.backupDir, 'backup_registry.json');
        
        try {
            let registry = [];
            
            try {
                const data = await fs.readFile(registryFile, 'utf8');
                registry = JSON.parse(data);
            } catch (error) {
                // File doesn't exist or is invalid, start fresh
                console.error('Failed to read backup registry file:', error);
            }

            registry.push(backupInfo);
            await fs.writeFile(registryFile, JSON.stringify(registry, null, 2));

        } catch (error) {
            console.error('Failed to update backup registry:', error);
        }
    }

    async cleanupOldBackups(schedule, retentionDays, logFile) {
        try {
            const cutoffDate = new Date();
            cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

            const files = await fs.readdir(this.backupDir);
            const backupFiles = files.filter(file => 
                file.startsWith(`${schedule}_backup_`) && file.endsWith('.sql')
            );

            let deletedCount = 0;

            for (const file of backupFiles) {
                const filepath = path.join(this.backupDir, file);
                const stats = await fs.stat(filepath);

                if (stats.mtime < cutoffDate) {
                    await fs.unlink(filepath);
                    await this.log(logFile, `Deleted old backup: ${file}`);
                    deletedCount++;
                }
            }

            if (deletedCount > 0) {
                await this.log(logFile, `Cleanup completed: deleted ${deletedCount} old backup(s)`);
            }

        } catch (error) {
            await this.log(logFile, `Cleanup error: ${error.message}`, 'WARNING');
        }
    }

    async log(logFile, message, level = 'INFO') {
        const timestamp = new Date().toISOString();
        const logEntry = `${timestamp} [${level}] ${message}\n`;
        
        console.log(`[BackupScheduler] ${logEntry.trim()}`);
        
        try {
            await fs.appendFile(logFile, logEntry);
        } catch (error) {
            console.error('Failed to write to log file:', error);
        }
    }

    // Get backup status for API endpoints
    async getScheduleStatus() {
        const dailySchedule = {
            name: 'Daily Backup',
            cron: '15 4 * * *',
            retention: '30 days',
            type: 'complete',
            description: 'Daily at 4:15 AM'
        };

        const nextRun = this.getNextCronRun(dailySchedule.cron);
        const lastBackupTime = await this.getLastBackupTime();

        return {
            active: true,
            schedule: {
                ...dailySchedule,
                nextRun: nextRun,
                timeUntilNext: this.getTimeUntilNext(nextRun)
            },
            lastRun: lastBackupTime,
            nextRun: nextRun,
            timeUntilNext: this.getTimeUntilNext(nextRun),
            backupDirectory: this.backupDir,
            logDirectory: this.logDir,
            databaseConfig: {
                host: this.dbConfig.host,
                port: this.dbConfig.port,
                database: this.dbConfig.database,
                user: this.dbConfig.user
                // Note: password is intentionally excluded for security
            },
            systemInfo: {
                nodeVersion: process.version,
                platform: process.platform,
                uptime: process.uptime(),
                timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
            }
        };
    }

    getNextScheduledRun() {
        // Calculate next scheduled run (improved calculation)
        const now = new Date();
        const schedules = [
            { cron: '0 1 * * *', name: 'Schema' },   // 1:00 AM daily
            { cron: '15 4 * * *', name: 'Daily' },    // 4:15 AM daily
            { cron: '0 3 * * 0', name: 'Weekly' },   // 3:00 AM Sunday
            { cron: '0 4 1 * *', name: 'Monthly' }   // 4:00 AM 1st of month
        ];

        let nextRun = null;
        let nextSchedule = null;

        schedules.forEach(schedule => {
            const nextTime = this.getNextCronRun(schedule.cron);
            if (!nextRun || nextTime < nextRun) {
                nextRun = nextTime;
                nextSchedule = schedule.name;
            }
        });

        return {
            time: nextRun,
            schedule: nextSchedule
        };
    }

    getNextCronRun(cronExpression) {
        try {
            // Simple cron parser for basic expressions
            const [minute, hour, day, month, dayOfWeek] = cronExpression.split(' ');
            const now = new Date();
            const next = new Date(now);

            // Reset seconds and milliseconds
            next.setSeconds(0, 0);
            next.setMinutes(parseInt(minute) || 0);
            next.setHours(parseInt(hour) || 0);

            // Handle daily schedules
            if (day === '*' && month === '*' && dayOfWeek === '*') {
                if (next <= now) {
                    next.setDate(next.getDate() + 1);
                }
                return next;
            }

            // Handle weekly schedules (Sunday = 0)
            if (day === '*' && month === '*' && dayOfWeek !== '*') {
                const targetDay = parseInt(dayOfWeek) || 0;
                const currentDay = next.getDay();
                let daysToAdd = targetDay - currentDay;
                
                if (daysToAdd <= 0 || (daysToAdd === 0 && next <= now)) {
                    daysToAdd += 7;
                }
                
                next.setDate(next.getDate() + daysToAdd);
                return next;
            }

            // Handle monthly schedules
            if (day !== '*' && month === '*') {
                const targetDay = parseInt(day) || 1;
                next.setDate(targetDay);
                
                if (next <= now) {
                    next.setMonth(next.getMonth() + 1);
                    next.setDate(targetDay); // Reset day in case month overflow
                }
                return next;
            }

            // Fallback for complex expressions
            const fallback = new Date(now.getTime() + 24 * 60 * 60 * 1000); // Tomorrow
            return fallback;
        } catch (error) {
            console.error('Error calculating next cron run:', error);
            // Return tomorrow as fallback
            return new Date(Date.now() + 24 * 60 * 60 * 1000);
        }
    }

    getCronDescription(cronExpression) {
        const descriptions = {
            '0 1 * * *': 'Daily at 1:00 AM',
            '15 4 * * *': 'Daily at 4:15 AM',
            '0 3 * * 0': 'Every Sunday at 3:00 AM',
            '0 4 1 * *': 'Monthly on the 1st at 4:00 AM'
        };
        
        return descriptions[cronExpression] || cronExpression;
    }

    async getLastBackupTime() {
        try {
            const registryFile = path.join(this.backupDir, 'backup_registry.json');
            const data = await fs.readFile(registryFile, 'utf8');
            const registry = JSON.parse(data);
            
            if (registry.length > 0) {
                const lastBackup = registry[registry.length - 1];
                return new Date(lastBackup.created_at);
            }
        } catch (error) {
            // Registry file doesn't exist or is invalid
        }
        
        return null;
    }

    getTimeUntilNext(nextRunDate) {
        if (!nextRunDate) return null;
        
        const now = new Date();
        const timeDiff = nextRunDate.getTime() - now.getTime();
        
        if (timeDiff <= 0) return { expired: true };
        
        const hours = Math.floor(timeDiff / (1000 * 60 * 60));
        const minutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((timeDiff % (1000 * 60)) / 1000);
        
        return {
            hours,
            minutes, 
            seconds,
            totalMinutes: Math.floor(timeDiff / (1000 * 60)),
            totalSeconds: Math.floor(timeDiff / 1000),
            formatted: this.formatTimeUntil(hours, minutes, seconds)
        };
    }

    formatTimeUntil(hours, minutes, seconds) {
        if (hours > 24) {
            const days = Math.floor(hours / 24);
            const remainingHours = hours % 24;
            return `${days} day${days !== 1 ? 's' : ''} ${remainingHours} hour${remainingHours !== 1 ? 's' : ''}`;
        } else if (hours > 0) {
            return `${hours} hour${hours !== 1 ? 's' : ''} ${minutes} minute${minutes !== 1 ? 's' : ''}`;
        } else if (minutes > 0) {
            return `${minutes} minute${minutes !== 1 ? 's' : ''} ${seconds} second${seconds !== 1 ? 's' : ''}`;
        } else {
            return `${seconds} second${seconds !== 1 ? 's' : ''}`;
        }
    }
}

module.exports = BackupScheduler;
