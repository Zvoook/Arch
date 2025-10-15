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
        echo " $(basename "$file")"
    done
else
    echo " (нет - критическая ситуация)"
fi

echo ""
echo "Будут заархивированы:"
echo "$files_to_archive" | while read -r file; do
    echo " $(basename "$file")"
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
            echo " Удален: $(basename "$file")"
        fi
    done
    
    new_usage=$(df "$LOG_PATH" | awk 'NR==2 {print $5}' | sed 's/%//')
    echo ""
    echo "Результат:"
    echo " Было: $usage%"
    echo " Стало: $new_usage%"
    
else
    echo "Ошибка при создании архива!"
    exit 1
fi

echo ""
echo "Архивирование завершено"