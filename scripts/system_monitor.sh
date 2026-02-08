#!/bin/bash

# ============================================
# SYSTEM MONITOR SCRIPT
# Purpose: Collect system metrics every minute
# ============================================

# Load configuration
CONFIG_FILE="config/config.yaml"

# Database connection (you can parse YAML or hardcode for now)
DB_NAME="monitoring_db"
DB_USER="monitor_user"
DB_HOST="localhost"

# Export password for psql (or use .pgpass file)
export PGPASSWORD="monitor_pass"

# ============================================
# FUNCTIONS
# ============================================

get_cpu_usage() {
    # Get CPU usage percentage
    # top shows idle %, we want used %
    local idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
    local used=$(echo "100 - $idle" | bc)
    echo $used
}

get_memory_usage() {
    # Get memory usage in MB and percentage
    # free shows:
    # total        used        free      shared  buff/cache   available
    local total=$(free -m | awk 'NR==2 {print $2}')
    local used=$(free -m | awk 'NR==2 {print $3}')
    local percent=$(echo "scale=2; ($used / $total) * 100" | bc)
    
    echo "$percent $total $used"
}

get_disk_usage() {
    # Get disk usage for root partition
    local disk_info=$(df -BG / | awk 'NR==2 {print $2,$3,$5}')
    local total=$(echo $disk_info | awk '{print $1}' | sed 's/G//')
    local used=$(echo $disk_info | awk '{print $2}' | sed 's/G//')
    local percent=$(echo $disk_info | awk '{print $3}' | sed 's/%//')
    
    echo "$percent $total $used"
}

get_process_count() {
    # Count active processes
    ps aux | wc -l
}

get_load_average() {
    # Get 1-minute load average
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
}

insert_metrics() {
    local cpu=$1
    local mem_percent=$2
    local mem_total=$3
    local mem_used=$4
    local disk_percent=$5
    local disk_total=$6
    local disk_used=$7
    local processes=$8
    local load=$9
    
    # Current timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Insert into database
    psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
        INSERT INTO system_metrics (
            metric_timestamp,
            cpu_usage,
            memory_usage,
            memory_total_mb,
            memory_used_mb,
            disk_usage,
            disk_total_gb,
            disk_used_gb,
            active_processes,
            load_average
        ) VALUES (
            '$timestamp',
            $cpu,
            $mem_percent,
            $mem_total,
            $mem_used,
            $disk_percent,
            $disk_total,
            $disk_used,
            $processes,
            $load
        );
    " > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Metrics inserted: CPU=$cpu% MEM=$mem_percent% DISK=$disk_percent%"
    else
        echo "❌ Failed to insert metrics"
    fi
}

# ============================================
# MAIN LOOP
# ============================================

echo "🚀 Starting system monitor..."
echo "📊 Collecting metrics every 60 seconds"
echo "⚠️  Press Ctrl+C to stop"
echo ""

while true; do
    echo "[$(date '+%H:%M:%S')] Collecting metrics..."
    
    # Collect all metrics
    cpu=$(get_cpu_usage)
    read mem_percent mem_total mem_used <<< $(get_memory_usage)
    read disk_percent disk_total disk_used <<< $(get_disk_usage)
    processes=$(get_process_count)
    load=$(get_load_average)
    
    # Insert into database
    insert_metrics $cpu $mem_percent $mem_total $mem_used \
                   $disk_percent $disk_total $disk_used \
                   $processes $load
    
    # Wait 60 seconds
    sleep 60
done