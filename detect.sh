#!/bin/bash

# 1. ЗАЩИТА ОТ ПРЕРЫВАНИЯ В КОНСОЛИ
trap '' SIGINT SIGTSTP SIGQUIT SIGTERM SIGHUP

CORRECT_PASS="001"
UNLOCKED=false

export DISPLAY=${DISPLAY:-:0}
export XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority}

# Функция проверки ввода (только цифры)
is_numeric() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# 2. ФУНКЦИЯ ФИКСАЦИИ ОКНА (ALWAYS ON TOP И ПОЛНЫЙ ЭКРАН)
# Запускается параллельно и удерживает окно блокировки в фокусе
pin_window_on_top() {
    local title="$1"
    # Ожидаем появления окна в системе (максимум 2 секунды)
    for i in {1..20}; do
        if command -v wmctrl &> /dev/null; then
            # Активируем полноэкранный режим и Always on Top через wmctrl
            wmctrl -r "$title" -b add,fullscreen,above &>/dev/null
            wmctrl -a "$title" &>/dev/null
        elif command -v xdotool &> /dev/null; then
            # Альтернативный вариант через xdotool (поиск окна по имени и фокус)
            WID=$(xdotool search --name "$title" | head -n 1)
            if [ -not -z "$WID" ]; then
                xdotool windowactivate "$WID" &>/dev/null
                xdotool windowsize "$WID" 100% 100% &>/dev/null
            fi
        fi
        sleep 0.1
    done
}

# ГЛАВНЫЙ ЦИКЛ БЛОКИРОВКИ
while [ "$UNLOCKED" = false ]; do
    WINDOW_TITLE="System Protection"
    
    # Запускаем фоновый фиксатор окон для обеспечения Always on Top
    pin_window_on_top "$WINDOW_TITLE" &
    
    # 3. ИНИЦИАЛИЗАЦИЯ ГРАФИЧЕСКОГО ОКНА
    if command -v kdialog &> /dev/null; then
        INPUT=$(kdialog --title "$WINDOW_TITLE" --password "Enter ONLY numbers to restore access:")
        STATUS=$?
    elif command -v zenity &> /dev/null; then
        INPUT=$(zenity --entry --title="$WINDOW_TITLE" --text="Enter ONLY numbers to restore access:" --hide-text)
        STATUS=$?
    else
        # Резервный текстовый режим
        stty -echo
        read -r -p "Enter ONLY numbers: " INPUT
        stty echo
        STATUS=0
    fi

    # Если окно закрыли крестиком или нажали отмену — перезапускаем интерфейс
    if [ $STATUS -ne 0 ] || [ -z "$INPUT" ]; then
        continue
    fi

    # 4. ФИЛЬТРАЦИЯ ВВОДА
    if ! is_numeric "$INPUT"; then
        pin_window_on_top "Invalid Input" &
        if command -v kdialog &> /dev/null; then
            kdialog --error "Only digits (0-9) are allowed!" --title "Invalid Input"
        elif command -v zenity &> /dev/null; then
            zenity --error --text="Only digits (0-9) are allowed!" --title="Invalid Input"
        fi
        continue
    fi

    # 5. ПРОВЕРКА ПАРОЛЯ
    if [ "$INPUT" = "$CORRECT_PASS" ]; then
        UNLOCKED=true
    else
        pin_window_on_top "Access Denied" &
        if command -v kdialog &> /dev/null; then
            kdialog --error "Incorrect password! Desktop is locked." --title "Access Denied"
        elif command -v zenity &> /dev/null; then
            zenity --error --text="Incorrect password! Desktop is locked." --title="Access Denied"
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
