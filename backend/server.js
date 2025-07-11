const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const cron = require('node-cron');
require('dotenv').config();

// Import routes
const userRoutes = require('./routes/users');
const databaseRoutes = require('./routes/database');
const analyticsRoutes = require('./routes/analytics');

// Import database configuration
require('./config/database');

// Import backup scheduler
const BackupScheduler = require('./services/backupScheduler');

const app = express();
const PORT = process.env.PORT || 3001;

// Trust proxy for rate limiting (fixes express-rate-limit warning)
app.set('trust proxy', 1);

// Security middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
        },
    },
}));

// CORS configuration
app.use(cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Compression middleware
app.use(compression());

// Rate limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
    message: {
        success: false,
        message: 'Too many requests from this IP, please try again later.'
    }
});

app.use('/api', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - IP: ${req.ip}`);
    next();
});

// Health check endpoints
app.get('/health', async (req, res) => {
    try {
        const { pool } = require('./config/database');
        
        // Test database connection
        const dbResult = await pool.query('SELECT 1 as healthy');
        
        res.json({
            success: true,
            message: 'Server is running',
            timestamp: new Date().toISOString(),
            environment: process.env.NODE_ENV,
            database: dbResult.rows[0].healthy === 1 ? 'connected' : 'disconnected',
            uptime: process.uptime()
        });
    } catch (error) {
        res.status(503).json({
            success: false,
            message: 'Health check failed',
            timestamp: new Date().toISOString(),
            environment: process.env.NODE_ENV,
            database: 'disconnected',
            error: error.message
        });
    }
});

app.get('/api/health', async (req, res) => {
    try {
        const { pool } = require('./config/database');
        
        // Test database connection
        const dbResult = await pool.query('SELECT 1 as healthy');
        
        res.json({
            success: true,
            message: 'API is healthy',
            timestamp: new Date().toISOString(),
            environment: process.env.NODE_ENV,
            database: dbResult.rows[0].healthy === 1 ? 'connected' : 'disconnected',
            uptime: process.uptime()
        });
    } catch (error) {
        res.status(503).json({
            success: false,
            message: 'API health check failed',
            timestamp: new Date().toISOString(),
            environment: process.env.NODE_ENV,
            database: 'disconnected',
            error: error.message
        });
    }
});

// API routes
app.use('/api/users', userRoutes);
app.use('/api/database', databaseRoutes);
app.use('/api/analytics', analyticsRoutes);

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'E-Commerce Database Administration API',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            users: '/api/users',
            documentation: '/api/docs'
        }
    });
});

// Add backup scheduler status endpoint (must be before 404 handler)
let backupScheduler = null;

if (process.env.ENABLE_SCHEDULED_BACKUPS !== 'false') {
    try {
        console.log('🕐 Initializing backup scheduler...');
        const BackupScheduler = require('./services/backupScheduler');
        backupScheduler = new BackupScheduler();
        console.log('✅ Backup scheduler initialized successfully');
    } catch (error) {
        console.error('❌ Failed to initialize backup scheduler:', error.message);
        console.error('   Scheduled backups will not be available');
    }
}

app.get('/api/backup/schedule', async (req, res) => {
    if (backupScheduler) {
        try {
            const data = await backupScheduler.getScheduleStatus();
            res.json({
                success: true,
                data: data
            });
        } catch (error) {
            console.error('Error getting schedule status:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to get schedule status'
            });
        }
    } else {
        res.json({
            success: false,
            message: 'Backup scheduler not available'
        });
    }
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint not found',
        requestedPath: req.originalUrl
    });
});

// Global error handler
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    
    res.status(error.status || 500).json({
        success: false,
        message: process.env.NODE_ENV === 'production' 
            ? 'Internal server error' 
            : error.message,
        ...(process.env.NODE_ENV !== 'production' && { stack: error.stack })
    });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received. Shutting down gracefully...');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received. Shutting down gracefully...');
    process.exit(0);
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`📡 API Base URL: http://localhost:${PORT}/api`);
    console.log(`🏥 Health Check: http://localhost:${PORT}/health`);
});

module.exports = app;
