const { Pool } = require('pg');
require('dotenv').config();

// Simple query statistics tracking
const queryStats = {
    totalQueries: 0,
    startTime: Date.now(),
    queryTimes: [],
    recentQueries: [] // Track recent query details for performance monitoring
};

// Database connection configuration
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'ecommerce_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    max: parseInt(process.env.DB_MAX_CONNECTIONS) || 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000, // Increased timeout
    // Connection retry settings
    keepAlive: true,
    keepAliveInitialDelayMillis: 10000,
};

// Create connection pool
const pool = new Pool(dbConfig);

// Handle pool errors with better resilience
pool.on('error', (err) => {
    console.error('🔄 Database pool error:', err.message);
    
    // Handle specific error codes
    if (err.code === '57P01') {
        console.log('📝 Connection terminated by administrator (likely during backup) - this is normal');
        // Don't exit the process, let the pool recover
        return;
    }
    
    // For other critical errors, log but try to recover
    console.error('🚨 Critical database error:', err);
    console.log('🔄 Attempting to recover database connections...');
    
    // Only exit for truly unrecoverable errors
    if (err.code === 'ECONNREFUSED' || err.code === 'ENOTFOUND') {
        console.error('💀 Database server unreachable. Exiting...');
        process.exit(-1);
    }
});

// Test connection
pool.connect()
    .then(client => {
        console.log('✅ Database connected successfully');
        client.release();
    })
    .catch(err => {
        console.error('❌ Database connection failed:', err.message);
    });

// Helper function to execute queries with error handling and retry logic
const query = async (text, params, retries = 3) => {
    const start = Date.now();
    
    for (let attempt = 1; attempt <= retries; attempt++) {
        try {
            const result = await pool.query(text, params);
            const duration = Date.now() - start;
            
            // Track query statistics
            queryStats.totalQueries++;
            queryStats.queryTimes.push({
                duration,
                timestamp: Date.now()
            });
            
            // Track recent queries with details for performance monitoring
            const queryPreview = text.length > 80 ? text.substring(0, 80) + '...' : text;
            queryStats.recentQueries.push({
                query: queryPreview,
                duration,
                timestamp: Date.now(),
                rowCount: result.rowCount || 0,
                status: duration < 50 ? 'Fast' : duration < 200 ? 'Moderate' : 'Slow'
            });
            
            // Keep only last 10 recent queries
            if (queryStats.recentQueries.length > 10) {
                queryStats.recentQueries = queryStats.recentQueries.slice(-10);
            }
            
            // Keep only last hour of query times
            const oneHourAgo = Date.now() - (60 * 60 * 1000);
            queryStats.queryTimes = queryStats.queryTimes.filter(q => q.timestamp > oneHourAgo);
            
            console.log(`Query executed in ${duration}ms:`, text.substring(0, 100));
            return result;
            
        } catch (error) {
            // Handle connection termination errors gracefully
            if (error.code === '57P01' && attempt < retries) {
                console.log(`🔄 Connection terminated (attempt ${attempt}/${retries}) - retrying...`);
                await new Promise(resolve => setTimeout(resolve, 1000 * attempt)); // Exponential backoff
                continue;
            }
            
            // For the last attempt or non-recoverable errors
            if (attempt === retries) {
                console.error(`❌ Query failed after ${retries} attempts:`, error.message);
                throw error;
            }
            
            console.log(`⚠️ Query error (attempt ${attempt}/${retries}):`, error.message);
            await new Promise(resolve => setTimeout(resolve, 500 * attempt));
        }
    }
};

// Helper function for transactions with retry logic
const transaction = async (callback, retries = 2) => {
    for (let attempt = 1; attempt <= retries; attempt++) {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            const result = await callback(client);
            await client.query('COMMIT');
            return result;
        } catch (error) {
            try {
                await client.query('ROLLBACK');
            } catch (rollbackError) {
                console.error('Rollback error:', rollbackError.message);
            }
            
            // Handle connection termination errors
            if (error.code === '57P01' && attempt < retries) {
                console.log(`🔄 Transaction connection terminated (attempt ${attempt}/${retries}) - retrying...`);
                await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
                continue;
            }
            
            if (attempt === retries) {
                throw error;
            }
            
        } finally {
            client.release();
        }
    }
};

// Get query statistics
const getQueryStats = () => {
    const currentTime = Date.now();
    const runtimeHours = (currentTime - queryStats.startTime) / (1000 * 60 * 60);
    const queriesPerHour = runtimeHours > 0 ? Math.round(queryStats.totalQueries / runtimeHours) : 0;
    
    // Calculate average query time from last hour
    const avgQueryTime = queryStats.queryTimes.length > 0 
        ? Math.round(queryStats.queryTimes.reduce((sum, q) => sum + q.duration, 0) / queryStats.queryTimes.length)
        : 0;
    
    return {
        total_queries: queryStats.totalQueries,
        queries_per_hour: queriesPerHour,
        queries_last_hour: queryStats.queryTimes.length,
        avg_query_time: avgQueryTime,
        runtime_hours: Math.round(runtimeHours * 10) / 10,
        recent_queries: queryStats.recentQueries.slice().reverse() // Most recent first
    };
};

module.exports = {
    pool,
    query,
    transaction,
    getQueryStats
};
