# Production System Monitor & Log Analyzer

A comprehensive monitoring and troubleshooting toolkit that simulates real-world production support workflows. This project demonstrates proactive system monitoring, log analysis, issue detection, and automated reporting capabilities.

## 🎯 Purpose

This project showcases the skills needed for Technical Analyst and Production Support roles:
- **Monitoring**: Real-time system health tracking (CPU, memory, disk)
- **Log Analysis**: Parsing application logs to identify patterns and anomalies
- **Issue Detection**: Automatically flagging problems before they escalate
- **Troubleshooting**: SQL-based analysis to investigate performance bottlenecks
- **Reporting**: Daily health summaries for management visibility

## 🏗️ Architecture
```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ Log Generator│─────>│ Application  │<─────│ System       │
│  (Python)    │      │ Logs         │      │ Monitor      │
└──────────────┘      └──────────────┘      │  (Bash)      │
                             │               └──────────────┘
                             │                      │
                             ▼                      ▼
                      ┌──────────────────────────────┐
                      │   Log Analyzer (Python)       │
                      │ - Parse logs                  │
                      │ - Detect issues               │
                      │ - Store metrics               │
                      └──────────────────────────────┘
                                  │
                                  ▼
                      ┌──────────────────────────────┐
                      │   PostgreSQL Database         │
                      │ - log_entries                 │
                      │ - system_metrics              │
                      │ - issues                      │
                      │ - health_reports              │
                      └──────────────────────────────┘
                                  │
                                  ▼
                      ┌──────────────────────────────┐
                      │  Analysis & Reporting         │
                      │ - SQL queries                 │
                      │ - Health check script         │
                      └──────────────────────────────┘
```

## 📋 Features

### 1. Log Generation
- Simulates realistic production application logs
- Multiple components: Database, API, Auth, Cache, Queue, Payment
- Various log levels: INFO, WARN, ERROR, DEBUG
- Realistic scenarios: timeouts, slow queries, failed authentication

### 2. System Monitoring
- CPU usage tracking
- Memory usage (total and percentage)
- Disk usage
- Active process count
- Load average
- Automated data collection every 60 seconds

### 3. Log Analysis
- Real-time log parsing
- Pattern recognition for common issues
- Response time extraction
- User activity tracking
- Error code identification
- Issue grouping and counting

### 4. Issue Detection
- High error rates per component
- Database timeouts
- Slow API responses
- Failed authentication attempts
- Automatic severity classification (CRITICAL, HIGH, MEDIUM, LOW)

### 5. Reporting
- Daily health summaries
- Error rate trends
- Performance analysis
- System health scoring
- Top errors and slow components

## 🚀 Setup Instructions

### Prerequisites
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3 python3-pip postgresql postgresql-contrib

# macOS
brew install python postgresql
```

### Installation

1. **Clone/Download Project**
```bash
cd production-system-monitor
```

2. **Install Python Dependencies**
```bash
pip3 install psycopg2-binary pyyaml
```

3. **Setup PostgreSQL Database**
```bash
# Start PostgreSQL
sudo service postgresql start

# Create database and user
sudo -u postgres psql
CREATE DATABASE monitoring_db;
CREATE USER monitor_user WITH PASSWORD 'monitor_pass';
GRANT ALL PRIVILEGES ON DATABASE monitoring_db TO monitor_user;
\q

