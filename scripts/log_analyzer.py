#!/home/sobhy/production-system-monitor/venv/bin/python3
"""
LOG ANALYZER
Purpose: Parse application logs, detect issues, store in database
This is the "detective" that finds problems in your logs
"""

import re
import os
import time
import yaml
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import psycopg2
from psycopg2.extras import execute_values

# ============================================
# CONFIGURATION
# ============================================

def load_config():
    """Load configuration from YAML file"""
    with open("config/config.yaml", "r") as f:
        return yaml.safe_load(f)

CONFIG = load_config()

# ============================================
# DATABASE CONNECTION
# ============================================

def get_db_connection():
    """Create database connection"""
    try:
        conn = psycopg2.connect(
            host=CONFIG["database"]["host"],
            port=CONFIG["database"]["port"],
            database=CONFIG["database"]["name"],
            user=CONFIG["database"]["user"],
            password=CONFIG["database"]["password"]
        )
        return conn
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return None

# ============================================
# LOG PARSING
# ============================================

# Regular expression to parse log lines
# Format: TIMESTAMP LEVEL [COMPONENT] MESSAGE
LOG_PATTERN = re.compile(
    r"(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+"
    r"(?P<level>\w+)\s+"
    r"\[(?P<component>[^\]]+)\]\s+"
    r"(?P<message>.*)"
)

# Pattern to extract response times from messages
TIME_PATTERN = re.compile(r"(\d+)ms")

# Pattern to extract user IDs
USER_ID_PATTERN = re.compile(r"user_id[=:](\d+)")

# Pattern to extract error codes
ERROR_CODE_PATTERN = re.compile(r"(404|500|503|\d{3})")

def parse_log_line(line: str) -> Optional[Dict]:
    """
    Parse a single log line into structured data
    
    Args:
        line: Raw log line
        
    Returns:
        Dictionary with parsed fields, or None if parsing fails
    """
    match = LOG_PATTERN.match(line.strip())
    
    if not match:
        return None
    
    # Extract basic fields
    data = {
        "timestamp": match.group("timestamp"),
        "level": match.group("level"),
        "component": match.group("component"),
        "message": match.group("message")
    }
    
    # Extract response time if present
    time_match = TIME_PATTERN.search(data["message"])
    if time_match:
        data["response_time"] = int(time_match.group(1))
    else:
        data["response_time"] = None
    
    # Extract user ID if present
    user_match = USER_ID_PATTERN.search(data["message"])
    if user_match:
        data["user_id"] = int(user_match.group(1))
    else:
        data["user_id"] = None
    
    # Extract error code if present
    error_match = ERROR_CODE_PATTERN.search(data["message"])
    if error_match:
        data["error_code"] = error_match.group(1)
    else:
        data["error_code"] = None
    
    return data

# ============================================
# DATABASE OPERATIONS
# ============================================

def insert_log_entries(conn, entries: List[Dict]):
    """
    Bulk insert log entries into database
    
    Args:
        conn: Database connection
        entries: List of parsed log entries
    """
    if not entries:
        return
    
    # Prepare data for bulk insert
    values = [
        (
            e["timestamp"],
            e["level"],
            e["component"],
            e["message"],
            e["response_time"],
            e["error_code"],
            e["user_id"]
        )
        for e in entries
    ]
    
    query = """
        INSERT INTO log_entries 
        (log_timestamp, log_level, component, message, response_time, error_code, user_id)
        VALUES %s
    """
    
    try:
        cursor = conn.cursor()
        execute_values(cursor, query, values)
        conn.commit()
        cursor.close()
        print(f"  ✅ Inserted {len(entries)} log entries")
    except Exception as e:
        print(f"  ❌ Insert failed: {e}")
        conn.rollback()

# ============================================
# ISSUE DETECTION
# ============================================

def detect_issues(conn, entries: List[Dict]):
    """
    Analyze log entries and detect issues
    
    Issues to detect:
    1. High error rate
    2. Slow response times
    3. Database timeouts
    4. Failed authentications
    5. System resource problems
    """
    issues_to_insert = []
    
    # Group entries by component and level
    by_component = {}
    errors = []
    slow_responses = []
    
    for entry in entries:
        component = entry["component"]
        if component not in by_component:
            by_component[component] = []
        by_component[component].append(entry)
        
        # Collect errors
        if entry["level"] == "ERROR":
            errors.append(entry)
        
        # Collect slow responses (> 3000ms)
        if entry["response_time"] and entry["response_time"] > 3000:
            slow_responses.append(entry)
    
    # ISSUE 1: High error rate per component
    for component, comp_entries in by_component.items():
        error_count = sum(1 for e in comp_entries if e["level"] == "ERROR")
        total_count = len(comp_entries)
        error_rate = (error_count / total_count * 100) if total_count > 0 else 0
        
        if error_rate > 10:  # More than 10% errors
            issues_to_insert.append({
                "issue_type": "High Error Rate",
                "severity": "HIGH" if error_rate > 20 else "MEDIUM",
                "description": f"{component} has {error_rate:.1f}% error rate ({error_count}/{total_count} entries)",
                "component": component,
                "occurrence_count": error_count
            })
    
    # ISSUE 2: Database timeouts
    db_timeouts = [
        e for e in errors 
        if e["component"] == "Database" and "timeout" in e["message"].lower()
    ]
    if len(db_timeouts) > 0:
        issues_to_insert.append({
            "issue_type": "Database Timeout",
            "severity": "CRITICAL" if len(db_timeouts) > 5 else "HIGH",
            "description": f"Database timeouts detected: {len(db_timeouts)} occurrences",
            "component": "Database",
            "occurrence_count": len(db_timeouts)
        })
    
    # ISSUE 3: Slow API responses
    if len(slow_responses) > 0:
        avg_time = sum(e["response_time"] for e in slow_responses) / len(slow_responses)
        issues_to_insert.append({
            "issue_type": "Slow Response Time",
            "severity": "MEDIUM",
            "description": f"Slow responses detected: {len(slow_responses)} requests averaging {avg_time:.0f}ms",
            "component": "API",
            "occurrence_count": len(slow_responses)
        })
    
    # ISSUE 4: Failed authentication attempts
    auth_failures = [
        e for e in errors 
        if e["component"] == "Auth" and ("failed" in e["message"].lower() or "invalid" in e["message"].lower())
    ]
    if len(auth_failures) > 5:
        issues_to_insert.append({
            "issue_type": "Authentication Failures",
            "severity": "HIGH",
            "description": f"Multiple failed authentication attempts: {len(auth_failures)} occurrences",
            "component": "Auth",
            "occurrence_count": len(auth_failures)
        })
    
    # Insert issues into database
    insert_issues(conn, issues_to_insert)

