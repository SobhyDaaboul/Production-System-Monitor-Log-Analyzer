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

## 🎓 What I Learned

Built a Linux-based monitoring system using Bash and Python

Collected and analyzed system metrics (CPU, memory, disk)

Parsed and analyzed log files in real time using regex

Stored and analyzed data using PostgreSQL and SQL

Detected issues early through monitoring, alerting, and log analysis

Automated data collection, reporting, and troubleshooting workflows

Applied production best practices for performance, reliability, and efficiency