# Create tables
psql -U monitor_user -d monitoring_db -f sql/schema.sql
```

4. **Configure Settings**
Edit `config/config.yaml` with your database credentials and preferences.

5. **Make Scripts Executable**
```bash
chmod +x scripts/*.sh scripts/*.py
```

## 📖 Usage

### Start All Components

**Terminal 1: Log Generator**
```bash
python3 scripts/log_generator.py
```

**Terminal 2: System Monitor**
```bash
./scripts/system_monitor.sh
```

**Terminal 3: Log Analyzer**
```bash
python3 scripts/log_analyzer.py
```

Let all three run for at least 15-30 minutes to generate meaningful data.

### Generate Health Report
```bash
./scripts/health_check.sh
```

### Run Analysis Queries
```bash
psql -U monitor_user -d monitoring_db

# Inside psql, run queries from sql/queries.sql
\i sql/queries.sql
```

## 📊 Example Queries

### View Recent Errors
```sql
SELECT log_timestamp, component, message 
FROM log_entries 
WHERE log_level = 'ERROR' 
ORDER BY log_timestamp DESC 
LIMIT 10;
```

### Check System Health
```sql
SELECT 
    metric_timestamp,
    cpu_usage,
    memory_usage,
    disk_usage
FROM system_metrics
ORDER BY metric_timestamp DESC
LIMIT 10;
```

### View Active Issues
```sql
SELECT 
    issue_type,
    severity,
    occurrence_count,
    last_seen
FROM issues
WHERE resolved = FALSE
ORDER BY severity;
```

## 🎓 What I Learned

### Technical Skills
- **Linux/Bash**: System metrics collection, process monitoring, automated scripting
- **Python**: Log parsing with regex, database operations, real-time file monitoring
- **SQL**: Complex queries, aggregations, window functions, performance analysis
- **PostgreSQL**: Schema design, indexing, bulk inserts, data types
- **System Administration**: Understanding CPU/memory/disk metrics, load averages

### Support Concepts
- **Proactive Monitoring**: Catching issues before users report them
- **Log Analysis**: Finding patterns in large volumes of unstructured data
- **Issue Prioritization**: Classifying problems by severity and impact
- **Root Cause Analysis**: Using SQL to drill down into performance problems
- **Documentation**: Writing clear reports for technical and non-technical audiences

### Production Practices
- **Automation**: Scripts that run continuously without manual intervention
- **Data Retention**: Managing log volumes and database size
- **Alerting**: Threshold-based notifications for critical issues
- **Reporting**: Daily summaries for management visibility
- **Troubleshooting Workflow**: Systematic approach to investigating problems

## 🔧 Technical Details

### Database Schema
- **log_entries**: Every parsed log line (indexed by timestamp, level, component)
- **system_metrics**: System health snapshots every minute
- **issues**: Detected problems grouped by type and severity
- **health_reports**: Daily summaries with scores and trends

### Key Components
- **Log Generator**: Creates 1 log entry per second with realistic distribution
- **System Monitor**: Collects metrics every 60 seconds using Linux commands
- **Log Analyzer**: Monitors log files in real-time, parses with regex, detects patterns
- **Health Check**: Generates formatted report combining all data sources

### Performance Considerations
- Bulk inserts for efficiency (100+ rows at once)
- Database indexes on frequently queried columns
- File tailing instead of full re-reads
- Minimal memory footprint (suitable for limited resources)

## 🎯 Real-World Applications

This project directly applies to roles like:
- **Technical Analyst**: Monitor production systems, investigate issues
- **Application Support**: Analyze logs, troubleshoot errors, coordinate fixes
- **DevOps Engineer**: Build monitoring infrastructure, automate alerting
- **Site Reliability Engineer**: Track system health, improve reliability

The skills demonstrated:
- Reading/parsing production logs
- SQL-based performance analysis
- Linux system administration
- Automated monitoring and alerting
- Technical documentation
- Problem-solving under pressure

## 📚 Future Enhancements

Possible improvements to showcase continuous learning:
- Web dashboard (Flask/React) for real-time visualization
- Email/Slack alerts for critical issues
- Machine learning for anomaly detection
- Integration with external monitoring tools (Grafana, Prometheus)
- Log retention and archival policies
- Multi-server monitoring (distributed systems)

## 📝 License

Personal educational project - free to use and modify.

## 👤 Author

**Sobhy Daaboul**
- Email: sobhydaaboul4@gmail.com
- Phone: +961 71 629 655
- Location: Lebanon

*Built as part of technical portfolio for Technical Analyst roles*
```

---

## 📊 PHASE 9: Creating Your Updated CV

Now that you've built the project, let's create your updated CV with this impressive addition.

### Updated Project Section

Replace your current projects with:
```
KEY PROJECTS

Production System Monitor & Log Analyzer
Technologies: Python, Bash, PostgreSQL, Linux
GitHub: [your-github-link]

- Built a comprehensive monitoring and troubleshooting toolkit simulating production support workflows for high-availability systems
- Developed Python-based log analyzer that parses 1,000+ daily application logs, identifies error patterns using regex, and stores structured data in PostgreSQL for trend analysis
- Created Bash scripts for automated system monitoring (CPU, memory, disk usage) with threshold-based alerting, collecting metrics every 60 seconds
- Designed SQL queries to analyze performance bottlenecks, calculate error rates, and generate daily health reports with system scoring (0-100)
- Implemented automated issue detection that groups similar problems, tracks occurrence counts, and prioritizes by severity (CRITICAL/HIGH/MEDIUM/LOW)
- Focused on proactive monitoring, rapid issue detection, and data-driven troubleshooting approaches typical of mission-critical production environments
- Generated comprehensive documentation including setup guides, usage examples, and technical architecture diagrams