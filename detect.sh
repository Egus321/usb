#!/bin/bash

# Инициализация защиты от сигналов прерывания
trap '' SIGINT SIGTSTP SIGQUIT SIGTERM

CORRECT_PASS="001"
UNLOCKED=false

# Пытаемся вытащить данные дисплея для корректного запуска графических окон
export DISPLAY=${DISPLAY:-:0}
export XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority}

# ГЛАВНЫЙ ЦИКЛ БЛОКИРОВКИ (Графический интерфейс)
while [ "$UNLOCKED" = false ]; do
    
    # Выводим графическое окно ввода пароля (скрытый ввод)
    # Используем kdialog (родной для KDE/MOS Linux), если его нет — gdialog/zenity
    if command -v kdialog &> /dev/null; then
        INPUT=$(kdialog --title "Security Lock" --password "Enter pass for unlock:")
        STATUS=$?
    elif command -v zenity &> /dev/null; then
        INPUT=$(zenity --entry --title="Security Lock" --text="Enter pass for unlock:" --hide-text)
        STATUS=$?
    else
        # Резервный вариант, если графические утилиты диалогов отсутствуют
        stty -echo
        read -r -p "Enter pass for unlock: " INPUT
        stty echo
        STATUS=0
    fi

    # Если пользователь нажал "Отмена" (Status != 0) или закрыл окно крестиком
    if [ $STATUS -ne 0 ]; then
        continue
    fi

    # Проверка пароля
    if [ "$INPUT" = "$CORRECT_PASS" ]; then
        UNLOCKED=true
    else
        # Графическое окно ошибки
        if command -v kdialog &> /dev/null; then
            kdialog --error "Incorrect password!" --title "Error"
        elif command -v zenity &> /dev/null; then
            zenity --error --text="Incorrect password!" --title="Error"
        else
            echo "Incorrect password!"
            sleep 1.2
        fi
    fi
done

# ЗАПУСК ТЕКСТОВОГО РЕДАКТОРА
if command -v kwrite &> /dev/null; then
    kwrite &>/dev/null &
elif command -v kate &> /dev/null; then
    kate &>/dev/null &
elif command -v gedit &> /dev/null; then
    gedit &>/dev/null &
fi

exit 0
