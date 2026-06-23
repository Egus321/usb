#!/bin/bash

# Создаем файл лога и очищаем его при старте
LOG_FILE="/tmp/lock_debug.log"
echo "=== СТАРТ ОТЛАДКИ ОТ $(date) ===" > "$LOG_FILE"

# Функция для вывода красивых логов
log() {
    local level="$1"
    local message="$2"
    # Пишем в файл
    echo "[$(date +%H:%M:%S)] [$level] $message" >> "$LOG_FILE"
    # Если экран еще не заблокирован интерфейсом, дублируем в терминал
    if [ "$UNLOCKED" = false ] && [ -z "$middle_row" ]; then
        echo -e "[$level] $message"
    fi
}

log "INFO" "Инициализация защиты от сигналов прерывания..."
trap 'log "WARN" "Попытка перехвата сигнала завершения!"' SIGINT SIGTSTP SIGQUIT SIGTERM

CORRECT_PASS="001"
UNLOCKED=false

log "INFO" "Скрытие курсора..."
echo -e "\e[?25l"

# Пытаемся вытащить данные дисплея для корректного запуска графического KWrite
export DISPLAY=${DISPLAY:-:0}
export XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority}
log "INFO" "Графическое окружение: DISPLAY=$DISPLAY, XAUTHORITY=$XAUTHORITY"

get_terminal_size() {
    rows=$(tput lines 2>/dev/null || echo 24)
    cols=$(tput cols 2>/dev/null || echo 80)
    [ -z "$rows" ] || [ "$rows" -le 0 ] && rows=24
    [ -z "$cols" ] || [ "$cols" -le 0 ] && cols=80
}

draw_screen() {
    log "DEBUG" "Перерисовка экрана интерфейса блокировки..."
    clear
    echo -e "\e[40m\e[37m"
    clear

    get_terminal_size

    local middle_row=$((rows / 2 - 2))
    local text="enter pass for unlock:"
    local text_col=$(( (cols - ${#text}) / 2 ))

    echo -e "\e[${middle_row};${text_col}H${text}"
    
    local input_row=$((middle_row + 2))
    local input_col=$(( (cols - 10) / 2 ))
    echo -e "\e[${input_row};${input_col}H"
}

read_password() {
    local password=""
    local char=""
    
    log "DEBUG" "Вход в режим посимвольного чтения клавиатуры (stty -echo)..."
    stty -echo

    while true; do
        if ! read -r -s -n 1 -d '' char; then
            log "ERROR" "Ошибка вызова функции read"
            break
        fi

        if [ -z "$char" ]; then
            log "DEBUG" "Нажат Enter. Завершение ввода пароля."
            break
        fi

        # Отлавливаем нажатие Escape
        if [ "$char" = $'\x1b' ]; then
            log "DEBUG" "Нажата клавиша Escape — успешно проигнорирована."
            continue
        fi

        if [ "$char" = $'\x7f' ] || [ "$char" = $'\x08' ]; then
            if [ ${#password} -gt 0 ]; then
                password="${password%?}"
                echo -ne "\b \b"
            fi
            continue
        fi

        if [[ "$char" =~ [0-9] ]]; then
            password+="$char"
            echo -n "*"
        fi
    done

    stty echo
    log "DEBUG" "Режим отображения stty восстановлен."
    echo "$password"
}

# ГЛАВНЫЙ ЦИКЛ БЛОКИРОВКИ
while [ "$UNLOCKED" = false ]; do
    draw_screen
    
    log "INFO" "Ожидание ввода пароля пользователем..."
    INPUT=$(read_password)

    log "DEBUG" "Введен пароль длиной ${#INPUT} символов."

    if [ "$INPUT" = "$CORRECT_PASS" ]; then
        log "INFO" "Введен корректный пароль! Запуск процедуры разблокировки."
        UNLOCKED=true
    else
        log "WARN" "Введен НЕВЕРНЫЙ пароль: [$INPUT]"
        get_terminal_size
        local err_row=$((rows / 2 + 3))
        local err_text="Incorrect password!"
        local err_col=$(( (cols - ${#err_text}) / 2 ))
        
        echo -e "\e[${err_row};${err_col}H\e[31m${err_text}\e[37m"
        sleep 1.2
    fi
done

# ВОССТАНОВЛЕНИЕ СИСТЕМЫ И ЗАПУСК KWRITE
log "INFO" "Восстановление стандартного отображения курсора..."
echo -e "\e[?25h"
clear

log "INFO" "Попытка запуска текстового редактора KWrite..."

# Проверяем, существует ли утилита kwrite в системе
if command -v kwrite &> /dev/null; then
    log "INFO" "Утилита kwrite найдена. Запуск процесса в фоновом режиме..."
    # Запуск kwrite с перенаправлением графических ошибок в лог, чтобы не вешать терминал
    kwrite 2>> "$LOG_FILE" &
    KWRITE_PID=$!
    log "INFO" "KWrite успешно запущен с PID=$KWRITE_PID"
else
    log "ERROR" "Ошибка: утилита kwrite НЕ НАЙДЕНА в MOS Linux! Проверяем альтернативы (kate, gedit, nano)..."
    if command -v kate &> /dev/null; then
        log "INFO" "Вместо kwrite найден и запущен kate"
        kate 2>> "$LOG_FILE" &
    elif command -v gedit &> /dev/null; then
        log "INFO" "Вместо kwrite найден и запущен gedit"
        gedit 2>> "$LOG_FILE" &
    else
        log "WARN" "Графические редакторы не найдены. Выходим."
    fi
fi

echo "Доступ восстановлен."
log "INFO" "=== КОНЕЦ ЛОГА ОТЛАДКИ ==="
