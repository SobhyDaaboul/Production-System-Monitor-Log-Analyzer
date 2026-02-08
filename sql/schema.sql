-- Drop tables if they exist (for fresh start)
DROP TABLE IF EXISTS health_reports CASCADE;
DROP TABLE IF EXISTS issues CASCADE;
DROP TABLE IF EXISTS system_metrics CASCADE;
DROP TABLE IF EXISTS log_entries CASCADE;

-- ============================================
-- TABLE 1: log_entries
-- Purpose: Store every parsed log line
-- ============================================
CREATE TABLE log_entries (
    id SERIAL PRIMARY KEY,
    -- SERIAL = auto-incrementing integer
    
    log_timestamp TIMESTAMP NOT NULL,
    -- When the log event happened
    
    log_level VARCHAR(10) NOT NULL,
    -- ERROR, WARN, INFO, DEBUG
    
    component VARCHAR(50) NOT NULL,
    -- Which part of the app? (Database, API, Auth, etc.)
    
    message TEXT NOT NULL,
    -- The actual log message
    
    response_time INTEGER,
    -- If it's a performance log, how many milliseconds?
    -- NULL if not applicable
    
    error_code VARCHAR(20),
    -- HTTP status code or custom error code
    
    user_id INTEGER,
    -- Which user triggered this? (if applicable)
    
    created_at TIMESTAMP DEFAULT NOW()
    -- When we inserted this into the database
);

-- Index for faster queries
-- "Show me all ERROR logs from yesterday"
CREATE INDEX idx_log_level ON log_entries(log_level);
CREATE INDEX idx_log_timestamp ON log_entries(log_timestamp);
CREATE INDEX idx_component ON log_entries(component);

-- ============================================
-- TABLE 2: system_metrics
-- Purpose: Store system health snapshots
-- ============================================
CREATE TABLE system_metrics (
    id SERIAL PRIMARY KEY,
    
    metric_timestamp TIMESTAMP NOT NULL,
    -- When we took this measurement
    
    cpu_usage DECIMAL(5,2) NOT NULL,
    -- Percentage: 0.00 to 100.00
    -- DECIMAL(5,2) means: 5 total digits, 2 after decimal
    -- Examples: 45.67, 99.99, 100.00
    
    memory_usage DECIMAL(5,2) NOT NULL,
    -- Same format as CPU
    
    memory_total_mb INTEGER NOT NULL,
    -- Total RAM in megabytes
    
    memory_used_mb INTEGER NOT NULL,
    -- Used RAM in megabytes
    
    disk_usage DECIMAL(5,2) NOT NULL,
    -- Percentage used
    
    disk_total_gb INTEGER NOT NULL,
    -- Total disk in gigabytes
    
    disk_used_gb INTEGER NOT NULL,
    -- Used disk in gigabytes
    
    active_processes INTEGER NOT NULL,
    -- How many processes running?
    
    load_average DECIMAL(4,2),
    -- Linux load average (1-minute)
    -- Tells you if system is overloaded
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_metric_timestamp ON system_metrics(metric_timestamp);

-- ============================================
-- TABLE 3: issues
-- Purpose: Group similar problems together
-- ============================================
CREATE TABLE issues (
    id SERIAL PRIMARY KEY,
    
    issue_type VARCHAR(50) NOT NULL,
    -- Examples: "Database Timeout", "API Error 500", "High CPU"
    
    severity VARCHAR(20) NOT NULL,
    -- CRITICAL, HIGH, MEDIUM, LOW
    
    description TEXT NOT NULL,
    -- Detailed description of the problem
    
    component VARCHAR(50),
    -- Which part of the system?
    
    first_seen TIMESTAMP NOT NULL,
    -- When did this issue first appear?
    
    last_seen TIMESTAMP NOT NULL,
    -- Most recent occurrence
    
    occurrence_count INTEGER DEFAULT 1,
    -- How many times has this happened?
    
    resolved BOOLEAN DEFAULT FALSE,
    -- Has someone fixed it?
    
    resolved_at TIMESTAMP,
    -- When was it marked as resolved?
    
    resolved_by VARCHAR(50),
    -- Who fixed it?
    
    notes TEXT
    -- Any additional comments
);

CREATE INDEX idx_issue_severity ON issues(severity);
CREATE INDEX idx_issue_resolved ON issues(resolved);

-- ============================================
-- TABLE 4: health_reports
-- Purpose: Daily summaries for management
-- ============================================
CREATE TABLE health_reports (
    id SERIAL PRIMARY KEY,
    
    report_date DATE NOT NULL UNIQUE,
    -- One report per day
    
    total_log_entries INTEGER,
    total_errors INTEGER,
    total_warnings INTEGER,
    
    avg_cpu_usage DECIMAL(5,2),
    max_cpu_usage DECIMAL(5,2),
    
    avg_memory_usage DECIMAL(5,2),
    max_memory_usage DECIMAL(5,2),
    
    avg_response_time INTEGER,
    -- Average API response time in ms
    
    max_response_time INTEGER,
    -- Slowest response time
    
    critical_issues_count INTEGER,
    high_issues_count INTEGER,
    
    system_health_score INTEGER,
    -- Overall score 0-100 (we'll calculate this)
    
    generated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_report_date ON health_reports(report_date);