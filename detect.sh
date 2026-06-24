#!/bin/bash

# 1. ЗАЩИТА ОТ ЗАКРЫТИЯ КОНСОЛИ И СИГНАЛОВ СИСТЕМЫ
trap '' SIGINT SIGTSTP SIGQUIT SIGTERM SIGHUP

CORRECT_PASS="001"
UNLOCKED=false

export DISPLAY=${DISPLAY:-:0}
export XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority}

WINDOW_TITLE="System Security Lock"

# 2. ФУНКЦИЯ ПОЛНОЙ ОЧИСТКИ РАБОЧЕГО СТОЛА И УДЕРЖАНИЯ ФОКУСА
# Этот фоновый процесс закрывает абсолютно всё, кроме окна блокировщика, и держит его поверх всех окон
close_everything_else() {
    while [ "$UNLOCKED" = false ]; do
        # Если в системе есть wmctrl, получаем список всех открытых окон
        if command -v wmctrl &> /dev/null; then
            # Читаем список окон по очереди
            wmctrl -l | while read -r line; do
                # Проверяем, содержит ли строка заголовка имя нашего окна блокировки или окон ошибок
                if [[ "$line" != *"$WINDOW_TITLE"* ]] && [[ "$line" != *"Invalid Input"* ]] && [[ "$line" != *"Error"* ]]; then
                    # Извлекаем ID окна (первое слово в строке)
                    local win_id
                    win_id=$(echo "$line" | awk '{print $1}')
                    # Жестко закрываем стороннее окно
                    wmctrl -i -c "$win_id" &>/dev/null
                fi
            done

            # Принудительно удерживаем наше окно на весь экран и поверх всех (Always on Top)
            wmctrl -r "$WINDOW_TITLE" -b add,fullscreen,above &>/dev/null
            wmctrl -a "$WINDOW_TITLE" &>/dev/null
        fi
        
        # Дополнительная защита: убиваем системные терминалы и мониторы на случай, если wmctrl их не успел закрыть
        pkill -f -9 "ksysguard" &>/dev/null
        pkill -f -9 "plasma-systemmonitor" &>/dev/null
        pkill -f -9 "konsole" &>/dev/null
        pkill -f -9 "gnome-terminal" &>/dev/null
        pkill -f -9 "xterm" &>/dev/null

        sleep 0.2
    done
}

# 3. ИСПРАВЛЕННАЯ ФУНКЦИЯ ПРОВЕРКИ НА ЦИФРЫ
is_numeric() {
    local clean_input
    clean_input=$(echo -n "$1" | tr -d '\r' | tr -d '[:space:]')
    [[ "$clean_input" =~ ^[0-9]+$ ]]
}

# Запускаем фоновый уничтожитель всех окон
close_everything_else &
MONITOR_PID=$!

# ГЛАВНЫЙ ЦИКЛ БЛОКИРОВКИ
while [ "$UNLOCKED" = false ]; do
    
    # Вызов графического окна ввода
    if command -v kdialog &> /dev/null; then
        INPUT=$(kdialog --title "$WINDOW_TITLE" --password "Enter ONLY numbers to restore access:")
        STATUS=$?
    elif command -v zenity &> /dev/null; then
        INPUT=$(zenity --entry --title="$WINDOW_TITLE" --text="Enter ONLY numbers to restore access:" --hide-text)
        STATUS=$?
    else
        stty -echo
        read -r -p "Enter ONLY numbers: " INPUT
        stty echo
        STATUS=0
    fi

    # Очищаем ввод от мусорных скрытых символов графической оболочки
    INPUT=$(echo -n "$INPUT" | tr -d '\r' | tr -d '[:space:]')

    # Перехват закрытия окна (крестик или кнопка Отмена)
    if [ $STATUS -ne 0 ] || [ -z "$INPUT" ]; then
        continue
    fi

    # Валидация ввода (только цифры)
    if ! is_numeric "$INPUT"; then
        if command -v kdialog &> /dev/null; then
            kdialog --error "Only digits (0-9) are allowed!" --title "Invalid Input"
        elif command -v zenity &> /dev/null; then
            zenity --error --text="Only digits (0-9) are allowed!" --title="Invalid Input"
        fi
        continue
    fi

    # Проверка пароля
    if [ "$INPUT" = "$CORRECT_PASS" ]; then
        UNLOCKED=true
        kill -9 "$MONITOR_PID" &>/dev/null # Останавливаем тотальное уничтожение окон
    else
        if command -v kdialog &> /dev/null; then
            kdialog --error "Incorrect password! Access denied." --title "Error"
        elif command -v zenity &> /dev/null; then
            zenity --error --text="Incorrect password! Access denied." --title="Error"
        fi
    fi
done

# ВОССТАНОВЛЕНИЕ ДОСТУПА И ЗАПУСК ТЕКСТОВОГО РЕДАКТОРА
if command -v kwrite &> /dev/null; then
    kwrite &>/dev/null &
elif command -v kate &> /dev/null; then
    kate &>/dev/null &
elif command -v gedit &> /dev/null; then
    gedit &>/dev/null &
fi

exit 0
