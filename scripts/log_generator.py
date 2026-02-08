#!/home/sobhy/production-system-monitor/venv/bin/python3
"""
LOG GENERATOR
Purpose: Simulate a production application writing log files
This creates realistic logs with errors, warnings, slow queries, etc.
"""

import random
import time
from datetime import datetime, timedelta
import os

# ============================================
# CONFIGURATION
# ============================================

LOG_DIR = "./logs"
LOG_LEVELS = ["INFO", "WARN", "ERROR", "DEBUG"]
COMPONENTS = ["Database", "API", "Auth", "Cache", "Queue", "Payment"]

# Probability weights for log levels
# INFO is most common, ERROR is rare
LEVEL_WEIGHTS = {
    "INFO": 70,   # 70% of logs
    "WARN": 20,   # 20% of logs
    "ERROR": 8,   # 8% of logs
    "DEBUG": 2    # 2% of logs
}

# ============================================
# MESSAGE TEMPLATES
# ============================================

# Different message types per component
MESSAGES = {
    "Database": {
        "INFO": [
            "Query executed successfully in {time}ms",
            "Connection pool: {pool} active connections",
            "Index scan completed: {rows} rows",
        ],
        "WARN": [
            "Slow query detected: {time}ms for SELECT statement",
            "Connection pool reaching limit: {pool}/100 connections",
            "Table lock held for {time}ms",
        ],
        "ERROR": [
            "Query timeout after {time}ms: {query}",
            "Connection failed: Unable to reach database server",
            "Deadlock detected on table users",
            "Max connections reached: 100/100",
        ],
    },
    "API": {
        "INFO": [
            "GET /api/users/{id} completed in {time}ms",
            "POST /api/orders completed in {time}ms",
            "Request processed: user_id={user_id}",
        ],
        "WARN": [
            "Slow response: {endpoint} took {time}ms",
            "Rate limit approaching: {count} requests in last minute",
            "Large payload detected: {size}MB",
        ],
        "ERROR": [
            "500 Internal Server Error: {endpoint}",
            "404 Not Found: {endpoint}",
            "Request validation failed: {error}",
            "Authentication failed for user_id={user_id}",
        ],
    },
    "Auth": {
        "INFO": [
            "User login successful: user_id={user_id}",
            "Token generated for user_id={user_id}",
            "Password reset email sent to user_id={user_id}",
        ],
        "WARN": [
            "Failed login attempt for user_id={user_id}",
            "Token expired for user_id={user_id}",
            "Multiple login attempts from IP {ip}",
        ],
        "ERROR": [
            "Invalid credentials for user_id={user_id}",
            "Session hijacking attempt detected",
            "Brute force attack detected from IP {ip}",
        ],
    },
    "Cache": {
        "INFO": [
            "Cache hit: key={key}",
            "Cache miss: key={key}",
            "Cache size: {size}MB / 512MB",
        ],
        "WARN": [
            "Cache eviction: Memory limit reached",
            "Cache miss rate high: {rate}%",
            "Stale data detected for key={key}",
        ],
        "ERROR": [
            "Cache server unreachable",
            "Cache corruption detected",
            "Out of memory: Cannot allocate cache",
        ],
    },
    "Queue": {
        "INFO": [
            "Message processed: queue={queue} time={time}ms",
            "Queue size: {size} messages pending",
            "Worker started: worker_id={worker_id}",
        ],
        "WARN": [
            "Queue backlog growing: {size} messages",
            "Message processing slow: {time}ms",
            "Dead letter queue has {size} messages",
        ],
        "ERROR": [
            "Message processing failed: {error}",
            "Queue connection lost",
            "Worker crashed: worker_id={worker_id}",
        ],
    },
    "Payment": {
        "INFO": [
            "Payment processed: amount=${amount} user_id={user_id}",
            "Refund issued: transaction_id={transaction_id}",
            "Payment gateway connected",
        ],
        "WARN": [
            "Payment declined: insufficient funds user_id={user_id}",
            "Retry attempt {attempt}/3 for transaction_id={transaction_id}",
            "Payment gateway latency high: {time}ms",
        ],
        "ERROR": [
            "Payment gateway timeout",
            "Transaction failed: {error}",
            "Fraud detection triggered for user_id={user_id}",
        ],
    },
}

