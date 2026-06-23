#!/bin/bash

# Жесткий перехват сигналов (Ctrl+C, Ctrl+Z, Ctrl+\, закрытие терминала)
trap '' SIGINT SIGTSTP SIGQUIT SIGTERM

CORRECT_PASS="001"
UNLOCKED=false

# Прячем курсор
echo -e "\e[?25l"

# Безопасное получение размеров экрана (с дефолтными значениями, если tput сбоит)
get_terminal_size() {
    rows=$(tput lines 2>/dev/null || echo 24)
    cols=$(tput cols 2>/dev/null || echo 80)
    # Если tput вернул 0 или пустоту
    [ -z "$rows" ] || [ "$rows" -le 0 ] && rows=24
    [ -z "$cols" ] || [ "$cols" -le 0 ] && cols=80
}

draw_screen() {
    clear
    echo -e "\e[40m\e[37m" # Черный фон, белый текст
    clear

    get_terminal_size

    local middle_row=$((rows / 2 - 2))
    local text="enter pass for unlock:"
    local text_col=$(( (cols - ${#text}) / 2 ))

    # Выводим текст
    echo -e "\e[${middle_row};${text_col}H${text}"
    
    # Позиция для звездочек пароля
    local input_row=$((middle_row + 2))
    local input_col=$(( (cols - 10) / 2 ))
    echo -e "\e[${input_row};${input_col}H"
}

read_password() {
    local password=""
    local char=""
    
    # Отключаем отображение ввода, чтобы read работал корректно в MOS Linux
    stty -echo

    while true; do
        # Читаем ровно 1 символ (-n 1) в скрытом режиме (-s) без обработки бэкслешей (-r)
        # Опция -d '' предотвращает баг с игнорированием Enter
        if ! read -r -s -n 1 -d '' char; then
            break
        fi

        # Если нажат Enter (пустая строка в read означает нажатие Enter)
        if [ -z "$char" ]; then
            break
        fi

        # Обработка Backspace (в MOS Linux код клавиши может отличаться)
        if [ "$char" = $'\x7f' ] || [ "$char" = $'\x08' ]; then
            if [ ${#password} -gt 0 ]; then
                password="${password%?}"
                echo -ne "\b \b" # Стираем звездочку
            fi
            continue
        fi

        # Фильтр: только цифры
        if [[ "$char" =~ [0-9] ]]; then
            password+="$char"
            echo -n "*"
        fi
    done

    stty echo
    echo "$password"
}

# ГЛАВНЫЙ ЦИКЛ БЛОКИРОВКИ
while [ "$UNLOCKED" = false ]; do
    draw_screen
    
    INPUT=$(read_password)

    if [ "$INPUT" = "$CORRECT_PASS" ]; then
        UNLOCKED=true
    else
        get_terminal_size
        local err_row=$((rows / 2 + 3))
        local err_text="Incorrect password!"
        local err_col=$(( (cols - ${#err_text}) / 2 ))
        
        echo -e "\e[${err_row};${err_col}H\e[31m${err_text}\e[37m"
        sleep 1.2
    fi
done

# ВОССТАНОВЛЕНИЕ СИСТЕМЫ
echo -e "\e[?25h"
clear
echo "Доступ восстановлен."