def insert_issues(conn, issues: List[Dict]):
    """
    Insert or update issues in database
    """
    if not issues:
        return
    
    cursor = conn.cursor()
    
    for issue in issues:
        # Check if similar issue already exists (not resolved, same type/component)
        cursor.execute("""
            SELECT id, occurrence_count, first_seen 
            FROM issues 
            WHERE issue_type = %s 
              AND component = %s 
              AND resolved = FALSE
            ORDER BY last_seen DESC
            LIMIT 1
        """, (issue["issue_type"], issue["component"]))
        
        existing = cursor.fetchone()
        
        if existing:
            # Update existing issue
            issue_id, old_count, first_seen = existing
            new_count = old_count + issue["occurrence_count"]
            
            cursor.execute("""
                UPDATE issues 
                SET last_seen = NOW(),
                    occurrence_count = %s,
                    severity = %s,
                    description = %s
                WHERE id = %s
            """, (new_count, issue["severity"], issue["description"], issue_id))
            
            print(f"  🔄 Updated issue #{issue_id}: {issue['issue_type']}")
        else:
            # Insert new issue
            cursor.execute("""
                INSERT INTO issues 
                (issue_type, severity, description, component, first_seen, last_seen, occurrence_count)
                VALUES (%s, %s, %s, %s, NOW(), NOW(), %s)
                RETURNING id
            """, (
                issue["issue_type"],
                issue["severity"],
                issue["description"],
                issue["component"],
                issue["occurrence_count"]
            ))
            
            issue_id = cursor.fetchone()[0]
            print(f"  🚨 New issue #{issue_id}: {issue['issue_type']} - {issue['severity']}")
    
    conn.commit()
    cursor.close()

# ============================================
# FILE MONITORING
# ============================================

def get_latest_log_file():
    """Find the most recent log file"""
    log_dir = CONFIG["logging"]["log_directory"]
    prefix = CONFIG["logging"]["log_file_prefix"]
    
    if not os.path.exists(log_dir):
        return None
    
    log_files = [
        f for f in os.listdir(log_dir)
        if f.startswith(prefix) and f.endswith(".log")
    ]
    
    if not log_files:
        return None
    
    # Get most recent file
    log_files.sort(reverse=True)
    return os.path.join(log_dir, log_files[0])

def tail_file(filepath, last_position=0):
    """
    Read new lines from file (like 'tail -f')
    
    Args:
        filepath: Path to log file
        last_position: File position from last read
        
    Returns:
        List of new lines, new file position
    """
    try:
        with open(filepath, "r") as f:
            # Seek to last position
            f.seek(last_position)
            
            # Read new lines
            new_lines = f.readlines()
            
            # Get new position
            new_position = f.tell()
            
            return new_lines, new_position
    except FileNotFoundError:
        return [], last_position

# ============================================
# MAIN LOOP
# ============================================

def main():
    """
    Main function: Monitor log files and analyze continuously
    """
    print("🚀 Starting log analyzer...")
    print("📊 Monitoring log files for issues...")
    print("⚠️  Press Ctrl+C to stop\n")
    
    # Get database connection
    conn = get_db_connection()
    if not conn:
        print("❌ Cannot connect to database. Exiting.")
        return
    
    last_position = 0
    current_file = None
    
    try:
        while True:
            # Check for latest log file
            log_file = get_latest_log_file()
            
            if not log_file:
                print("⏳ Waiting for log file...")
                time.sleep(5)
                continue
            
            # If file changed, reset position
            if log_file != current_file:
                print(f"📂 Now monitoring: {log_file}")
                current_file = log_file
                last_position = 0
            
            # Read new lines
            new_lines, last_position = tail_file(log_file, last_position)
            
            if new_lines:
                print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Processing {len(new_lines)} new log entries...")
                
                # Parse all lines
                parsed_entries = []
                for line in new_lines:
                    parsed = parse_log_line(line)
                    if parsed:
                        parsed_entries.append(parsed)
                
                if parsed_entries:
                    # Insert into database
                    insert_log_entries(conn, parsed_entries)
                    
                    # Detect issues
                    detect_issues(conn, parsed_entries)
            
            # Wait before next check
            time.sleep(5)
            
    except KeyboardInterrupt:
        print("\n\n✅ Stopped log analyzer")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()