# ============================================
# HELPER FUNCTIONS
# ============================================

def generate_timestamp():
    """Generate realistic timestamp (slightly in past)"""
    # Random time in last 60 seconds
    seconds_ago = random.randint(0, 60)
    timestamp = datetime.now() - timedelta(seconds=seconds_ago)
    return timestamp.strftime("%Y-%m-%d %H:%M:%S")

def choose_log_level():
    """Choose log level based on probability weights"""
    # Create a weighted random choice
    levels = []
    weights = []
    for level, weight in LEVEL_WEIGHTS.items():
        levels.append(level)
        weights.append(weight)
    
    return random.choices(levels, weights=weights)[0]

def generate_values():
    """Generate random values for message templates"""
    return {
        "time": random.randint(50, 5000),  # Response time in ms
        "pool": random.randint(10, 95),    # Connection pool count
        "rows": random.randint(100, 10000), # Database rows
        "query": "SELECT * FROM users WHERE id = 12345",
        "user_id": random.randint(1000, 9999),
        "id": random.randint(1, 1000),
        "endpoint": random.choice(["/api/users", "/api/orders", "/api/products"]),
        "count": random.randint(50, 95),
        "size": random.randint(5, 50),
        "error": random.choice(["Invalid input", "Connection refused", "Timeout"]),
        "key": f"cache_key_{random.randint(1, 100)}",
        "rate": random.randint(40, 80),
        "queue": random.choice(["orders", "emails", "notifications"]),
        "worker_id": random.randint(1, 10),
        "amount": f"{random.randint(10, 500)}.{random.randint(0, 99):02d}",
        "transaction_id": f"TXN{random.randint(100000, 999999)}",
        "attempt": random.randint(1, 3),
        "ip": f"192.168.{random.randint(1, 255)}.{random.randint(1, 255)}",
    }

def generate_log_entry():
    """Generate a single log entry"""
    timestamp = generate_timestamp()
    level = choose_log_level()
    component = random.choice(COMPONENTS)
    
    # Get message template for this component and level
    message_templates = MESSAGES[component][level]
    message_template = random.choice(message_templates)
    
    # Fill in the template with random values
    values = generate_values()
    message = message_template.format(**values)
    
    # Format: TIMESTAMP LEVEL [COMPONENT] MESSAGE
    log_line = f"{timestamp} {level:5} [{component:10}] {message}"
    
    return log_line

# ============================================
# MAIN FUNCTION
# ============================================

def main():
    """
    Main function: Generate logs continuously
    """
    # Create logs directory if it doesn't exist
    if not os.path.exists(LOG_DIR):
        os.makedirs(LOG_DIR)
    
    # Generate filename with current date
    date_str = datetime.now().strftime("%Y%m%d")
    log_file = f"{LOG_DIR}/app_{date_str}.log"
    
    print(f"🚀 Starting log generator...")
    print(f"📝 Writing to: {log_file}")
    print(f"⏱️  Generating 1 log entry per second")
    print(f"⚠️  Press Ctrl+C to stop\n")
    
    entry_count = 0
    
    try:
        with open(log_file, "a") as f:  # "a" = append mode
            while True:
                # Generate and write log entry
                log_entry = generate_log_entry()
                f.write(log_entry + "\n")
                f.flush()  # Force write to disk immediately
                
                # Print to console too
                entry_count += 1
                print(f"[{entry_count:4}] {log_entry}")
                
                # Wait 1 second before next entry
                time.sleep(1)
                
    except KeyboardInterrupt:
        print(f"\n\n✅ Stopped. Generated {entry_count} log entries.")
        print(f"📁 Log file: {log_file}")

if __name__ == "__main__":
    main()