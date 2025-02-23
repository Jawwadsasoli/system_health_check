#!/bin/bash

set -e 

LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/system_health.log"


#Threshold for alerts

CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=90

mkdir -p "$LOG_DIR"

echo_log(){
	echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}
check_cpu(){
	CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
	echo_log "CPU USAGE: $CPU_USAGE%"
	if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
	echo_log "WARNING: CPU usage exceeded $CPU_THRESHOLD%!"
	fi
}


check_memory(){
	MEM_USAGE=$(free  | awk '/Mem/{printf("%.2f"), $3/$2*100}')
	echo_log "Memory USAGE: $MEM_USAGE%"
	if (( $(echo "$MEM_USAGE > $MEM_THRESHOLD" | bc -l) )); then
	echo_log "WARNING: Memory usage exceeded $MEM_THRESHOLD%!"
	fi
}

check_disk(){
	DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
	echo_log "Disk USAGE: $DISK_USAGE%"
	if (( DISK_USAGE > DISK_THRESHOLD )); then
	echo_log "WARNING: Memory usage exceeded $DISK_THRESHOLD%!"
	fi
}

check_processes(){
	PROCESS_COUNT=$(ps aux --no-heading | wc -l)
	echo_log "Total Running Processes: $PROCESS_COUNT"
}

run_checks(){
	echo_log "------ System Health Check ------"
	check_cpu
	check_memory
	check_disk
	check_processes
}


run_checks


CRON_JOBS="*/1 * * * * $(realpath $0)"
CRON_FILE="/tmp/cronjob"
crontab -l > "$CRON_FILE" 2>/dev/null || true
if ! grep -Fxq "$CRON_JOBS" "$CRON_FILE"; then
	echo "$CRON_JOBS" >> "$CRON_FILE"
	crontab "$CRON_FILE"
	echo_log "Cron Job added to run every 10 minutes."
else
	echo_log "Cron Job already exists"
fi
