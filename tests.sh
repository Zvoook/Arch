#!/bin/bash

LOG_PATH="/LOG"
BACKUP_PATH="/BACKUP"
SCRIPT="./lab.sh"

cleanup() {
    echo "Очистка директории"
    rm -f $LOG_PATH/* 2>/dev/null
    rm -f $BACKUP_PATH/* 2>/dev/null
}

show_status() {
    echo ""
    echo "Файлов в $LOG_PATH: $(ls $LOG_PATH 2>/dev/null | wc -l)"
    df -h $LOG_PATH | grep $LOG_PATH
    echo "Архивов в $BACKUP_PATH: $(ls $BACKUP_PATH/*.tar.gz 2>/dev/null | wc -l)"
    echo ""
}

test1() {
    echo "ТЕСТ 1: Много файлов"
    echo "Ожидается: остались 3 самых новых файла"
    cleanup

    echo "Создаем 3 больших файла для заполнения диска (750 Mb)"

    dd if=/dev/zero of=$LOG_PATH/big1.log bs=1M count=250 2>/dev/null
    dd if=/dev/zero of=$LOG_PATH/big2.log bs=1M count=250 2>/dev/null
    dd if=/dev/zero of=$LOG_PATH/big3.log bs=1M count=250 2>/dev/null
    

    echo "Создаем еще 5 небольших файлов (100 Mb)"
    for i in {1..5}; do
	dd if=/dev/zero of=$LOG_PATH/test_$i.log bs=1M count=20 2>/dev/null
        sleep 0.2
    done
    
    show_status
    
    echo "Запуск скрипта (порог 70%, оставить 3 файла)"
    $SCRIPT 70 3
    
    show_status
}

test2() {
    echo "ТЕСТ 2: Критическая ситуация - один большой файл"
    echo "Ожидается: файл заархивирован (при критической ситуации)"
    cleanup
    
    echo "Создаем один большой файл (800 МБ)"
    dd if=/dev/zero of=$LOG_PATH/huge_file.log bs=1M count=800 2>/dev/null
    
    show_status
    
    echo "Запуск скрипта (порог 70%, оставить 3 файла)"
    echo "Файлов меньше 3, но диск переполнен"
    $SCRIPT 70 3
    
    show_status
}

test3() {
    echo "ТЕСТ 3: Заполненность ниже порога"
    echo "Ожидается: архивирование не запустилось"
    cleanup
    
    echo "Создаем маленькие файлы"
    for i in {1..5}; do
    dd if=/dev/zero of=$LOG_PATH/small_file_$i.log bs=1M count=20 2>/dev/null
    done
    
    show_status
    
    echo "Запуск скрипта (порог 70%)"
    $SCRIPT 70 3
    
    show_status
}

test4() {
    echo "ТЕСТ 4: Пробуем заархивировать всё"
    echo "Ожидается: папка пуста, все файлы заархивированы"
    cleanup
    
    echo "Создаем 7 файлов (770 Mb)"
    for i in {1..7}; do
        dd if=/dev/zero of=$LOG_PATH/file_$i.log bs=1M count=110 2>/dev/null
        sleep 0.2
    done
    
    show_status
    
    echo "Запуск скрипта (порог 70%, оставить 0 файлов)"
    $SCRIPT 70 0
    
    show_status
}

test5() {
    echo "ТЕСТ 5: Пустая папка"
    echo "Ожидается: сообщение о пустой папке"
    cleanup
    
    show_status
    
    echo "Запускаем скрипт на пустой папке"
    $SCRIPT 70 3
    
    show_status
}


if [ $# -eq 0 ]; then
    echo "Доступные тесты:"
    echo "  1 - Много файлов"
    echo "  2 - Один большой файл"
    echo "  3 - Заполненность ниже порога"
    echo "  4 - Архивируем все файлы"
    echo "  5 - Пустая папка"
    echo "  all - Запустить все тесты"
    echo ""
    exit 1
fi


if [ ! -f "$SCRIPT" ]; then
    echo "Ошибка: файл $SCRIPT не найден"
    exit 1
fi

case $1 in
    1) test1 ;;
    2) test2 ;;
    3) test3 ;;
    4) test4 ;;
    5) test5 ;;
    all)
        test1
        echo ""
        echo ""
        echo ""
        echo ""
        echo ""
        test2
        echo ""
        echo ""
        echo ""
        echo ""
        echo ""
        test3
        echo ""
        echo ""
        echo ""
        echo ""
        echo ""
        test4
        echo ""
        echo ""
        echo ""
        echo ""
        echo ""
        test5
        echo ""
        echo "Все тесты завершены"
        ;;
    *)
        echo "Неверный номер теста: $1"
        echo "Используйте: $0 [1-5] или all"
        exit 1
        ;;
esac
