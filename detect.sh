#!/bin/bash

# Перехватываем системные сигналы прерывания (Ctrl+C, Ctrl+Z, Ctrl+\, закрытие)
# Скрипт проигнорирует их и продолжит работу
trap '' SIGINT SIGTSTP SIGQUIT SIGTERM

CORRECT_PASS="001"
UNLOCKED=false

# Прячем курсор терминала, чтобы его не было видно
echo -e "\e[?25l"

# Функция отрисовки интерфейса по центру экрана
draw_screen() {
    clear
    # Очищаем экран и задаем черный фон, белый текст
    echo -e "\e[40m\e[37m"
    clear

    # Получаем текущие размеры терминала (строки и столбцы)
    local rows=$(tput lines)
    local cols=$(tput cols)

    # Вычисляем центр экрана
    local middle_row=$((rows / 2 - 2))
    local text="enter pass for unlock:"
    local text_col=$(( (cols - ${#text}) / 2 ))

    # Перемещаем курсор в центр экрана и выводим текст
    echo -e "\e[${middle_row};${text_col}H${text}"
    
    # Смещаем курсор на две строки ниже для поля ввода пароля
    local input_row=$((middle_row + 2))
    local input_col=$(( (cols - 20) / 2 ))
    echo -e "\e[${input_row};${input_col}H"
}

# Функция безопасного ввода пароля (только цифры, маскировка звездочками)
read_password() {
    local password=""
    local char=""
    
    # Переводим терминал в режим посимвольного чтения без вывода на экран (raw-режим)
    stty -echo -icanon min 1 time 0

    while true; do
        # Читаем ровно один символ
        char=$(dd bs=1 count=1 2>/dev/null)

        # Если нажат Enter (символ новой строки или перевода каретки)
        if [ "$char" = $'\n' ] || [ "$char" = $'\r' ]; then
            break
        fi

        # Если нажат Backspace (символы удаления)
        if [ "$char" = $'\x7f' ] || [ "$char" = $'\x08' ]; then
            if [ ${#password} -gt 0 ]; then
                password="${password%?}"
                # Стираем последнюю звездочку на экране
                echo -ne "\b \b"
            fi
            continue
        fi

        # Валидация: разрешаем вводить ТОЛЬКО цифры (от 0 до 9)
        if [[ "$char" =~ [0-9] ]]; then
            password+="$char"
            echo -n "*" # Выводим звездочку вместо цифры
        fi
        
        # Нажатие Escape (и других управляющих клавиш) здесь просто игнорируется,
        # так как символ не подпадает под регулярное выражение [0-9]
    done

    # Возвращаем терминал в исходный нормальный режим
    stty echo icanon
    echo "$password"
}

# ГЛАВНЫЙ ЦИКЛ БЛОКИРОВКИ
while [ "$UNLOCKED" = false ]; do
    draw_screen
    
    # Вызываем нашу функцию чтения ввода
    INPUT=$(read_password)

    if [ "$INPUT" = "$CORRECT_PASS" ]; then
        UNLOCKED=true
    else
        # Выводим ошибку по центру чуть ниже поля ввода
        local rows=$(tput lines)
        local cols=$(tput cols)
        local err_row=$((rows / 2 + 3))
        local err_text="Incorrect password!"
        local err_col=$(( (cols - ${#err_text}) / 2 ))
        
        echo -e "\e[${err_row};${err_col}H\e[31m${err_text}\e[37m"
        sleep 1.5
    fi
done

# ВОССТАНОВЛЕНИЕ СИСТЕМЫ
# Возвращаем курсор обратно на экран
echo -e "\e[?25h"
clear
echo "Доступ восстановлен."
