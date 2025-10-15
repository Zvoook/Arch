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

used_space=$(du -sk "$LOG_PATH" | awk '{print $1}')
total_space=1000000
usage=$((used_space * 100 / total_space))
echo "Заполненность $LOG_PATH: $usage%"

if [ "$usage" -lt "$LIMIT" ]; then
    echo "Заполненность в норме (лимит: $LIMIT%)"
    exit 0
fi



echo "Заполненность превышает лимит $LIMIT%!"
echo "Начинаем архивированиe"

all_files=$(find "$LOG_PATH" -maxdepth 1 -type f -printf "%T@ %p\n" | sort -rn | cut -d' ' -f2-)
total_files=$(echo "$all_files" | wc -l)

if [ "$total_files" -le "$KEEP_NEWEST" ]; then
    echo "Внимание: недостаточно файлов для стандартного архивирования"
    echo "Всего файлов: $total_files, нужно оставить: $KEEP_NEWEST"
    
    if [ "$total_files" -gt 0 ]; then
        echo "Критическая ситуация: архивируем все доступные файлы"
        files_to_archive="$all_files"
        files_to_keep=""
    else
        echo "Нет файлов для архивирования"
        exit 0
    fi
else
    files_to_keep=$(echo "$all_files" | head -n "$KEEP_NEWEST")
    files_to_archive=$(echo "$all_files" | tail -n +$((KEEP_NEWEST + 1)))
fi

echo ""
echo "Останутся:"
if [ -n "$files_to_keep" ]; then
    echo "$files_to_keep" | while read -r file; do
        echo "  $(basename "$file")"
    done
else
    echo "  (нет - критическая ситуация)"
fi

echo ""
echo "Будут заархивированы:"
echo "$files_to_archive" | while read -r file; do
    echo "  $(basename "$file")"
done

timestamp=$(date +"%Y%m%d_%H%M%S")
archive_name="backup_$timestamp.tar.gz"
archive_path="$BACKUP_PATH/$archive_name"

echo ""
echo "Создание архива: $archive_name"

cd "$LOG_PATH" || exit 1

if tar -czf "$archive_path" $(echo "$files_to_archive" | xargs -n1 basename); then
    echo "Архив создан успешно"
    
    echo ""
    echo "Удаление файлов"
    echo "$files_to_archive" | while read -r file; do
        if [ -f "$file" ]; then
            rm "$file"
            echo "  Удален: $(basename "$file")"
        fi
    done
    
    new_used_space=$(du -sk  "$LOG_PATH" | awk '{print $1}')
    new_usage=$((new_used_space * 100 / total_space))
    echo ""
    echo "Результат:"
    echo "  Было: $usage%"
    echo "  Стало: $new_usage%"
    
else
    echo "Ошибка при создании архива!"
    exit 1
fi

echo ""
echo "Архивирование завершено"
