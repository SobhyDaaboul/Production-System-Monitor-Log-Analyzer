#!/bin/bash

# ============================================
# HEALTH CHECK SCRIPT
# Purpose: Generate daily summary report
# ============================================

DB_NAME="monitoring_db"
DB_USER="monitor_user"
DB_HOST="localhost"
export PGPASSWORD="monitor_pass"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           SYSTEM HEALTH REPORT - $(date +%Y-%m-%d)                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================
# SECTION 1: System Metrics
# ============================================
echo "📊 SYSTEM METRICS (Last 24 Hours)"
echo "────────────────────────────────────────"

psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "
SELECT 
    '  CPU Usage: ' || ROUND(AVG(cpu_usage), 1) || '% avg, ' || ROUND(MAX(cpu_usage), 1) || '% max',
    '  Memory:    ' || ROUND(AVG(memory_usage), 1) || '% avg, ' || ROUND(MAX(memory_usage), 1) || '% max',
    '  Disk:      ' || ROUND(AVG(disk_usage), 1) || '% avg, ' || ROUND(MAX(disk_usage), 1) || '% max'
FROM system_metrics
WHERE metric_timestamp > NOW() - INTERVAL '24 hours';
" | sed 's/^[ \t]*//'

echo ""

# ============================================
# SECTION 2: Log Statistics
# ============================================
echo "📝 LOG STATISTICS (Last 24 Hours)"
echo "────────────────────────────────────────"

psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "
SELECT 
    '  Total Logs: ' || COUNT(*),
    '  Errors:     ' || SUM(CASE WHEN log_level = 'ERROR' THEN 1 ELSE 0 END) || 
        ' (' || ROUND(100.0 * SUM(CASE WHEN log_level = 'ERROR' THEN 1 ELSE 0 END) / COUNT(*), 1) || '%)',
    '  Warnings:   ' || SUM(CASE WHEN log_level = 'WARN' THEN 1 ELSE 0 END) ||
        ' (' || ROUND(100.0 * SUM(CASE WHEN log_level = 'WARN' THEN 1 ELSE 0 END) / COUNT(*), 1) || '%)'
FROM log_entries
WHERE log_timestamp > NOW() - INTERVAL '24 hours';
" | sed 's/^[ \t]*//'

echo ""

# ============================================
# SECTION 3: Active Issues
# ============================================
echo "🚨 ACTIVE ISSUES"
echo "────────────────────────────────────────"

issue_count=$(psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM issues WHERE resolved = FALSE;" | tr -d ' ')

if [ "$issue_count" -eq "0" ]; then
    echo "  ✅ No active issues"
else
    psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
    SELECT 
        '  [' || severity || '] ' || issue_type as issue,
        component,
        occurrence_count as count,
        TO_CHAR(last_seen, 'HH24:MI') as last_seen
    FROM issues
    WHERE resolved = FALSE
    ORDER BY 
        CASE severity
            WHEN 'CRITICAL' THEN 1
            WHEN 'HIGH' THEN 2
            WHEN 'MEDIUM' THEN 3
            ELSE 4
        END;
    "
fi

echo ""

# ============================================
# SECTION 4: Top Errors
# ============================================
echo "❌ TOP 5 ERRORS (Last 24 Hours)"
echo "────────────────────────────────────────"

psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
SELECT 
    component,
    LEFT(message, 60) as error_message,
    COUNT(*) as count
FROM log_entries
WHERE log_level = 'ERROR'
  AND log_timestamp > NOW() - INTERVAL '24 hours'
GROUP BY component, message
ORDER BY count DESC
LIMIT 5;
"

echo ""

# ============================================
# SECTION 5: Performance Summary
# ============================================
echo "⚡ PERFORMANCE SUMMARY (Last 24 Hours)"
echo "────────────────────────────────────────"

psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
SELECT 
    component,
    COUNT(*) as requests,
    ROUND(AVG(response_time)) as avg_ms,
    ROUND(MAX(response_time)) as max_ms
FROM log_entries
WHERE response_time IS NOT NULL
  AND log_timestamp > NOW() - INTERVAL '24 hours'
GROUP BY component
ORDER BY avg_ms DESC;
"

echo ""

# ============================================
# SECTION 6: Health Score
# ============================================
echo "💯 OVERALL HEALTH SCORE"
echo "────────────────────────────────────────"

psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "
WITH recent_metrics AS (
    SELECT 
        AVG(cpu_usage) as avg_cpu,
        AVG(memory_usage) as avg_memory
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
    '  Health Score: ' || 
    ROUND(GREATEST(0, 
        100 
        - (avg_cpu / 2)
        - (avg_memory / 2)
        - (CASE WHEN error_count > 0 THEN (error_count::float / total_count * 50) ELSE 0 END)
    )) || '/100'
FROM recent_metrics, recent_errors;
" | sed 's/^[ \t]*//'

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Report generated at $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════════════"