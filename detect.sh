#!/bin/bash

# 1. ЗАЩИТА ОТ ЗАКРЫТИЯ КОНСОЛИ И СИГНАЛОВ СИСТЕМЫ
trap '' SIGINT SIGTSTP SIGQUIT SIGTERM SIGHUP

CORRECT_PASS="001"
UNLOCKED=false

export DISPLAY=${DISPLAY:-:0}
export XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority}

WINDOW_TITLE="System Security Lock"

# Запоминаем PID самого скрипта
MY_PID=$$

# 2. ФУНКЦИЯ ТОТАЛЬНОГО УНИЧТОЖЕНИЯ ВСЕХ ПРОЦЕССОВ (КРОМЕ СЕБЯ)
kill_absolutely_everything() {
    while [ "$UNLOCKED" = false ]; do
        # Находим PID графического интерфейса (kdialog или zenity), который мы открыли
        DIALOG_PID=$(pgrep -f "$WINDOW_TITLE" | grep -v "$MY_PID")

        # Получаем список всех PID процессов текущего пользователя
        pids=$(pgrep -u "$USER")

        for pid in $pids; do
            # Пропускаем критически важные процессы, чтобы система не упала в черный экран:
            # - Сам скрипт ($MY_PID)
            # - Фоновый цикл очистки ($BASHPID)
            # - Окно ввода пароля ($DIALOG_PID)
            # - Системные графические сервера и менеджеры (systemd, xorg, kwin, kded, plasma, dbus)
            if [ "$pid" -eq "$MY_PID" ] || \
               [ "$pid" -eq "$BASHPID" ] || \
               [ -n "$DIALOG_PID" && "$pid" -eq "$DIALOG_PID" ] || \
               cat /proc/$pid/cmdline 2>/dev/null | grep -E -q "systemd|Xorg|kwin|ksmserver|kded|plasma|dbus|wayland|lxqt|gnome-session|xfce"; then
                continue
            fi

            # Жестко убиваем все остальные процессы пользователя (браузеры, игры, терминалы, блокноты)
            kill -9 "$pid" &>/dev/null
        done

        # Параллельно принудительно разворачиваем окно ввода на весь экран и выводим на передний план
        if command -v wmctrl &> /dev/null; then
            wmctrl -r "$WINDOW_TITLE" -b add,fullscreen,above &>/dev/null
            wmctrl -a "$WINDOW_TITLE" &>/dev/null
        fi

        sleep 0.1
    done
}

# 3. ИСПРАВЛЕННАЯ ФУНКЦИЯ ПРОВЕРКИ НА ЦИФРЫ
is_numeric() {
    local clean_input
    clean_input=$(echo -n "$1" | tr -d '\r' | tr -d '[:space:]')
    [[ "$clean_input" =~ ^[0-9]+$ ]]
}

# Запускаем тотальный ликвидатор процессов в фоне
kill_absolutely_everything &
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

    # Очищаем ввод от невидимых символов
    INPUT=$(echo -n "$INPUT" | tr -d '\r' | tr -d '[:space:]')

    # Если окно закрыли или нажали "Отмена" — мгновенно перезапускаем
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
        kill -9 "$MONITOR_PID" &>/dev/null # Останавливаем уничтожение процессов
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
