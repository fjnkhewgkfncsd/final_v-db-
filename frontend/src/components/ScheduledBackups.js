import React, { useState, useEffect } from 'react';
import { ClockIcon, CalendarIcon, CheckCircleIcon, XCircleIcon } from '@heroicons/react/24/outline';

const ScheduledBackups = () => {
  const [scheduleStatus, setScheduleStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [countdown, setCountdown] = useState(null);

  useEffect(() => {
    fetchScheduleStatus();
    // Refresh every 30 seconds
    const interval = setInterval(fetchScheduleStatus, 30000);
    return () => clearInterval(interval);
  }, []);

  // Update countdown every second
  useEffect(() => {
    if (scheduleStatus?.timeUntilNext && !scheduleStatus.timeUntilNext.expired) {
      const countdownInterval = setInterval(() => {
        const now = new Date();
        const nextRun = new Date(scheduleStatus.nextRun);
        const timeDiff = nextRun.getTime() - now.getTime();
        
        if (timeDiff <= 0) {
          setCountdown({ expired: true });
          fetchScheduleStatus(); // Refresh data when backup should have run
        } else {
          const hours = Math.floor(timeDiff / (1000 * 60 * 60));
          const minutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60));
          const seconds = Math.floor((timeDiff % (1000 * 60)) / 1000);
          
          setCountdown({
            hours,
            minutes,
            seconds,
            formatted: formatTimeUntil(hours, minutes, seconds)
          });
        }
      }, 1000);

      return () => clearInterval(countdownInterval);
    }
  }, [scheduleStatus]);

  const fetchScheduleStatus = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/backup/schedule', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      const data = await response.json();
      if (data.success) {
        setScheduleStatus(data.data);
        setError(null);
      } else {
        setError(data.message);
      }
    } catch (error) {
      setError('Failed to fetch schedule status');
      console.error('Schedule status error:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatTimeUntil = (hours, minutes, seconds) => {
    if (hours > 24) {
      const days = Math.floor(hours / 24);
      const remainingHours = hours % 24;
      return `${days}d ${remainingHours}h`;
    } else if (hours > 0) {
      return `${hours}h ${minutes}m`;
    } else if (minutes > 0) {
      return `${minutes}m ${seconds}s`;
    } else {
      return `${seconds}s`;
    }
  };

  const formatNextRun = (dateString) => {
    if (!dateString) return 'Unknown';
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  const getScheduleColor = (isActive) => {
    return isActive ? 'text-green-600' : 'text-red-600';
  };

  const getScheduleIcon = (isActive) => {
    return isActive ? 
      <CheckCircleIcon className="h-5 w-5 text-green-600" /> : 
      <XCircleIcon className="h-5 w-5 text-red-600" />;
  };

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="space-y-3">
            <div className="h-4 bg-gray-200 rounded"></div>
            <div className="h-4 bg-gray-200 rounded w-5/6"></div>
            <div className="h-4 bg-gray-200 rounded w-4/6"></div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex items-center space-x-2 text-red-600 mb-4">
          <XCircleIcon className="h-6 w-6" />
          <h3 className="text-lg font-medium">Scheduled Backups Unavailable</h3>
        </div>
        <p className="text-gray-600 mb-4">{error}</p>
        <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4">
          <h4 className="font-medium text-yellow-800">Alternative Options:</h4>
          <ul className="mt-2 text-sm text-yellow-700 space-y-1">
            <li>• Use Windows Task Scheduler with PowerShell scripts</li>
            <li>• Run manual backups from the Database Tools tab</li>
            <li>• Set up external cron jobs on your system</li>
          </ul>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center space-x-2">
          <ClockIcon className="h-6 w-6 text-blue-600" />
          <h3 className="text-lg font-medium text-gray-900">Daily Scheduled Backups</h3>
        </div>
        <div className="flex items-center space-x-2">
          {getScheduleIcon(scheduleStatus?.active)}
          <span className={`text-sm font-medium ${getScheduleColor(scheduleStatus?.active)}`}>
            {scheduleStatus?.active ? 'Active' : 'Inactive'}
          </span>
        </div>
      </div>

      {scheduleStatus && (
        <div className="space-y-6">
          {/* Countdown Timer - Main Feature */}
          <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg p-6 border border-blue-200">
            <div className="text-center">
              <h4 className="text-lg font-semibold text-blue-900 mb-2">Next Backup In</h4>
              <div className="text-3xl font-bold text-blue-600 mb-2">
                {countdown?.expired ? 
                  "Backup Overdue" : 
                  countdown?.formatted || scheduleStatus.timeUntilNext?.formatted || "Calculating..."
                }
              </div>
              <p className="text-sm text-blue-700">
                Scheduled for: {formatNextRun(scheduleStatus.nextRun)}
              </p>
            </div>
          </div>

          {/* Schedule Overview */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="flex items-center space-x-2 mb-2">
                <CalendarIcon className="h-5 w-5 text-gray-600" />
                <span className="font-medium text-gray-900">Schedule</span>
              </div>
              <p className="text-gray-700">{scheduleStatus.schedule?.description}</p>
              <p className="text-xs text-gray-500 mt-1">({scheduleStatus.schedule?.cron})</p>
            </div>
            
            <div className="bg-green-50 rounded-lg p-4">
              <div className="flex items-center space-x-2 mb-2">
                <CheckCircleIcon className="h-5 w-5 text-green-600" />
                <span className="font-medium text-gray-900">Retention</span>
              </div>
              <p className="text-gray-700">{scheduleStatus.schedule?.retention}</p>
              <p className="text-xs text-gray-500 mt-1">Auto-cleanup old backups</p>
            </div>

            <div className="bg-purple-50 rounded-lg p-4">
              <div className="flex items-center space-x-2 mb-2">
                <ClockIcon className="h-5 w-5 text-purple-600" />
                <span className="font-medium text-gray-900">Last Run</span>
              </div>
              <p className="text-gray-700">
                {scheduleStatus.lastRun ? 
                  formatNextRun(scheduleStatus.lastRun) : 
                  'No previous backup'
                }
              </p>
            </div>
          </div>

          {/* Configuration Info */}
          <div className="bg-gray-50 rounded-lg p-4">
            <h4 className="font-medium text-gray-900 mb-3">Configuration</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <span className="font-medium text-gray-700">Backup Type:</span>
                <span className="ml-2 text-gray-600">Complete Database</span>
              </div>
              <div>
                <span className="font-medium text-gray-700">Storage:</span>
                <span className="ml-2 text-gray-600">{scheduleStatus.backupDirectory}</span>
              </div>
              <div>
                <span className="font-medium text-gray-700">Database:</span>
                <span className="ml-2 text-gray-600">
                  {scheduleStatus.databaseConfig?.database} @ {scheduleStatus.databaseConfig?.host}
                </span>
              </div>
              <div>
                <span className="font-medium text-gray-700">Timezone:</span>
                <span className="ml-2 text-gray-600">{scheduleStatus.systemInfo?.timezone}</span>
              </div>
            </div>
          </div>

          {/* Setup Instructions */}
          <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4">
            <h4 className="font-medium text-yellow-800 mb-2">Setup Instructions</h4>
            <div className="text-sm text-yellow-700 space-y-2">
              <div>
                <strong>Option 1: Application-Level Scheduling (Current)</strong>
                <ul className="mt-1 ml-4 space-y-1">
                  <li>• Automatic scheduling when backend server is running</li>
                  <li>• Logs stored in <code>logs/</code> directory</li>
                  <li>• Configure via environment variables</li>
                </ul>
              </div>
              <div>
                <strong>Option 2: Windows Task Scheduler (Recommended)</strong>
                <ul className="mt-1 ml-4 space-y-1">
                  <li>• Run <code>scripts/setup_scheduled_backups.ps1</code> as Administrator</li>
                  <li>• More reliable for production environments</li>
                  <li>• Backups run even when application is offline</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ScheduledBackups;
