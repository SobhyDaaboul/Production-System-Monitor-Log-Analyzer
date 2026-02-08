-- ============================================
-- ANALYSIS QUERIES FOR MONITORING SYSTEM
-- ============================================

-- QUERY 1: Error Summary (Last 24 Hours)
-- Purpose: Quick overview of all errors
-- ============================================
SELECT 
    component,
    COUNT(*) as error_count,
    COUNT(DISTINCT message) as unique_errors,
    MAX(log_timestamp) as last_error
FROM log_entries
WHERE log_level = 'ERROR'
  AND log_timestamp > NOW() - INTERVAL '24 hours'
GROUP BY component
ORDER BY error_count DESC;

-- QUERY 2: Slowest Components
-- Purpose: Which components have worst performance?
-- ============================================
SELECT 
    component,
    COUNT(*) as request_count,
    AVG(response_time) as avg_response_ms,
    MAX(response_time) as max_response_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time) as p95_response_ms
FROM log_entries
WHERE response_time IS NOT NULL
  AND log_timestamp > NOW() - INTERVAL '24 hours'
GROUP BY component
ORDER BY avg_response_ms DESC;

-- QUERY 3: Error Rate Trend (Hourly)
-- Purpose: Is error rate increasing or decreasing?
-- ============================================
SELECT 
    DATE_TRUNC('hour', log_timestamp) as hour,
    COUNT(*) as total_logs,
    SUM(CASE WHEN log_level = 'ERROR' THEN 1 ELSE 0 END) as errors,
    ROUND(100.0 * SUM(CASE WHEN log_level = 'ERROR' THEN 1 ELSE 0 END) / COUNT(*), 2) as error_rate_percent
FROM log_entries
WHERE log_timestamp > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;

-- QUERY 4: Most Problematic Users
-- Purpose: Which users experience most errors?
-- ============================================
SELECT 
    user_id,
    COUNT(*) as total_actions,
    SUM(CASE WHEN log_level = 'ERROR' THEN 1 ELSE 0 END) as errors,
    ROUND(100.0 * SUM(CASE WHEN log_level = 'ERROR' THEN 1 ELSE 0 END) / COUNT(*), 2) as error_rate_percent
FROM log_entries
WHERE user_id IS NOT NULL
  AND log_timestamp > NOW() - INTERVAL '24 hours'
GROUP BY user_id
HAVING SUM(CASE WHEN log_level = 'ERROR' THEN 1 ELSE 0 END) > 5
ORDER BY errors DESC
LIMIT 10;

-- QUERY 5: System Health Over Time
-- Purpose: CPU/Memory trends
-- ============================================
SELECT 
    DATE_TRUNC('hour', metric_timestamp) as hour,
    AVG(cpu_usage) as avg_cpu,
    MAX(cpu_usage) as max_cpu,
    AVG(memory_usage) as avg_memory,
    MAX(memory_usage) as max_memory,
    AVG(disk_usage) as avg_disk
FROM system_metrics
WHERE metric_timestamp > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;

-- QUERY 6: Active Issues (Not Resolved)
-- Purpose: What needs attention right now?
-- ============================================
SELECT 
    id,
    issue_type,
    severity,
    component,
    occurrence_count,
    first_seen,
    last_seen,
    AGE(NOW(), last_seen) as time_since_last_occurrence
FROM issues
WHERE resolved = FALSE
ORDER BY 
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END,
    last_seen DESC;

-- QUERY 7: Database Performance Issues
-- Purpose: Find slow/problematic queries
-- ============================================
SELECT 
    component,
    message,
    COUNT(*) as occurrence_count,
    AVG(response_time) as avg_time_ms,
    MAX(response_time) as max_time_ms
FROM log_entries
WHERE component = 'Database'
  AND (log_level = 'ERROR' OR log_level = 'WARN')
  AND log_timestamp > NOW() - INTERVAL '24 hours'
GROUP BY component, message
ORDER BY occurrence_count DESC
LIMIT 20;

-- QUERY 8: System Health Score Calculator
-- Purpose: Single number representing overall health
-- ============================================
WITH recent_metrics AS (
    SELECT 
        AVG(cpu_usage) as avg_cpu,
        AVG(memory_usage) as avg_memory,
        AVG(disk_usage) as avg_disk
    FROM system_metrics
    WHERE metric_timestamp > NOW() - INTERVAL '1 hour'
),
recent_errors AS (
    SELECT 
        COUNT(*) as error_count,
        (SELECT COUNT(*) FROM log_entries WHERE log_timestamp > NOW() - INTERVAL '1 hour') as total_count
    FROM log_entries
    WHERE log_level = 'ERROR'
      AND log_timestamp > NOW() - INTERVAL '1 hour'
)
SELECT 
    -- Health score: 100 = perfect, 0 = critical
    GREATEST(0, 
        100 
        - (CASE WHEN avg_cpu > 80 THEN 20 ELSE avg_cpu / 4 END)
        - (CASE WHEN avg_memory > 80 THEN 20 ELSE avg_memory / 4 END)
        - (CASE WHEN avg_disk > 90 THEN 30 ELSE avg_disk / 3 END)
        - (CASE WHEN error_count > 0 THEN (error_count::float / total_count * 100) ELSE 0 END)
    ) as health_score,
    avg_cpu,
    avg_memory,
    avg_disk,
    error_count,
    ROUND(100.0 * error_count / NULLIF(total_count, 0), 2) as error_rate_percent
FROM recent_metrics, recent_errors;