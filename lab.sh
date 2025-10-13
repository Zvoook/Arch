#!/bin/bash

LIMIT=${1:-70}       
KEEP_NEWEST=${2:-3}  
LOG_PATH="/LOG"      
BACKUP_PATH="/BACKUP"

echo ""
echo "Параметры запуска: порог - $LIMIT%, оставлять новых файлов - $KEEP_NEWEST"
echo ""

file_count=$(ls "$LOG_PATH" 2>/dev/null | wc -l)

if [ "$file_count" -eq 0 ]; then
    echo "Папка $LOG_PATH пуста"
    exit 0
fi

echo "В папке $LOG_PATH найдено файлов: $file_count"

usage=$(df "$LOG_PATH" | awk 'NR==2 {print $5}' | sed 's/%//')
echo "Заполненность $LOG_PATH: $usage%"

if [ "$usage" -lt "$LIMIT" ]; then
    echo "Заполненность в норме (лимит: $LIMIT%)"
    exit 0
fi